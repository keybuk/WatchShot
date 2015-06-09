//
//  ReceiptValidation.m
//  WatchShot
//
//  Created by Scott James Remnant on 5/12/15.
//  Copyright (c) 2015 Scott James Remnant. All rights reserved.
//

#include "ReceiptValidation.h"

#include "receipt.h"

void IAP_CheckInAppPurchases(NSArray * __nonnull _inapp_identifiers, IAP_InAppValidateBlock __nonnull _inapp_block, id<SKRequestDelegate> __nonnull _request_delegate) {
    ReceiptValidation_CheckInAppPurchases(_inapp_identifiers, _inapp_block, _request_delegate);
}
