//
//  StoreKeeper.swift
//  WatchShot
//
//  Created by Scott James Remnant on 5/13/15.
//  Copyright (c) 2015 Scott James Remnant. All rights reserved.
//

import UIKit
import StoreKit

class StoreKeeper: NSObject {
    
    /// Singleton instance.
    static let sharedInstance = StoreKeeper()

    override init() {
        super.init()

        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        
        checkPurchases()
        checkReceipt()
    }
    
    deinit {
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }

    /// Validate the set of purchases with the App Store.
    func checkPurchases() {
        let watchManager = WatchManager.sharedInstance

        let productsRequest = SKProductsRequest(productIdentifiers: Set(watchManager.productIdentifiers()))
        productsRequest.delegate = self
        productsRequest.start()
    }

    /// Validate the receipt, and check which in-app purchases are owned.
    func checkReceipt() {
        let watchManager = WatchManager.sharedInstance
        
        IAP_CheckInAppPurchases(watchManager.productIdentifiers(), { productIdentifier, isPresent, purchaseInfo in
            let watchModel = watchManager.modelForProductIdentifier(productIdentifier)!
            if isPresent {
                watchModel.receipt = purchaseInfo
            } else {
                watchModel.receipt = nil
            }
        }, self)
    }

    /// Initiate a receipt refresh with the App Store.
    func restorePurchases() {
        let request = SKReceiptRefreshRequest()
        request.delegate = self
        request.start()
    }
    
    /// Submit a purchase for the given product.
    func createPurchase(product: SKProduct) {
        let payment = SKMutablePayment(product: product)
        payment.quantity = 1
        
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }
    
}

// MARK: SKPaymentTransactionObserver
extension StoreKeeper: SKPaymentTransactionObserver {
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        let paymentQueue = SKPaymentQueue.defaultQueue()

        var updateReceipt: Bool = false
        for transaction in transactions {
            switch transaction.transactionState {
            case .Purchasing, .Deferred:
                break
            case .Failed:
                paymentQueue.finishTransaction(transaction)
            case .Purchased, .Restored:
                updateReceipt = true
                paymentQueue.finishTransaction(transaction)
            }
        }
        
        if updateReceipt {
            checkReceipt()
        }
    }

}

// MARK: SKProductsRequestDelegate
extension StoreKeeper: SKProductsRequestDelegate {
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        let watchManager = WatchManager.sharedInstance

        for product in response.products {
            let watchModel = watchManager.modelForProductIdentifier(product.productIdentifier)!
            watchModel.product = product
        }
    }
    
}

// MARK: SKRequestDelegate
extension StoreKeeper: SKRequestDelegate {
    
    func request(request: SKRequest, didFailWithError error: NSError) {
    }
    
    func requestDidFinish(request: SKRequest) {
        dispatch_async(dispatch_get_main_queue()) {
            self.checkReceipt()
        }
    }
    
}
