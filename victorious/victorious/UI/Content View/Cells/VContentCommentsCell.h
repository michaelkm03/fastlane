//
//  VContentCommentsCell.h
//  victorious
//
//  Created by Michael Sena on 9/15/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VSwipeCollectionViewCell.h"

#import "VCellFocus.h"

@class VComment, VCommentTextAndMediaView, VDependencyManager, VSequencePermissions;

/**
 *  UICollectionViewCell for representing a general comment on an item.
 */
@interface VContentCommentsCell : VSwipeCollectionViewCell <VCellFocus>

@property (nonatomic, strong) VComment *comment;
@property (nonatomic, readonly) NSURL *mediaURL;
@property (nonatomic, strong) VDependencyManager *dependencyManager;
@property (nonatomic, strong) VSequencePermissions *sequencePermissions;

@property (nonatomic, copy) void (^onMediaTapped)();
@property (nonatomic, copy) void (^onUserProfileTapped)();

@property (nonatomic, readonly) UIImage *previewImage;
@property (nonatomic, readonly) UIView *previewView;
@property (nonatomic, readonly) BOOL mediaIsVideo;

@property (weak, nonatomic) IBOutlet VCommentTextAndMediaView *commentAndMediaView;

+ (NSCache *)sharedImageCached;

+ (void)clearSharedImageCache;

/**
 *  Sizing method for delegates.
 *
 *  @param width       The full width that will be provided to the cell. The cell grows vertically so only width is needed.
 *  @param commentBody The text of the comment.
 *  @param hasMedia    A boolean if the comment has media or not.
 *
 *  @return The size required to display the cell at full size.
 */
+ (CGSize)sizeWithFullWidth:(CGFloat)width
                    comment:(VComment *)comment
                   hasMedia:(BOOL)hasMedia
          dependencyManager:(VDependencyManager *)dependencyManager;

@end
