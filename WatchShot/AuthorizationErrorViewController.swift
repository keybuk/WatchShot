//
//  AuthorizationErrorViewController.swift
//  WatchShot
//
//  Created by Scott James Remnant on 5/11/15.
//  Copyright (c) 2015 Scott James Remnant. All rights reserved.
//

import UIKit
import Photos


/// View to indicate that there is an authorization error accessing the photo library.
class AuthorizationErrorViewController: UIViewController {
    
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var messageLabelYConstraint: NSLayoutConstraint!

    /// Vertical offset from the center so we show the "not determined" message above the alert.
    let alertOffset: CGFloat = 100.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = cuteTitleView()
        navigationItem.hidesBackButton = true
        
        updateErrorMessage()
    }
    
    func updateErrorMessage() {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch authorizationStatus {
        case .NotDetermined:
            messageLabel.text = "Please authorize access to your Photos."
            messageLabelYConstraint.constant = alertOffset
        case .Restricted:
            messageLabel.text = "Access to your Photos is restricted. Please ask your parent, guardian or system administrator."
            messageLabelYConstraint.constant = 0.0
        case .Denied:
            messageLabel.text = "Please authorize access to your Photos in the Settings app."
            messageLabelYConstraint.constant = 0.0
        default:
            messageLabel.text = "Something went wrong."
            messageLabelYConstraint.constant = 0.0
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "LoadedSegue" {
            let loadingViewController = sender as! LoadingViewController
            let pickerViewController = segue.destinationViewController as! PickerViewController
            
            pickerViewController.fetchResult = loadingViewController.fetchResult
        }
    }

}
