//
//  UIImageView+VLoadingAnimations.h
//  victorious
//
//  Created by Will Long on 9/25/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (VLoadingAnimations)

- (void)fadeInImageAtURL:(NSURL *)url
        placeholderImage:(UIImage *)image;
- (void)fadeInImage:(UIImage *)image;

@end
