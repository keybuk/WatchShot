//
//  LoadingViewController.swift
//  WatchShot
//
//  Created by Scott James Remnant on 5/11/15.
//  Copyright (c) 2015 Scott James Remnant. All rights reserved.
//

import UIKit
import Photos

/// This view controller handles the complex case of authorizing access to the photo library, dealing with authorization issues, fetching the set of photos, and dealing with there not being any.
///
/// It handles the segues between itself and two other view controllers to update the UI, before replacing the entire stack with PickerViewContoller and passing it the fetch result.
class LoadingViewController: UIViewController {

    /// Photo library fetch result.
    var fetchResult: PHFetchResult? = nil
    
    /// When true, indicates a non-nil fetch result should be ignored until changed.
    var expectingFetchResultChange = false
    
    /// Set to true once the view has appeared, and we can perform segues.
    var canSegue = false

    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register for change notifications, so we find out when the fetch results change.
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)

        // For the first-run, do an explicit request for authorization status because that allows us to be immediately notified of the user's answer.
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        if authorizationStatus == .NotDetermined {
            PHPhotoLibrary.requestAuthorization({ status in
                dispatch_async(dispatch_get_main_queue()) {
                    self.updateViewControllers()
                }
            })
        }
        
        // Build up the fetch request.
        let watchManager = WatchManager.sharedInstance
        let sizePredicates = watchManager.sizes.map { watchSize in
            NSPredicate(format: "pixelWidth == \(watchSize.screenshotSize.width) && pixelHeight == \(watchSize.screenshotSize.height)")
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType, subpredicates: sizePredicates)
        fetchOptions.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]

        // Perform the fetch on a background thread so it doesn't block the UI, and update when done.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let fetchResult = PHAsset.fetchAssetsWithMediaType(.Image, options: fetchOptions)
            dispatch_async(dispatch_get_main_queue()) {
                self.fetchResult = fetchResult

                // If we get the fetch result while we're still awaiting authorization, it'll get a Change (even when there are no results); so we want to ignore it from the purposes of updating the UI.
                let authorizationStatus = PHPhotoLibrary.authorizationStatus()
                self.expectingFetchResultChange = authorizationStatus == .NotDetermined

                self.updateViewControllers()
            }
        }
        
        navigationItem.titleView = cuteTitleView()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        canSegue = true
        self.updateViewControllers()
    }
    
    func updateViewControllers() {
        if !canSegue {
            return
        }
        
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch authorizationStatus {
        case .NotDetermined, .Restricted, .Denied:
            if let authorizationErrorViewController = navigationController?.topViewController as? AuthorizationErrorViewController {
                authorizationErrorViewController.updateErrorMessage()
            } else {
                performSegueWithIdentifier("AuthorizationErrorSegue", sender: self)
            }
        case .Authorized:
            if fetchResult?.count > 0 {
                navigationController?.topViewController.performSegueWithIdentifier("LoadedSegue", sender: self)
            } else if fetchResult != nil {
                // Only perform this segue if we're not expecting an immediate change on the fetch result, this avoids an unnecessary extra view controller change.
                if !expectingFetchResultChange {
                    navigationController?.topViewController.performSegueWithIdentifier("NoScreenshotsSegue", sender: self)
                }
            } else {
                if let authorizationErrorViewController = navigationController?.topViewController as? AuthorizationErrorViewController {
                    authorizationErrorViewController.performSegueWithIdentifier("AuthorizedSegue", sender: self)
                }
            }
        }
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "LoadedSegue" {
            let pickerViewController = segue.destinationViewController as! PickerViewController
    
            pickerViewController.fetchResult = fetchResult
        }
    }
    
    @IBAction func unwindFromAuthorizationErrorViewController(segue: UIStoryboardSegue) {
    }
    
}

// MARK: PHPhotoLibraryChangeObserver
extension LoadingViewController: PHPhotoLibraryChangeObserver {

    func photoLibraryDidChange(changeInstance: PHChange) {
        dispatch_async(dispatch_get_main_queue()) {
            if let fetchResultChanges = changeInstance.changeDetailsForFetchResult(self.fetchResult) {
                self.fetchResult = fetchResultChanges.fetchResultAfterChanges
                print("NEW FETCH WITH \(self.fetchResult!.count) ITEMS")
                self.expectingFetchResultChange = false
                self.updateViewControllers()
            }
        }
    }

}
