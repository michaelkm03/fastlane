//
//  VRoundedBackgroundButton.m
//  victorious
//
//  Created by Michael Sena on 3/16/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VRoundedBackgroundButton.h"
#import <objc/runtime.h>

static const CGFloat kHighlightedAlpha = 0.7f;
static const CGFloat kHighlightedScale = 0.8f;

@interface VRoundedBackgroundButton ()

@property (nonatomic, strong) CAShapeLayer *circleLayer;
@property (nonatomic, copy) UIColor *defaultTintColor;

@end

@implementation VRoundedBackgroundButton

#pragma mark - UIView Overrides

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.circleLayer == nil)
    {
        self.circleLayer = [CAShapeLayer layer];
        [self.layer insertSublayer:self.circleLayer atIndex:0];
    }
    
    self.circleLayer.fillColor = self.selected ? self.selectedColor.CGColor : self.unselectedColor.CGColor;
    self.circleLayer.bounds = self.bounds;
    self.circleLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                     byRoundingCorners:UIRectCornerAllCorners
                                                           cornerRadii:self.bounds.size];
    self.circleLayer.path = circlePath.CGPath;
}

#pragma mark - UIControl Overrides

- (void)setTintColor:(UIColor *)tintColor
{
    super.tintColor = tintColor;
    self.defaultTintColor = tintColor;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    self.circleLayer.fillColor = selected ? self.selectedColor.CGColor : self.unselectedColor.CGColor;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    self.alpha = highlighted ? kHighlightedAlpha : 1.0f;
    self.circleLayer.affineTransform = highlighted ? CGAffineTransformMakeScale(kHighlightedScale, kHighlightedScale) : CGAffineTransformIdentity;
}

- (void)setActive:(BOOL)active
{
    _active = active;
    
    UIImage *image = active ? self.activeImage : self.inactiveImage;
    if ( self.activeColor != nil )
    {
        super.tintColor = active ? self.activeColor : self.defaultTintColor; //< Use super.tintColor, self is overridden
    }
    [self setImage:image forState:UIControlStateNormal];
}

- (void)setInactiveImage:(UIImage *)inactiveImage
{
    _inactiveImage = inactiveImage;
    [self setImage:_inactiveImage forState:UIControlStateNormal];
}

#pragma mark - Property Accessors

- (void)setSelectedColor:(UIColor *)selectedColor
{
    _selectedColor = [selectedColor copy];
    
    self.circleLayer.fillColor = self.selected ? selectedColor.CGColor : self.unselectedColor.CGColor;
    [self setNeedsLayout];
}

- (void)setUnselectedColor:(UIColor *)unselectedColor
{
    _unselectedColor = [unselectedColor copy];
    
    self.circleLayer.fillColor = self.selected ? self.selectedColor.CGColor : _unselectedColor.CGColor;
    [self setNeedsLayout];
}

@end
