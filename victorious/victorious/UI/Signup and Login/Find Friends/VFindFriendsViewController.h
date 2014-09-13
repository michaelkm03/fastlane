//
//  VFindFriendsViewController.h
//  victorious
//
//  Created by Josh Hinman on 6/20/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VFindFriendsViewController : UIViewController

@property (nonatomic) BOOL shouldAutoselectNewFriends; ///< If YES, new friends will be automatically selected as they're displayed

+ (VFindFriendsViewController *)newFindFriendsViewController;

@end