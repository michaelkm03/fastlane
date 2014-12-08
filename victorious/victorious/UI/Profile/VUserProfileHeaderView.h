//
//  VUserProfileHeaderView.h
//  victorious
//
//  Created by Will Long on 6/18/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VUser, VDefaultProfileImageView;

@protocol VUserProfileHeaderDelegate <NSObject>

@required
- (void)editProfileHandler;
- (void)followerHandler;
- (void)followingHandler;

@end

@interface VUserProfileHeaderView : UIView

@property (nonatomic, weak) IBOutlet VDefaultProfileImageView *profileImageView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *taglineLabel;

@property (nonatomic, weak) IBOutlet UILabel *followersLabel;
@property (nonatomic, weak) IBOutlet UILabel *followersHeader;
@property (nonatomic, weak) IBOutlet UILabel *followingLabel;
@property (nonatomic, weak) IBOutlet UILabel *followingHeader;

@property (nonatomic, weak) IBOutlet UIButton *editProfileButton;

@property (nonatomic, strong) UIActivityIndicatorView *followButtonActivityIndicator;

@property (nonatomic, strong) VUser *user;
@property (nonatomic, weak) id<VUserProfileHeaderDelegate> delegate;

@property (nonatomic) NSInteger numberOfFollowers;
@property (nonatomic) NSInteger numberOfFollowing;

+ (instancetype)newViewWithFrame:(CGRect)frame;

@end
