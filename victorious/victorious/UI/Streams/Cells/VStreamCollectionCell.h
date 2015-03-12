//
//  VStreamCollectionCell.h
//  victorious
//
//  Created by Will Long on 10/6/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "VSharedCollectionReusableViewMethods.h"
#import "VSequenceActionsDelegate.h"
#import "VBaseCollectionViewCell.h"

extern const CGFloat kTemplateCTextNeighboringViewSeparatorHeight;
extern const CGFloat kTemplateCTextSeparatorHeight;

@class VSequence, VStreamCellHeaderView, VStreamCollectionCell;

@interface VStreamCollectionCell : VBaseCollectionViewCell <VSharedCollectionReusableViewMethods>

@property (nonatomic, weak) IBOutlet UIImageView            *previewImageView;
@property (nonatomic, weak) IBOutlet UIImageView            *lowerGradientView;
@property (nonatomic, weak) IBOutlet UIView                 *overlayView;
@property (nonatomic, weak) IBOutlet UIView                 *shadeView;
@property (nonatomic, weak) IBOutlet VStreamCellHeaderView  *streamCellHeaderView;
@property (nonatomic, weak) IBOutlet UILabel                *commentsLabel;

@property (nonatomic, weak) VSequence                       *sequence;

@property (nonatomic, weak) id<VSequenceActionsDelegate> delegate;

@property (nonatomic, weak) UIViewController *parentViewController;

/**
 A rectangle that corresponds to any media asset within this view,
 useful for indicating its visibility when scrolling the collection view.
 */
@property (nonatomic, assign, readonly) CGRect mediaContentFrame;

- (void)hideOverlays;
- (void)showOverlays;
+ (CGSize)actualSizeWithCollectionViewBounds:(CGRect)bounds sequence:(VSequence *)sequence;

- (void)playVideo;
- (void)pauseVideo;

- (void)reloadCommentsCount;

@end
