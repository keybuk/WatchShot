//
//  AppDelegate.swift
//  WatchShot
//
//  Created by Scott James Remnant on 5/7/15.
//  Copyright (c) 2015 Scott James Remnant. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let watchManager: WatchManager = WatchManager.sharedInstance
    let storeKeeper: StoreKeeper = StoreKeeper.sharedInstance
    
    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Save the selected model if the compose view controller is on top of the stack.
        if let navigationController = window?.rootViewController as? UINavigationController,
            composeViewController = navigationController.topViewController as? ComposeViewController {
                composeViewController.saveSelectedModel()
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Return to the screenshot picker, and reset it to the initial state, provided it's the root in the stack.
        if let navigationController = window?.rootViewController as? UINavigationController,
            pickerViewController = navigationController.viewControllers.first as? PickerViewController {
                navigationController.popToRootViewControllerAnimated(false)
                pickerViewController.resetToInitialState()
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

