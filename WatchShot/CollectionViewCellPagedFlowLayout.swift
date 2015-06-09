//
//  CollectionViewCellPagedFlowLayout.swift
//  WatchShot
//
//  Created by Scott James Remnant on 5/8/15.
//  Copyright (c) 2015 Scott James Remnant. All rights reserved.
//

import UIKit

/// Sub-classes UICollectionViewFlowLayout to perform horizontal paged scrolling on a per-cell basis.
///
/// http://stackoverflow.com/a/28813308
class CollectionViewCellPagedFlowLayout: UICollectionViewFlowLayout {
   
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        var targetContentOffset = proposedContentOffset
        var offSetAdjustment = CGFloat.max
        
        let horizontalCenter = proposedContentOffset.x + (collectionView!.bounds.size.width / 2.0)
        let targetRect = CGRect(x: proposedContentOffset.x, y: 0.0, width: collectionView!.bounds.size.width, height: collectionView!.bounds.size.height)
        
        var array = layoutAttributesForElementsInRect(targetRect) as! [UICollectionViewLayoutAttributes]
        for layoutAttributes in array {
            if layoutAttributes.representedElementCategory == UICollectionElementCategory.Cell {
                let itemHorizontalCenter = layoutAttributes.center.x
                if abs(itemHorizontalCenter - horizontalCenter) < abs(offSetAdjustment) {
                    offSetAdjustment = itemHorizontalCenter - horizontalCenter
                }
            }
        }
        
        var nextOffset = proposedContentOffset.x + offSetAdjustment
        
        repeat {
            targetContentOffset.x = nextOffset
            let deltaX = proposedContentOffset.x - collectionView!.contentOffset.x
            let velX = velocity.x
            
            if deltaX == 0.0 || velX == 0 || (velX > 0.0 && deltaX > 0.0) || (velX < 0.0 && deltaX < 0.0) {
                break
            }
            
            if velocity.x > 0.0 {
                nextOffset = nextOffset + snapStep()
            } else if velocity.x < 0.0 {
                nextOffset = nextOffset - snapStep()
            }
        } while isValidOffset(nextOffset)
        
        targetContentOffset.y = 0.0
        
        return targetContentOffset
    }
    
    func isValidOffset(offset: CGFloat) -> Bool {
        return offset >= minContentOffset() && offset <= maxContentOffset()
    }
    
    func minContentOffset() -> CGFloat {
        return -collectionView!.contentInset.left
    }
    
    func maxContentOffset() -> CGFloat {
        return minContentOffset() + collectionView!.contentSize.width - itemSize.width
    }
    
    func snapStep() -> CGFloat {
        return itemSize.width + minimumLineSpacing;
    }

}
