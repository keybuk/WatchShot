//
//  Watches.swift
//  WatchShot
//
//  Created by Scott James Remnant on 5/13/15.
//  Copyright (c) 2015 Scott James Remnant. All rights reserved.
//

import UIKit
import StoreKit

class WatchManager {

    /// Singleton instance.
    static let sharedInstance = WatchManager()
    
    /// Sizes of watch.
    let sizes: [WatchSize]
    
    init() {
        // Load the property list
        let path = NSBundle.mainBundle().pathForResource("Watches", ofType: "plist")!
        let pList = NSDictionary(contentsOfFile: path)!
        
        let sizeList = pList["sizes"]! as! [String: NSDictionary]
        let descriptions = pList["descriptions"]! as! [String: [String: String]]
        
        var sizes = [WatchSize]()
        for sizeInfo in sizeList.values {
            let watchSize = WatchSize(sizeInfo: sizeInfo, descriptions: descriptions)
            sizes.append(watchSize)
        }
        self.sizes = sizes
    }
    
    /// - returns: WatchSize that has screenshots of the given size.
    func sizeForScreenshotSize(screenshotSize: CGSize) -> WatchSize? {
        for watchSize in sizes {
            if CGSizeEqualToSize(screenshotSize, watchSize.screenshotSize) {
                return watchSize
            }
        }
        
        return nil
    }
    
    /// - returns: the set of all product identifiers.
    func productIdentifiers() -> [String] {
        var productIdentifiers = [String]()
        for watchSize in sizes {
            for watchModel in watchSize._models {
                if let productIdentifier = watchModel.productIdentifier {
                    productIdentifiers.append(productIdentifier)
                }
            }
        }
        return productIdentifiers
    }
    
    /// - returns: the watch model corresponding to the given product identifier.
    func modelForProductIdentifier(productIdentifier: String) -> WatchModel? {
        for watchSize in sizes {
            for watchModel in watchSize._models {
                if watchModel.productIdentifier == productIdentifier {
                    return watchModel
                }
            }
        }

        return nil
    }

}

/// A collection of watch models all of the same size.
class WatchSize {

    /// Prefix added to filenames.
    let filenamePrefix: String
    
    /// Size of screenshots, in pixels, from models of this size.
    let screenshotSize: CGSize
    
    /// Size of the resulting image, in pixels, for models of this size.
    let imageSize: CGSize
    
    /// Models available in this size.
    var models: [WatchModel] {
        get { return _models.filter { watchModel in return watchModel.ownership != .Unavailable } }
    }

    /// All models for this size, including those unavailable for sale.
    private var _models: [WatchModel]

    init(sizeInfo: NSDictionary, descriptions: [String: [String: String]]) {
        filenamePrefix = sizeInfo["filenamePrefix"] as! String
        
        let screenshotWidth = sizeInfo["screenshotWidth"] as! NSNumber
        let screenshotHeight = sizeInfo["screenshotHeight"] as! NSNumber
        
        screenshotSize = CGSizeMake(CGFloat(screenshotWidth.floatValue), CGFloat(screenshotHeight.floatValue))
        
        let imageWidth = sizeInfo["imageWidth"] as! NSNumber
        let imageHeight = sizeInfo["imageHeight"] as! NSNumber
        
        imageSize = CGSizeMake(CGFloat(imageWidth.floatValue), CGFloat(imageHeight.floatValue))
        
        let modelFilenames = sizeInfo["modelFilenames"] as! [String]
        let productIdentifiers = sizeInfo["productIdentifiers"] as! [String: String]
        let activationKeys = sizeInfo["activationKeys"] as! [String: String]
        
        _models = [WatchModel]()
        for modelFilename in modelFilenames {
            let productIdentifier = productIdentifiers[modelFilename]
            let activationKey = activationKeys[modelFilename]
            let watchModel = WatchModel(filenameSuffix: modelFilename, productIdentifier: productIdentifier, activationKey: activationKey, watchSize: self, descriptions: descriptions)
            _models.append(watchModel)
        }
    }
    
    /// - returns: the watch model corresponding to the given filename suffix.
    func modelForFilenameSuffix(filenameSuffix: String) -> WatchModel? {
        for watchModel in models {
            if watchModel.filenameSuffix == filenameSuffix {
                return watchModel
            }
        }
        
        return nil
    }

}

/// A single watch model, at a specific size.
class WatchModel: Equatable {

    /// Associated size of this model.
    unowned var watchSize: WatchSize
    
    /// Suffix added to filenames.
    let filenameSuffix: String
    
    /// Product identifier of this model, if it's a purchasable item.
    let productIdentifier: String?
    
    /// NSUserDefaults activation key, if it's a secret item.
    let activationKey: String?
    
    /// Human-readable description of this model, usually appended to "WATCH".
    let modelDescription: String
    
    /// Human-readable description of the case of this model.
    let caseDescription: String
    
    /// Human-readable description of the band of this model.
    let bandDescription: String
    
    /// Ownership status of watch models:
    ///  - Free: this model has no associated purchase.
    ///  - Owned: the purchase of this model is owned.
    ///  - ForSale: this model is available for purchase.
    ///  - Unavailable: this model is currently unavailable.
    enum Ownership {
        case Free, Owned, ForSale, Unavailable
    }
    
    /// StoreKit product associated with this watch model, set after the receipt has been checked and products validated.
    var product: SKProduct?
    
    /// StoreKit receipt associated with this watch model, set after the receipt has been checked.
    var receipt: NSDictionary?
    
    /// User's ownership of this watch model.
    var ownership: Ownership {
        get {
            let defaults = NSUserDefaults.standardUserDefaults()
            if productIdentifier == nil && activationKey == nil {
                return .Free
            } else if activationKey != nil && defaults.boolForKey(activationKey!) {
                return .Owned
            } else if receipt != nil {
                return .Owned
            } else if product != nil {
                return .ForSale
            } else {
                return .Unavailable
            }
        }
    }
    
    init(filenameSuffix: String, productIdentifier: String?, activationKey: String?, watchSize: WatchSize, descriptions: [String: [String: String]]) {
        self.filenameSuffix = filenameSuffix
        self.productIdentifier = productIdentifier
        self.activationKey = activationKey
        self.watchSize = watchSize
        
        var modelDescription: String = ""
        for (prefix, description) in descriptions["models"]! {
            if filenameSuffix.hasPrefix(prefix) {
                modelDescription = description
            }
        }
        self.modelDescription = modelDescription
        
        var caseDescription: String = ""
        for (prefix, description) in descriptions["cases"]! {
            if filenameSuffix.hasPrefix(prefix) {
                caseDescription = description
            }
        }
        self.caseDescription = caseDescription

        var bandDescription: String = ""
        for (suffix, description) in descriptions["bands"]! {
            if filenameSuffix.hasSuffix(suffix) {
                bandDescription = description
            }
        }
        self.bandDescription = bandDescription
    }
    
    /// - returns: An attributed string containing the complete description of the model.
    func attributedString() -> NSAttributedString {
        let appleFont = UIFont(name: "HelveticaNeue-Bold", size: 17.0)!
        let modelFont = UIFont(name: "HelveticaNeue", size: 17.0)!
        let lightFont = UIFont(name: "HelveticaNeue-Light", size: 15.0)!
        
        let appleString = NSAttributedString(string: "WATCH", attributes: [NSFontAttributeName: appleFont])
        
        let modelString: NSAttributedString
        if modelDescription != "" {
            modelString = NSAttributedString(string: " \(modelDescription)\n", attributes: [NSFontAttributeName: modelFont])
        } else {
            modelString = NSAttributedString(string: "\n")
        }
        
        let caseString = NSAttributedString(string: "\(caseDescription)\n", attributes: [NSFontAttributeName: lightFont])
        let bandString = NSAttributedString(string: "\(bandDescription)", attributes: [NSFontAttributeName: lightFont])

        let attributedString = NSMutableAttributedString()
        attributedString.appendAttributedString(appleString)
        attributedString.appendAttributedString(modelString)
        attributedString.appendAttributedString(caseString)
        attributedString.appendAttributedString(bandString)
        return attributedString
    }


    /// - returns: A new image composed of the watch model image and the screenshot.
    func createImageForScreenshot(screenshot: UIImage, backgroundColor: UIColor? = nil) -> UIImage {
        let imageRect = CGRectMake(0.0, 0.0, watchSize.imageSize.width, watchSize.imageSize.height)
        let screenshotRect = CGRectMake((watchSize.imageSize.width - watchSize.screenshotSize.width) / 2.0, (watchSize.imageSize.height - watchSize.screenshotSize.height) / 2.0, watchSize.screenshotSize.width, watchSize.screenshotSize.height)
        
        UIGraphicsBeginImageContextWithOptions(imageRect.size, backgroundColor != nil, 1.0)
        
        if let backgroundColor = backgroundColor {
            let context = UIGraphicsGetCurrentContext()
            CGContextSetFillColorWithColor(context, backgroundColor.CGColor)
            CGContextFillRect(context, imageRect)
            
            // When there's a background color, add a little monogram stamp to it.
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
            backgroundColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            backgroundColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

            let luminance = red * 0.2126 + green * 0.7152 + blue * 0.0722
            let stampColor: UIColor
            if luminance > 0.5 {
                // Closer to white, go a bit darker.
                stampColor = UIColor(hue: hue, saturation: saturation, brightness: max(0.0, brightness - 0.10), alpha: alpha)
            } else {
                // Closer to black, go a bit lighter.
                stampColor = UIColor(hue: hue, saturation: saturation, brightness: min(1.0, brightness + 0.10), alpha: alpha)
            }
            
            let watchAttrs = [ NSFontAttributeName: UIFont(name: "HelveticaNeue-Bold", size: 24.0)!, NSForegroundColorAttributeName: stampColor ]
            let shotAttrs = [ NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 24.0)!, NSForegroundColorAttributeName: stampColor ]
            
            let watchString = NSString(string: "WATCH")
            let shotString = NSString(string: " SHOT")
            
            let watchSize = watchString.sizeWithAttributes(watchAttrs)
            let shotSize = shotString.sizeWithAttributes(shotAttrs)
            
            let textStartX = (imageRect.size.width - watchSize.width - shotSize.width) / 2.0
            let textStartY = imageRect.size.height - max(watchSize.height, shotSize.height) - 4.0
            
            watchString.drawAtPoint(CGPointMake(textStartX, textStartY), withAttributes: watchAttrs)
            shotString.drawAtPoint(CGPointMake(textStartX + watchSize.width, textStartY), withAttributes: shotAttrs)
        }
        
        let filename = "\(watchSize.filenamePrefix)_\(filenameSuffix)"
        let modelImage = UIImage(named: filename)!
        
        modelImage.drawInRect(imageRect)
        screenshot.drawInRect(screenshotRect, blendMode: kCGBlendModeLighten, alpha: 1.0)
        
        var image = UIGraphicsGetImageFromCurrentImageContext()
        
        switch ownership {
        case .ForSale, .Unavailable:
            CGContextClearRect(UIGraphicsGetCurrentContext(), imageRect)
            image.drawInRect(imageRect, blendMode: kCGBlendModeNormal, alpha: 0.35)
            
            image = UIGraphicsGetImageFromCurrentImageContext()
        default:
            break
        }
        
        UIGraphicsEndImageContext()
        
        return image
    }
    
}

func ==(lhs: WatchModel, rhs: WatchModel) -> Bool {
    return lhs.filenameSuffix == rhs.filenameSuffix
}

