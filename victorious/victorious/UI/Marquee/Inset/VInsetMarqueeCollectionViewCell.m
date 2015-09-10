//
//  VInsetMarqueeCollectionViewCell.m
//  victorious
//
//  Created by Sharif Ahmed on 4/22/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VInsetMarqueeCollectionViewCell.h"
#import "VInsetMarqueeStreamItemCell.h"
#import "VDependencyManager.h"
#import "VInsetMarqueeCollectionViewFlowLayout.h"

@implementation VInsetMarqueeCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.marqueeCollectionView registerNib:[VInsetMarqueeStreamItemCell nibForCell] forCellWithReuseIdentifier:[VInsetMarqueeStreamItemCell suggestedReuseIdentifier]];
    VInsetMarqueeCollectionViewFlowLayout *collectionViewFlowLayout = [[VInsetMarqueeCollectionViewFlowLayout alloc] init];
    self.marqueeCollectionView.collectionViewLayout = collectionViewFlowLayout;
}

+ (CGSize)desiredSizeWithCollectionViewBounds:(CGRect)bounds
{
    return [VInsetMarqueeStreamItemCell desiredSizeWithCollectionViewBounds:bounds];
}

- (void)setDependencyManager:(VDependencyManager *)dependencyManager
{
    [super dependencyManager];
    if ( dependencyManager != nil )
    {
        self.backgroundColor = [dependencyManager colorForKey:VDependencyManagerSecondaryAccentColorKey];
    }
}

@end