//
//  VProfileViewController.h
//  victorious
//
//  Created by Kevin Choi on 1/5/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

@class  VUser;

@interface VProfileViewController : UIViewController

+ (VProfileViewController *)sharedProfileViewController;
+ (VProfileViewController *)sharedModalProfileViewController;

@property (nonatomic, readwrite, assign) NSUInteger userID;
@end
