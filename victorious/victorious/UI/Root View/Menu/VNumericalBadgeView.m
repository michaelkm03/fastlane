//
//  VNumericalBadgeView.m
//  victorious
//
//  Created by David Keegan on 1/2/14.
//  Copyright (c) 2014 Will Long. All rights reserved.
//

#import "VBadgeBackgroundView.h"
#import "VDependencyManager.h"
#import "VNumericalBadgeView.h"
#import "VBadgeStringFormatter.h"

@interface VNumericalBadgeView ()

@property (nonatomic, weak) UILabel *label;
@property (nonatomic, weak) VBadgeBackgroundView *backgroundView;

@end

static CGFloat kMaxFontPointSize = 12.0f;
static UIEdgeInsets const kMargin = { 2.0f, 4.0f, 2.0f, 4.0f };

@implementation VNumericalBadgeView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (UIColor *)defaultBadgeColor
{
    return [UIColor colorWithRed:0.88f green:0.18f blue:0.22f alpha:1.0f];
}

- (void)commonInit
{
    super.backgroundColor = [UIColor clearColor];
    
    VBadgeBackgroundView *backgroundView = [[VBadgeBackgroundView alloc] init];
    backgroundView.color = self.defaultBadgeColor;
    backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:backgroundView];
    _backgroundView = backgroundView;
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[backgroundView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(backgroundView)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[backgroundView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(backgroundView)]];
    
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    [self addSubview:label];
    _label = label;
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeWidth
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeHeight
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0f
                                                      constant:0.0f]];
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [self.label intrinsicContentSize];
    
    if ( size.width == 0 || size.height == 0 )
    {
        return CGSizeZero;
    }
    
    // We should be at least as wide as we are tall, or the badge background will be lemon-shaped!
    return CGSizeMake(MAX(size.width + kMargin.left + kMargin.right, size.height + kMargin.top + kMargin.bottom),
                      size.height + kMargin.top + kMargin.bottom);
}

- (UIFont *)font
{
    return self.label.font;
}

- (void)setFont:(UIFont *)font
{
    self.label.font = [UIFont fontWithName:font.fontName size:MIN(font.pointSize, kMaxFontPointSize)];
    [self invalidateIntrinsicContentSize];
}

- (UIColor *)backgroundColor
{
    return self.backgroundView.color;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    self.backgroundView.color = backgroundColor;
}

- (UIColor *)textColor
{
    return self.label.textColor;
}

- (void)setTextColor:(UIColor *)textColor
{
    self.label.textColor = textColor;
}

- (void)setBadgeNumber:(NSInteger)badgeNumber
{
    if (badgeNumber == _badgeNumber)
    {
        return;
    }
    _badgeNumber = badgeNumber;
    
    self.label.text = badgeNumber == 0 ? @"" : [VBadgeStringFormatter formattedBadgeStringForBadgeNumber:badgeNumber];
    [self invalidateIntrinsicContentSize];
}

@end
