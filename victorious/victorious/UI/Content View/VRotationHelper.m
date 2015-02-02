//
//  VRotationHelper.m
//  victorious
//
//  Created by Patrick Lynch on 2/2/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VRotationHelper.h"

@interface VRotationHelper()

@property (nonatomic, assign) CGPoint preRotationContentOffset;
@property (nonatomic, assign, readwrite) BOOL isLandscape;

@end

@implementation VRotationHelper

- (void)handleRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                    duration:(NSTimeInterval)duration
                         targetContentOffset:(CGPoint)targetContentOffset
                              collectionView:(UICollectionView *)collectionView
                        landscapeHiddenViews:(NSArray *)landscapeHiddenViews
{
    self.isLandscape = UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
    
    [landscapeHiddenViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop)
     {
         view.hidden = self.isLandscape;
     }];
    
    if ( self.isLandscape )
    {
        self.preRotationContentOffset = collectionView.contentOffset;
        [collectionView setContentOffset:targetContentOffset animated:NO];
        collectionView.scrollEnabled = NO;
    }
    else
    {
        [collectionView setContentOffset:self.preRotationContentOffset animated:NO];
        collectionView.scrollEnabled = YES;
    }
}

@end
