//
//  VFindFriendsTableView.h
//  victorious
//
//  Created by Josh Hinman on 6/20/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VFindFriendsTableViewController;

@interface VFindFriendsTableView : UIView

@property (nonatomic, weak) IBOutlet UIView      *disconnectedView; ///< Unhide this view to prompt the user to connect to the social network
@property (nonatomic, weak) IBOutlet UIView      *connectedView; ///< Unhide this view after the user has connected to the social network
@property (nonatomic, weak) IBOutlet UIView      *errorView; ///< Unhide this view if an error occurs loading friends
@property (nonatomic, weak) IBOutlet UIView      *busyOverlay; ///< Unhide this view to dim the view and display an activity spinner

@property (nonatomic, weak) IBOutlet UILabel     *connectPromptLabel;
@property (nonatomic, weak) IBOutlet UIButton    *connectButton;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UILabel     *errorLabel;
@property (nonatomic, weak) IBOutlet UIButton    *retryButton;

+ (VFindFriendsTableView *)newFromNibWithOwner:(VFindFriendsTableViewController *)nibOwner;

@end
