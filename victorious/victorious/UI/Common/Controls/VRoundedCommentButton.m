//
//  VRoundedCommentButton.m
//  victorious
//
//  Created by Michael Sena on 4/21/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VRoundedCommentButton.h"

// Dependencies
#import "VDependencyManager.h"

// Helpers
#import "UIView+AutoLayout.h"

static CGFloat const kCommentWidth = 68.0f;
static CGFloat const kActionButtonHeight = 31.0f;
static NSString * const kCommentIconKey = @"commentIcon";

@implementation VRoundedCommentButton

#pragma mark - UIView

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(kCommentWidth, kActionButtonHeight);
}

#pragma mark - VHasManagedDependencies

- (void)setDependencyManager:(VDependencyManager *)dependencyManager
{
    self.unselectedColor = [dependencyManager colorForKey:VDependencyManagerLinkColorKey];
    self.titleLabel.font = [dependencyManager fontForKey:VDependencyManagerLabel3FontKey];
    [self setImage:[dependencyManager imageForKey:kCommentIconKey] forState:UIControlStateNormal];
}

@end
