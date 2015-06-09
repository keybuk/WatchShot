//
//  NavigationControllerDelegate.swift
//  WatchShot
//
//  Created by Scott James Remnant on 5/11/15.
//  Copyright (c) 2015 Scott James Remnant. All rights reserved.
//

import UIKit

/// - returns: a UILabel for use in the UINavigationitem titleView.
func cuteTitleView() -> UILabel {
    let watchAttrs = [ NSFontAttributeName: UIFont(name: "HelveticaNeue-Bold", size: 17.0)!, NSForegroundColorAttributeName: UIColor.whiteColor() ]
    let shotAttrs = [ NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 17.0)!, NSForegroundColorAttributeName: UIColor.whiteColor() ]
    
    let titleString = NSMutableAttributedString(string: "WATCH", attributes: watchAttrs)
    titleString.appendAttributedString(NSAttributedString(string: " SHOT", attributes: shotAttrs))
    
    let titleLabel = UILabel(frame: CGRectMake(0.0, 0.0, titleString.size().width, titleString.size().height))
    titleLabel.attributedText = titleString
    
    return titleLabel
}

/// Manages selecting the appropriate animation for transitions within the view controller.
///
/// Instantiated by the Storyboard and attached to the UINavigationController.
class NavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if fromVC is PickerViewController && toVC is ComposeViewController {
            return PickerComposeAnimator()
        } else if fromVC is ComposeViewController && toVC is PickerViewController {
            return PickerComposeAnimator()
        } else {
            return FadeInAnimator()
        }
    }
    
}

/// Custom segue that replaces all of the view controllers on the stack with the destination.
///
/// Used to transition to the PickerViewController, and make that the new root view.
class ReplaceSegue: UIStoryboardSegue {
    
    override func perform() {
        if let sourceViewController = sourceViewController as? UIViewController,
            destinationViewController = destinationViewController as? UIViewController {
                sourceViewController.navigationController?.pushViewController(destinationViewController, animated: true)
                sourceViewController.navigationController?.setViewControllers([destinationViewController], animated: false)
        }
    }
    
}

/// Animator that fades in the new view.
///
/// Used for transitions between the loading, no screenshots, authorization error, and picker views.
class FadeInAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.35
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView()
        if let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
            toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) {
                containerView.addSubview(toViewController.view)
                toViewController.view.alpha = 0.0
                
                UIView.animateWithDuration(transitionDuration(transitionContext), animations: {
                    toViewController.view.alpha = 1.0
                }, completion: { finished in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                })
        }
    }
    
}

/// Animator for transitions between the Picker and Compose view.
class PickerComposeAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.35
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView()
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
        
        // Do a simple fade-in for the majority of the transition.
        containerView.addSubview(toViewController!.view)
        toViewController?.view.alpha = 0.0

        // This animator is used for both directions, so check which is the from and which is the to.
        let pickerViewController: PickerViewController
        let composeViewController: ComposeViewController
        if fromViewController is PickerViewController {
            pickerViewController = fromViewController! as! PickerViewController
            composeViewController = toViewController! as! ComposeViewController
        } else {
            pickerViewController = toViewController! as! PickerViewController
            composeViewController = fromViewController! as! ComposeViewController
        }
        
        // Grab the screenshot from the compose view (which has been filled in by the picker already, in that direction). We put it in our own image view that we zoom.
        let screenshot = composeViewController.screenshot
        let zoomyImage = UIImageView(image: screenshot)
        zoomyImage.contentMode = .ScaleAspectFill

        // Figure out the frame for the screenshot in both views, and set it to the one that's the view we're animating from.
        let largestSize = pickerViewController.largestSize
        let pickerImageScale = pickerViewController.imageScale
        let composeImageScale = composeViewController.imageScale
        let pickerFrame = CGRectMake(0.0, 0.0, largestSize.width * pickerImageScale, largestSize.height * pickerImageScale)
        let composeFrame = CGRectMake(0.0, 0.0, screenshot.size.width * composeImageScale, screenshot.size.height * composeImageScale)

        if fromViewController is PickerViewController {
            zoomyImage.frame = pickerFrame
        } else {
            zoomyImage.frame = composeFrame
        }

        // The original screenshot is left on the picker, and will be larger than the zoom, so hide that using a simple black mask over the top. This is added to the picker, rather than the container, because we want it to alpha change along with it.
        // We don't have to worry about the compose view since the screenshot there is always smaller than the zoomy one.
        let mask = UIView(frame: pickerFrame)
        mask.backgroundColor = UIColor.blackColor()

        pickerViewController.view.addSubview(mask)
        mask.center = pickerViewController.view.center

        // Now put the zoomy view in the center.
        containerView.addSubview(zoomyImage)
        zoomyImage.center = containerView.center

        // Animate the change with an alpha transition, and the zoomy image changing from one frame to another.
        UIView.animateWithDuration(transitionDuration(transitionContext), animations: {
            toViewController?.view.alpha = 1.0

            if fromViewController is PickerViewController {
                zoomyImage.frame = composeFrame
            } else {
                zoomyImage.frame = pickerFrame
            }
            zoomyImage.center = containerView.center
        }, completion: { finished in
            // Remove the extra views we created in the process.
            zoomyImage.removeFromSuperview()
            mask.removeFromSuperview()

            transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })
    }
    
}
