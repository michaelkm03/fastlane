//
//  VCreatePollViewController.h
//  victorious
//
//  Created by David Keegan on 1/8/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VCreateSequenceDelegate.h"

@interface VCreatePollViewController : UIViewController

@property (weak, nonatomic) id<VCreateSequenceDelegate> delegate;

+ (instancetype)newCreatePollViewControllerWithDelegate:(id<VCreateSequenceDelegate>)delegate;

@end