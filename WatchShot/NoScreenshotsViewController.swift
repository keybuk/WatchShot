//
//  NoScreenshotsViewController.swift
//  WatchShot
//
//  Created by Scott James Remnant on 5/11/15.
//  Copyright (c) 2015 Scott James Remnant. All rights reserved.
//

import UIKit

/// View to indicate that there are no screenshots in the photo library.
class NoScreenshotsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = cuteTitleView()
        navigationItem.hidesBackButton = true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "LoadedSegue" {
            let loadingViewController = sender as! LoadingViewController
            let pickerViewController = segue.destinationViewController as! PickerViewController
            
            pickerViewController.fetchResult = loadingViewController.fetchResult
        }
    }

}
