//
//  VDirectoryItemCell.h
//  victorious
//
//  Created by Will Long on 9/11/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "VBaseCollectionViewCell.h"

@class VStreamItem;

extern NSString * const VDirectoryItemCellNameStream;

/**
 *  A cell for the VDirectoryCollectionViewController.
 */
@interface VDirectoryItemCell : VBaseCollectionViewCell

/**
 *  The VStreamItem used to populate fields on the cell.
 */
@property (nonatomic, strong) VStreamItem *streamItem;

@end
