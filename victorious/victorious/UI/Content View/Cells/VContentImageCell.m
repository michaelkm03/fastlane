//
//  VContentImageCell.m
//  victorious
//
//  Created by Michael Sena on 9/15/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VContentImageCell.h"
#import "VParallaxPatternView.h"

@interface VContentImageCell ()

@property (nonatomic, assign) BOOL updatedImageBounds;

@property (weak, nonatomic) IBOutlet VParallaxPatternView *parallaxPatternView;

@end

@implementation VContentImageCell

#pragma mark - VSharedCollectionReusableViewMethods

+ (CGSize)desiredSizeWithCollectionViewBounds:(CGRect)bounds
{
    return CGSizeMake(CGRectGetWidth(bounds), CGRectGetWidth(bounds));
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    if ( !self.updatedImageBounds )
    {
        /*
         Updating imageView bounds after first time bounds is set
         Assumes cell will never be re-updated to a new "full" size but allows normal content
         resizing to work its magic
         */
        self.updatedImageBounds = YES;
        self.contentImageView.frame = bounds;
    }
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.shrinkingContentView = self.contentImageView;
}

- (void)setPatternBackgroundColor:(UIColor *)patternBackgroundColor
{
    [self.parallaxPatternView setPatternTintColor:patternBackgroundColor];
}

@end
