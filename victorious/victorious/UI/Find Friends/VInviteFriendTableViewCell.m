//
//  VInviteFriendTableViewCell.m
//  victorious
//
//  Created by Gary Philipp on 6/12/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VInviteFriendTableViewCell.h"
#import "VUser.h"
#import "VObjectManager.h"
#import "VObjectManager+Login.h"
#import "VFollowControl.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "VFollowResponder.h"
#import "VDependencyManager.h"
#import "VDefaultProfileButton.h"
#import "victorious-Swift.h"

static const CGFloat kInviteCellHeight = 50.0f;

@interface VInviteFriendTableViewCell ()

@property (nonatomic, weak) IBOutlet VDefaultProfileButton *profileButton;
@property (nonatomic, weak) IBOutlet UILabel *profileName;
@property (nonatomic, weak) IBOutlet UIView *labelsSuperview;
@property (nonatomic, strong) UIImage *followIcon;
@property (nonatomic, strong) UIImage *unfollowIcon;

@end

@implementation VInviteFriendTableViewCell

- (void)awakeFromNib
{
    [self.profileButton addBorderWithWidth:1.0f andColor:[UIColor whiteColor]];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    if ([AgeGate isAnonymousUser])
    {
        [self.followUserControl removeFromSuperview];
        self.followUserControl = nil;
    }
}

#pragma mark - VSharedCollectionReusableViewMethods

+ (UINib *)nibForCell
{
    return [UINib nibWithNibName:NSStringFromClass(self) bundle:nil];
}

+ (NSString *)suggestedReuseIdentifier
{
    return NSStringFromClass(self);
}

+ (CGSize)desiredSizeWithCollectionViewBounds:(CGRect)bounds
{
    return CGSizeMake(CGRectGetWidth(bounds), kInviteCellHeight);
}

- (void)setProfile:(VUser *)profile
{
    _profile = profile;
    
    self.profileButton.user = profile;
    self.profileName.text = profile.name;
    
    NSInteger profileID = profile.remoteId.integerValue;
    NSInteger mainUserID = [VObjectManager sharedManager].mainUser.remoteId.integerValue;
    self.followUserControl.hidden = (profileID == mainUserID);
    
    [self updateFollowStatusAnimated:NO];
}

- (BOOL)haveRelationship
{
    BOOL relationship = self.profile.isFollowedByMainUser.boolValue;
    return relationship;
}

- (void)updateFollowStatusAnimated:(BOOL)animated
{
    //If we get into a weird state and the relaionships are the same don't do anything
    
    if (self.followUserControl.controlState == [VFollowControl controlStateForFollowing:self.haveRelationship])
    {
        return;
    }
    
    [self.followUserControl setControlState:[VFollowControl controlStateForFollowing:self.haveRelationship]
                                   animated:animated];
}

- (void)setDependencyManager:(VDependencyManager *)dependencyManager
{
    _dependencyManager = dependencyManager;
    if ( dependencyManager != nil )
    {
        self.followUserControl.dependencyManager = dependencyManager;
        self.profileButton.dependencyManager = dependencyManager;
        self.profileButton.tintColor = [dependencyManager colorForKey:VDependencyManagerLinkColorKey];
        self.profileName.font = [dependencyManager fontForKey:VDependencyManagerLabel1FontKey];
    }
}

#pragma mark - Button Actions

- (IBAction)followUnfollowUser:(VFollowControl *)sender
{
    if ( sender.controlState == VFollowControlStateLoading )
    {
        return;
    }
    
    void (^authorizedBlock)() = ^
    {
        [sender setControlState:VFollowControlStateLoading
                       animated:YES];
    };
    
    void (^completionBlock)(VUser *) = ^(VUser *userActedOn)
    {
        [self updateFollowStatusAnimated:YES];
    };
    
    if ( sender.controlState == VFollowControlStateFollowed )
    {
        id<VFollowResponder> followResponder = [[self nextResponder] targetForAction:@selector(unfollowUser:withAuthorizedBlock:andCompletion:fromViewController:withScreenName:)
                                                                          withSender:nil];
        NSAssert(followResponder != nil, @"%@ needs a VFollowingResponder higher up the chain to communicate following commands with.", NSStringFromClass(self.class));
        
        [followResponder unfollowUser:self.profile
                  withAuthorizedBlock:authorizedBlock
                        andCompletion:completionBlock
                   fromViewController:nil
                       withScreenName:nil];
    }
    else
    {
        id<VFollowResponder> followResponder = [[self nextResponder] targetForAction:@selector(followUser:withAuthorizedBlock:andCompletion:fromViewController:withScreenName:)
                                                                          withSender:nil];
        NSAssert(followResponder != nil, @"%@ needs a VFollowingResponder higher up the chain to communicate following commands with.", NSStringFromClass(self.class));
        
        [followResponder followUser:self.profile
                withAuthorizedBlock:authorizedBlock
                      andCompletion:completionBlock
                 fromViewController:nil
                     withScreenName:nil];
    }
}

@end
