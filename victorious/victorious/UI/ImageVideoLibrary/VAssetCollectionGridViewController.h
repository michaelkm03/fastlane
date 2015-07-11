//
//  VAssetGridViewController.h
//  victorious
//
//  Created by Michael Sena on 6/29/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VMediaSource.h"

@import Photos;
@class VDependencyManager;

@interface VAssetCollectionGridViewController : UICollectionViewController <VMediaSource>

/**
 *  Factory method for this ViewController. Use this to grab a new instance of assetGridViewController;
 */
+ (instancetype)assetGridViewControllerWithDependencyManager:(VDependencyManager *)dependencyManager
                                                   mediaType:(PHAssetMediaType)mediaType;

/**
 *  Set this to the collection you want to display in the grid.
 */
@property (nonatomic, strong) PHAssetCollection *collectionToDisplay;

/**
 *  Provide the gridViewController a selection handelr to be notified
 */
@property (nonatomic, copy) void (^alternateFolderSelectionHandler)();

@end
