//
//  UIImage+Round.h
//  victorious
//
//  Created by Cody Kolodziejzyk on 5/6/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Round)

/**
 *  Returns a new image with rounded corners
 */
- (UIImage *)roundedImageWithCornerRadius:(CGFloat)cornerRadius;

@end
