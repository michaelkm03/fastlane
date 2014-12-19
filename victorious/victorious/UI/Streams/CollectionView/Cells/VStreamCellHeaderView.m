//
//  VStreamCellHeaderView.m
//  victorious
//
//  Created by Lawrence Leach on 9/10/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VStreamCellHeaderView.h"
#import "VDefaultProfileButton.h"

#import "VSequence.h"
#import "VObjectManager+Sequence.h"
#import "VThemeManager.h"
#import "NSDate+timeSince.h"
#import "VUser.h"
#import "VSequence+Fetcher.h"
#import "VNode+Fetcher.h"
#import "VAsset.h"
#import "VLargeNumberFormatter.h"
#import "UIImage+ImageCreation.h"
#import "UIButton+VImageLoading.h"
#import "VConstants.h"

#import "VUserProfileViewController.h"
#import "VSettingManager.h"

#import <KVOController/FBKVOController.h>

static VLargeNumberFormatter *largeNumberFormatter;

static const CGFloat kUserInfoViewMaxHeight = 25.0f;
static const CGFloat kCommentButtonBuffer = 5.0f;

@implementation VStreamCellHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

- (void)commonInit
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(void)
    {
        largeNumberFormatter = [[VLargeNumberFormatter alloc] init];
    });
    
    _commentViews = [[NSMutableArray alloc] init];
    
    self.dateImageView.image = [self.dateImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.commentButton setTitleEdgeInsets:UIEdgeInsetsMake(0, kCommentButtonBuffer, 0, 0)];

    // Style the ui
    self.usernameLabel.font = [[VThemeManager sharedThemeManager] themedFontForKey:kVLabel1Font];
    self.parentLabel.font = [[VThemeManager sharedThemeManager] themedFontForKey:kVLabel3Font];
    self.dateLabel.font = [[VThemeManager sharedThemeManager] themedFontForKey:kVLabel3Font];
    [self.commentButton.titleLabel setFont:[[VThemeManager sharedThemeManager] themedFontForKey:kVLabel3Font]];
    
    if ([[VSettingManager sharedManager] settingEnabledForKey:VSettingsTemplateCEnabled])
    {
        self.usernameLabel.textColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVLinkColor];
        self.parentLabel.textColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVContentTextColor];
        self.dateLabel.textColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVContentTextColor];
    }
    
    self.dateImageView.tintColor = self.dateLabel.textColor;
}

- (void)hideCommentsButton
{
    [self.commentButton setHidden:YES];
}

- (void)setParentText:(NSString *)text
{
    // Format repost / remix string
    NSString *parentUserString;
    if (self.sequence.isRepost.boolValue && self.sequence.parentUser != nil)
    {
        parentUserString = [NSString stringWithFormat:NSLocalizedString(@"repostedFromFormat", nil), text];
    }
    
    if (self.sequence.isRemix.boolValue && self.sequence.parentUser != nil)
    {
        parentUserString = [NSString stringWithFormat:NSLocalizedString(@"remixedFromFormat", nil), text];
    }
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName: self.parentLabel.font,
                                 NSForegroundColorAttributeName:  self.parentLabel.textColor,
                                 };
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:parentUserString ?: @""
                                                                                         attributes:attributes];
    if ([[VSettingManager sharedManager] settingEnabledForKey:VSettingsTemplateCEnabled])
    {
        NSRange range = [parentUserString rangeOfString:text];
        
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:[[VThemeManager sharedThemeManager] themedColorForKey:kVLinkColor]
                                 range:range];
    }
    
    self.parentLabel.attributedText = attributedString;
}

- (void)setSequence:(VSequence *)sequence
{
    if (_sequence == sequence)
    {
        return;
    }
    
    [self.KVOController unobserve:sequence.user];
    
    _sequence = sequence;
    
    if (sequence.user == nil)
    {
        return;
    }
    
    __weak typeof(self) welf = self;
    [self.KVOController observe:sequence.user
                       keyPaths:@[NSStringFromSelector(@selector(name)), NSStringFromSelector(@selector(pictureUrl))]
                        options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          block:^(id observer, id object, NSDictionary *change)
     {
         [welf updateWithCurrentUser];
     }];
}

- (void)updateWithCurrentUser
{
    if (self.sequence.user == nil)
    {
        return;
    }
    
    [self.profileImageButton setProfileImageURL:[NSURL URLWithString:self.sequence.user.pictureUrl]
                                       forState:UIControlStateNormal];
    
    self.dateLabel.text = [self.sequence.releasedAt timeSince];
    
    // Get comment count (if any)
    NSString *commentCount = self.sequence.commentCount.integerValue ? [largeNumberFormatter stringForInteger:self.sequence.commentCount.integerValue] : @"";
    [self.commentButton setTitle:commentCount forState:UIControlStateNormal];
    
    [self setParentText:self.sequence.parentUser.name];
    // Set username and format date
    self.usernameLabel.text = self.sequence.user.name;
    self.dateLabel.text = [self.sequence.releasedAt timeSince];
    
    // Check if this is a repost / remix and size the userInfoView accordingly
    if (self.sequence.parentUser)
    {
        self.userInfoViewHeightConstraint.constant = kUserInfoViewMaxHeight;
    }
    else
    {
        self.userInfoViewHeightConstraint.constant = self.usernameLabel.intrinsicContentSize.height;
    }
}

#pragma mark - Button Actions

- (IBAction)profileButtonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(selectedUserOnSequence:fromView:)])
    {
        [self.delegate selectedUserOnSequence:self.sequence fromView:self];
    }
}

- (IBAction)commentButtonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(willCommentOnSequence:fromView:)])
    {
        [self.delegate willCommentOnSequence:self.sequence fromView:self];
    }
}

@end