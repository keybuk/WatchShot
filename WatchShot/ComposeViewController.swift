//
//  ComposeViewController.swift
//  WatchShot
//
//  Created by Scott James Remnant on 5/7/15.
//  Copyright (c) 2015 Scott James Remnant. All rights reserved.
//

import UIKit

/// The compose view represents a carousel of WATCH models for the user to pick for sharing their screenshot on.
class ComposeViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var shareBuyButton: UIButton?
    @IBOutlet weak var restorePurchasesButton: UIButton?
    @IBOutlet weak var pickerXConstraint: NSLayoutConstraint?

    /// Screenshot selected by the user, set by the picker view on segue in.
    var screenshot: UIImage!
    
    /// Size of the watch model associated with the screenshot, set by the picker view on segue in.
    var watchSize: WatchSize!
    
    /// We don't show the images at full-size, since they won't fit. This is set when the view loads to the scale we're using for this device.
    var imageScale: CGFloat!
    
    /// Current watch model selected, updated as the user scrolls around or taps.
    var selectedModel: WatchModel?
    
    /// This is toggled to true after the user begins dragging the carousel, to ensure we update as they move it around.
    var updateSelectedModel = false
    
    /// Background color to be used for images.
    var backgroundColor = UIColor.whiteColor()
    
    deinit {
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register for store transaction notifications, so we can refresh on new purchases.
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)

        restorePurchasesButton?.hidden = true
        
        if let collectionView = collectionView {
            // The collection view hasn't got the right bounds yet, update the layout now so it does.
            collectionView.layoutIfNeeded()

            let flowLayout = collectionView.collectionViewLayout as! CollectionViewCellPagedFlowLayout

            // I don't want to deal with dynamic sizing.
            switch view.bounds.size.height {
            case let x where x <= 568.0:
                flowLayout.itemSize = CGSizeMake(170.0, 230.0)
            case let x where x <= 667.0:
                flowLayout.itemSize = CGSizeMake(218.0, 330.0)
            default:
                flowLayout.itemSize = CGSizeMake(250.0, 400.0)
            }
            
            imageScale = flowLayout.itemSize.height / watchSize.imageSize.height
            
            // Fiddle with the insets of the flow layout so that the first and last items appear centered.
            let inset = (collectionView.bounds.width - flowLayout.itemSize.width) / 2.0
            flowLayout.sectionInset.left = inset
            flowLayout.sectionInset.right = inset

            // Lay out horizontally with no gaps between, since the cells already have enough padding.
            flowLayout.minimumInteritemSpacing = 0.0
            flowLayout.minimumLineSpacing = 0.0
            flowLayout.scrollDirection = .Horizontal
        }

        // Load the last selected model. Actually scrolling to it is handled in viewWillAppear.
        loadSelectedModel()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Clear the selection on apperance as UIContainerViewController does.
        if let indexPaths = collectionView?.indexPathsForSelectedItems() as? [NSIndexPath] {
            for indexPath in indexPaths {
                collectionView?.deselectItemAtIndexPath(indexPath, animated: false)
            }
        }
        
        // Scroll to the selected model and update the display for it.
        updateViewForSelectedModel()
        if let selectedModel = selectedModel,
            index = find(watchSize.models, selectedModel) {
                collectionView?.layoutIfNeeded()
                collectionView?.scrollToItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: false)
        }
        
        navigationController?.navigationBar.barStyle = .Default
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        saveSelectedModel()

        navigationController?.navigationBar.barStyle = .Black
    }

    /// Updates the description label, and button states, to the selected model.
    func updateViewForSelectedModel() {
        if let selectedModel = selectedModel {
            descriptionLabel?.attributedText = selectedModel.attributedString()
            
            switch selectedModel.ownership {
            case .Free, .Owned:
                shareBuyButton?.setTitle("Share", forState: .Normal)
                shareBuyButton?.enabled = true
                restorePurchasesButton?.hidden = true
            case .ForSale:
                let numberFormatter = NSNumberFormatter()
                numberFormatter.formatterBehavior = .Behavior10_4
                numberFormatter.numberStyle = .CurrencyStyle
                numberFormatter.locale = selectedModel.product!.priceLocale
                let formattedPrice = numberFormatter.stringFromNumber(selectedModel.product!.price)
                
                shareBuyButton?.setTitle("Buy - \(formattedPrice!)", forState: .Normal)
                shareBuyButton?.enabled = true
                restorePurchasesButton?.hidden = false
            case .Unavailable:
                shareBuyButton?.setTitle("Unavailable", forState: .Normal)
                shareBuyButton?.enabled = false
                restorePurchasesButton?.hidden = false
            }
        }
    }
    
    /// MARK: Defaults handling
    
    /// Load the last selected model and store in selectedModel.
    func loadSelectedModel() {
        let watchManager = WatchManager.sharedInstance
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let filenameSuffix = defaults.stringForKey("lastSelectedModel\(watchSize.filenamePrefix)"),
            watchModel = watchSize.modelForFilenameSuffix(filenameSuffix) {
                selectedModel = watchModel
        } else {
            selectedModel = watchSize.models.first
        }
    }
    
    /// Saves a record of the selected model.
    func saveSelectedModel() {
        if let watchModel = selectedModel {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(watchModel.filenameSuffix, forKey: "lastSelectedModel\(watchSize.filenamePrefix)")
        }
    }
    
    /// MARK: Actions

    @IBAction func shareOrBuy(sender: UIButton) {
        if let watchModel = selectedModel {
            switch watchModel.ownership {
            case .Free, .Owned:
                openShareSheet(sender)
            case .ForSale:
                let storeKeeper = StoreKeeper.sharedInstance
                storeKeeper.createPurchase(watchModel.product!)

                shareBuyButton?.enabled = false
            case .Unavailable:
                break
            }
        }
    }

    @IBAction func restorePurchases(sender: UIButton) {
        let alertController = UIAlertController(title: "Restore Purchases", message: "Your purchases will be restored", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { action in
            let storeKeeper = StoreKeeper.sharedInstance
            storeKeeper.restorePurchases()
        }))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    @IBAction func openShareSheet(sender: UIView) {
        if let watchModel = selectedModel {
            let image = watchModel.createImageForScreenshot(screenshot, backgroundColor: backgroundColor)
        
            let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            presentViewController(activityViewController, animated: true, completion: nil)
        }
    }

    @IBAction func pickColor(sender: UIButton) {
        let colorPickerViewController = SwiftColorPickerViewController()
        colorPickerViewController.delegate = self
        colorPickerViewController.modalPresentationStyle = .Popover
        
        let popoverPresentationController = colorPickerViewController.popoverPresentationController!
        popoverPresentationController.sourceRect = sender.frame
        popoverPresentationController.sourceView = view
        popoverPresentationController.permittedArrowDirections = .Any
        popoverPresentationController.delegate = self
        
        presentViewController(colorPickerViewController, animated: true, completion: nil)
    }
}

// MARK: UICollectionViewDataSource
extension ComposeViewController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return watchSize.models.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ComposeViewCell", forIndexPath: indexPath) as! ComposeViewCell

        let watchModel = watchSize.models[indexPath.item]
        cell.image = watchModel.createImageForScreenshot(screenshot)
        
        return cell
    }

}

// MARK: UICollectionViewDelegate
extension ComposeViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let watchModel = watchSize.models[indexPath.item]

        if watchModel == selectedModel {
            // Tapping on the already selected model directly invokes the share flow, but not the buy flow.
            switch watchModel.ownership {
            case .Free, .Owned:
                openShareSheet(collectionView.cellForItemAtIndexPath(indexPath)!)
            case .ForSale, .Unavailable:
                break
            }
        } else {
            // Tapping on a non-selected model sets it to the selected, then updates the display immediately.
            selectedModel = watchModel
            updateViewForSelectedModel()
        }
        
        // Finally check if the model tapped on is in the center of the screen, or not. If not, scroll it, being careful not to update the display as we do so.
        let center = collectionView.convertPoint(collectionView.center, fromView: view)
        if let centerIndexPath = collectionView.indexPathForItemAtPoint(center) {
            if indexPath.item != centerIndexPath.item {
                updateSelectedModel = false
                collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: true)
            }
        }
    }

}


// MARK: UIScrollViewDelegate
extension ComposeViewController: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        // Since the user is dragging the view themselves, make sure we update the selected model as they do.
        updateSelectedModel = true
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        // Don't update things after a tap to select the item.
        if !updateSelectedModel {
            return
        }
        
        // Update the selected model to the one in the center, and refresh the display.
        if let collectionView = collectionView {
            let center = collectionView.convertPoint(collectionView.center, fromView: view)
            if let indexPath = collectionView.indexPathForItemAtPoint(center) {
                let watchModel = watchSize.models[indexPath.item]
                if watchModel != selectedModel {
                    selectedModel = watchModel
                    updateViewForSelectedModel()
                }
            }
        }
    }
}

/// Cell within the collection view, holds a reference to the image, and an outlet to its image view which it auto-updates.
class ComposeViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView?
    
    /// Screenshot image.
    var image: UIImage? {
        didSet {
            imageView?.image = image
        }
    }
    
}

// MARK: UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate
extension ComposeViewController: UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
}

// MARK: SwiftColorPickerDelegate
extension ComposeViewController: SwiftColorPickerDelegate {
    
    func colorSelectionChanged(selectedColor color: UIColor) {
        dismissViewControllerAnimated(true, completion: nil)
        
        backgroundColor = color
        UIView.animateWithDuration(0.35, animations: {
            collectionView?.backgroundColor = color
        })
    }
    
}

// MARK: SKPaymentTransactionObserver
extension ComposeViewController: SKPaymentTransactionObserver {
    
    func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!) {
        var refresh = false
        for transaction in transactions {
            let transaction = transaction as! SKPaymentTransaction
            switch transaction.transactionState {
            case .Failed, .Purchased, .Restored:
                refresh = true
            case .Purchasing, .Deferred:
                break
            }
        }
        
        // If any transaction reaches a completion state, refresh the display so that it updates to take it into account.
        if refresh {
            updateViewForSelectedModel()
            
            collectionView?.reloadData()
            //let indexPaths = collectionView?.indexPathsForVisibleItems()
            //collectionView?.reloadItemsAtIndexPaths(indexPaths!)
        }
    }
    
}


