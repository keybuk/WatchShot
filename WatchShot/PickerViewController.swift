//
//  PickerViewController.swift
//  WatchShot
//
//  Created by Scott James Remnant on 5/7/15.
//  Copyright (c) 2015 Scott James Remnant. All rights reserved.
//

import UIKit
import Photos

/// The picker view presents a carousel of screenshots from the photo library for the user to select. Tapping one will take the user to the compose view controller.
class PickerViewController: UIViewController {
    
    @IBOutlet weak var dateLabel: UILabel?
    @IBOutlet weak var collectionView: UICollectionView?
    
    /// We don't show the watch screenshots quite at full-size, in order to carousel them better.
    let imageScale: CGFloat = 0.75
    
    /// Size of the screenshot we actually do show.
    var largestSize = CGSizeZero

    /// Photo library fetch result, set by the loading view controller on segue in.
    var fetchResult: PHFetchResult!
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register for change notifications, so we find out when fetch results change.
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)

        // Figure out the largest size of screenshot we need to handle.
        let watchManager = WatchManager.sharedInstance
        for watchSize in watchManager.sizes {
            if watchSize.screenshotSize.width > largestSize.width {
                largestSize.width = watchSize.screenshotSize.width
            }
            if watchSize.screenshotSize.height > largestSize.height {
                largestSize.height = watchSize.screenshotSize.height
            }
        }
        
        // Layout the collection view.
        if let collectionView = collectionView {
            // The collection view hasn't got the right bounds yet, update the layout now so it does.
            collectionView.layoutIfNeeded()
            
            let flowLayout = collectionView.collectionViewLayout as! CollectionViewCellPagedFlowLayout
            flowLayout.itemSize = CGSizeMake(largestSize.width * imageScale, largestSize.height * imageScale)
            
            // Fiddle with the insets of the flow layout so that the first and last items appear centered.
            let inset = (collectionView.bounds.width - flowLayout.itemSize.width) / 2.0
            flowLayout.sectionInset.left = inset
            flowLayout.sectionInset.right = inset
            
            // Lay out horizontally with a gap between.
            flowLayout.minimumInteritemSpacing = 0.0
            flowLayout.minimumLineSpacing = 40.0
            flowLayout.scrollDirection = .Horizontal
        }
        
        // Set the date label to that of the first screenshot.
        if let asset = fetchResult.firstObject as? PHAsset {
            dateLabel?.text = asset.creationDate.timeAgo
        }
        
        navigationItem.titleView = cuteTitleView()
        navigationItem.hidesBackButton = true
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Clear the selection on apperance as UIContainerViewController does.
        if let indexPaths = collectionView?.indexPathsForSelectedItems() as? [NSIndexPath] {
            for indexPath in indexPaths {
                collectionView?.deselectItemAtIndexPath(indexPath, animated: false)
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ComposeSegue" {
            let composeViewController = segue.destinationViewController as! ComposeViewController
            
            if let indexPath = collectionView?.indexPathsForSelectedItems().first as? NSIndexPath,
                pickerViewCell = collectionView?.cellForItemAtIndexPath(indexPath) as? PickerViewCell {
                    composeViewController.watchSize = pickerViewCell.watchSize
                    composeViewController.screenshot = pickerViewCell.screenshot
            }
        }
    }

    /// Resets the carousel to the first screenshot without animating
    func resetToInitialState() {
        collectionView?.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: false)
    }

    /// Scroll the carousel to the first screenshot.
    func scrollToFirstScreenshot() {
        // First check to see if the screenshot is already in the center of the view.
        if let collectionView = collectionView {
            let center = collectionView.convertPoint(collectionView.center, fromView: view)
            if let indexPath = collectionView.indexPathForItemAtPoint(center) {
                if indexPath.item == 0 {
                    // It is, just update the date label in case the screenshot changed.
                    if let asset = fetchResult.firstObject as? PHAsset {
                        dateLabel?.text = asset.creationDate.timeAgo
                    }
                    return
                }
            }
            
            // Screenshot in the center of the view is not the first, scroll to it.
            collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: true)
        }
    }

}

// MARK: UICollectionViewDataSource
extension PickerViewController: UICollectionViewDataSource {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PickerViewCell", forIndexPath: indexPath) as! PickerViewCell

        let asset = fetchResult[indexPath.item] as! PHAsset
        let assetSize = CGSizeMake(CGFloat(asset.pixelWidth), CGFloat(asset.pixelHeight))

        let watchManager = WatchManager.sharedInstance
        let watchSize = watchManager.sizeForScreenshotSize(assetSize)!
        
        let imageManager = PHImageManager.defaultManager()
        let imageRequestOptions = PHImageRequestOptions()
        imageManager.requestImageForAsset(asset, targetSize: assetSize, contentMode: PHImageContentMode.AspectFill, options: PHImageRequestOptions(), resultHandler: { screenshot, info in
            cell.setScreenshot(screenshot, watchSize: watchSize)
        })

        return cell
    }
    
}

// MARK: UICollectionViewDelegate
extension PickerViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // When an item is tapped on, scroll it to the center. The storyboard already has the associated segue to the compose view hooked up.
        collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: true)
    }
    
}

// MARK: UIScrollViewDelegate
extension PickerViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        // Update the date label as the carousel is scrolled left and right to always refer to the image in the center.
        if let collectionView = collectionView {
            let center = collectionView.convertPoint(collectionView.center, fromView: view)
            if let indexPath = collectionView.indexPathForItemAtPoint(center),
                asset = fetchResult[indexPath.item] as? PHAsset {
                    dateLabel?.text = asset.creationDate.timeAgo
            }
        }
    }
}

/// Cell within the collection view, holds a reference to the screenshot and its size, and an outlet to its image view which it auto-updates.
class PickerViewCell: UICollectionViewCell {

    @IBOutlet weak var screenshotView: UIImageView?

    /// Screenshot image.
    var screenshot: UIImage?

    /// Size of the appropriate watch model.
    var watchSize: WatchSize?

    func setScreenshot(screenshot: UIImage, watchSize: WatchSize) {
        // FIXME here would be one good place to handle 38mm
        self.watchSize = watchSize
        self.screenshot = screenshot

        screenshotView?.image = screenshot
    }

}

// MARK: PHPhotoLibraryChangeObserver
extension PickerViewController: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(changeInstance: PHChange) {
        func indexPathsFromIndexSet(indexSet: NSIndexSet) -> [NSIndexPath] {
            var indexPaths: [NSIndexPath] = []
            for index in indexSet {
                indexPaths.append(NSIndexPath(forItem: index, inSection: 0))
            }
            return indexPaths
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            if let fetchResultChanges = changeInstance.changeDetailsForFetchResult(self.fetchResult) {
                self.fetchResult = fetchResultChanges.fetchResultAfterChanges
                
                // Update the collection view.
                if let collectionView = self.collectionView {
                    if fetchResultChanges.hasIncrementalChanges {
                        collectionView.performBatchUpdates({
                            var removedIndexPaths: [NSIndexPath]?
                            var insertedIndexPaths: [NSIndexPath]?
                            var changedIndexPaths: [NSIndexPath]?
                            
                            if let removedIndexes = fetchResultChanges.removedIndexes {
                                let removedIndexPaths = indexPathsFromIndexSet(removedIndexes)
                                if removedIndexPaths.count > 0 {
                                    collectionView.deleteItemsAtIndexPaths(removedIndexPaths)
                                }
                            }
                            if let insertedIndexes = fetchResultChanges.insertedIndexes {
                                let insertedIndexPaths = indexPathsFromIndexSet(insertedIndexes)
                                if insertedIndexPaths.count > 0 {
                                    collectionView.insertItemsAtIndexPaths(insertedIndexPaths)
                                }
                            }
                            if let changedIndexes = fetchResultChanges.changedIndexes {
                                let changedIndexPaths = indexPathsFromIndexSet(changedIndexes)
                                if changedIndexPaths.count > 0 {
                                    collectionView.reloadItemsAtIndexPaths(changedIndexPaths)
                                }
                            }
                            
                            if fetchResultChanges.hasMoves {
                                fetchResultChanges.enumerateMovesWithBlock{ fromIndex, toIndex in
                                    let fromIndexPath = NSIndexPath(forItem: fromIndex, inSection: 0)
                                    let toIndexPath = NSIndexPath(forItem: toIndex, inSection: 0)
                                    collectionView.moveItemAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
                                }
                            }

                        }, completion: { finished in
                            self.scrollToFirstScreenshot()

                        })
                    } else {
                        collectionView.reloadData()
                        self.scrollToFirstScreenshot()
                    }
                }
            }
        }
    }
    
}
