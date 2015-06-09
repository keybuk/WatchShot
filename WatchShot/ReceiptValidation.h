//
//  ReceiptValidation.h
//  WatchShot
//
//  Created by Scott James Remnant on 5/12/15.
//  Copyright (c) 2015 Scott James Remnant. All rights reserved.
//

#ifndef WatchShot_ReceiptValidation_h
#define WatchShot_ReceiptValidation_h

#import <StoreKit/StoreKit.h>

typedef void (^IAP_InAppValidateBlock)(NSString * __nonnull identifier, BOOL isPresent, NSDictionary * __nullable purchaseInfo);

void IAP_CheckInAppPurchases(NSArray * __nonnull _inapp_identifiers, IAP_InAppValidateBlock __nonnull _inapp_block, id<SKRequestDelegate> __nonnull _request_delegate);

#endif
