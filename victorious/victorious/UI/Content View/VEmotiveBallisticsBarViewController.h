//
//  VEmotiveBallisticsViewController.h
//  victorious
//
//  Created by Will Long on 2/27/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VEmotiveBallisticsBarViewController : UIViewController

@property (weak, nonatomic) UIView* target;

+ (VEmotiveBallisticsBarViewController *)sharedInstance;

- (void)animateIn;
- (void)animateOut;

@end
