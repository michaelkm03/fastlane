//
//  VShrinkingContentLayout.h
//  victorious
//
//  Created by Michael Sena on 9/29/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

typedef NS_ENUM(NSInteger, VContentViewSection)
{
    VContentViewSectionContent,
    VContentViewSectionPollQuestion,
    VContentViewSectionExperienceEnhancers,
    VContentViewSectionAllComments,
    VContentViewSectionCount
};

extern NSString *const VShrinkingContentLayoutContentBackgroundView;
extern NSString *const VShrinkingContentLayoutAllCommentsHandle;

static const CGFloat VShrinkingContentLayoutMinimumContentHeight = 125.0f;

/**
 *  Shrinking Content Layout. Lays out content/ticker from top top bottom in order for single cells. All Comments begin at the bounds of the collectionview height and subtracting the allCommentsHandleBottomInset property. Further comments are laid out below the handle header for all comments section. NOTE: Relies on the collectionView's delegate to implement UICollectionViewDelegateFlowLayout protocol.
 */
@interface VShrinkingContentLayout : UICollectionViewFlowLayout

/**
 *  How close the collection view is to the lock point relative to the catch point.
 */
- (CGFloat)percentCloseToLockPointFromCatchPoint;

/**
 *  Tells VShrinkingContentLayout to calculate catchPoint and lockPoint after the collectionView becomes aware of its frame information
 */
- (void)calculateCatchAndLockPoints;

@end
