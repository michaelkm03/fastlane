//
//  UIColor+VBrightness.h
//  victorious
//
//  Created by Patrick Lynch on 12/8/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, VColorLuminance)
{
    VColorLuminanceBright,
    VColorLuminanceDark,
};

/**
 *  Use this constant to highlight by a standard amount.
 */
extern CGFloat VDefaultHighlightAmount;

@interface UIColor (VBrightness)

- (VColorLuminance)v_colorLuminance;

/**
 Returns a new color darkened according to the `amount` parameter where
 a value of 1.0 will make the color black, 0.0 will not change the color,
 and anything in between will bring each color channel's that much closer
 to 0.0, effectively bringing all color channels closer to black.
 */
- (UIColor *)v_colorLightenedBy:(CGFloat)amount;

/**
 Returns a new color brightened according to the `amount` parameter where
 a value of 1.0 will make the color white, 0.0 will not change the color,
 and anything in between will bring each color channel's that much closer
 to 1.0, effectively bringing all color channels closer to white.
 */
- (UIColor *)v_colorDarkenedBy:(CGFloat)amount;

/**
 *  Returns a new color either brightened or darkened according to luminance. 
 *  luminanceBright -> darkenedBy:
 *  luminanceDark   -> lightenedBy:
 */
- (UIColor *)v_highlightColorBy:(CGFloat)amount;

@end
