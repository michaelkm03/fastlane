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
#import "VConstants.h"

#import "VUserProfileViewController.h"
#import "VSettingManager.h"

#import <KVOController/FBKVOController.h>

static VLargeNumberFormatter *largeNumberFormatter;

static const CGFloat kUserInfoViewMaxHeight = 25.0f;
static const CGFloat kCommentButtonBuffer = 5.0f;

@interface VStreamCellHeaderView ()

@property (nonatomic, assign) NSInteger defaultUsernameBottomConstraintValue;

@end

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
    self.tintColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVMainTextColor];
    
    if ([[VSettingManager sharedManager] settingEnabledForKey:VSettingsTemplateCEnabled])
    {
        self.usernameLabel.textColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVLinkColor];
        self.parentLabel.textColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVContentTextColor];
        self.dateLabel.textColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVContentTextColor];
    }
    
    self.dateImageView.tintColor = self.dateLabel.textColor;
    
    self.defaultUsernameBottomConstraintValue = self.usernameLabelBottomConstraint.constant;
    
}

- (void)hideCommentsButton
{
    [self.commentButton setHidden:YES];
}

- (void)reloadCommentsCount
{
    if ( ![[VSettingManager sharedManager] settingEnabledForKey:VSettingsTemplateCEnabled] )
    {
        // Get comment count (if any)
        NSString *commentCount = self.sequence.commentCount.integerValue ? [largeNumberFormatter stringForInteger:self.sequence.commentCount.integerValue] : @"";
        [self.commentButton setTitle:commentCount forState:UIControlStateNormal];
    }
}

- (void)setParentText:(NSString *)text
{
    // Format repost / remix string
    NSString *parentUserString;
    if (self.sequence.isRepost.boolValue && self.sequence.parentUser != nil)
    {
        NSUInteger repostCount = [self.sequence.repostCount unsignedIntegerValue];
        if ( repostCount == 0 )
        {
            parentUserString = [NSString stringWithFormat:NSLocalizedString(@"repostedByFormat", nil), text];
        }
        else if ( repostCount == 1 )
        {
            parentUserString = [NSString stringWithFormat:NSLocalizedString(@"doubleRepostedByFormat", nil), text];
        }
        else
        {
            parentUserString = [NSString stringWithFormat:NSLocalizedString(@"multipleRepostedByFormat", nil), text, [self.sequence.repostCount unsignedLongValue]];
        }
    }
    
    if (self.sequence.isRemix.boolValue && self.sequence.parentUser != nil)
    {
        NSString *formatString = NSLocalizedString(@"remixedFromFormat", nil);
        if ([[[[self.sequence firstNode] mp4Asset] playerControlsDisabled] boolValue])
        {
            formatString = NSLocalizedString(@"giffedFromFormat", nil);
        }
        parentUserString = [NSString stringWithFormat:formatString, text];
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

- (void)refreshParentLabelAttributes
{
    [self setParentText:self.sequence.parentUser.name];
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
    
    VUser *originalPoster = self.sequence.user;
    VUser *parentUser = self.sequence.parentUser;
    
    if ( [self.sequence.isRepost boolValue] )
    {
        originalPoster = self.sequence.parentUser;
        parentUser = self.sequence.user;
    }
    
    [self.profileImageButton setProfileImageURL:[NSURL URLWithString:originalPoster.pictureUrl]
                                       forState:UIControlStateNormal];
    
    self.dateLabel.text = [self.sequence.releasedAt timeSince];
    
    [self reloadCommentsCount];
    
    NSString *parentText = @"";
    CGFloat usernameBottomConstant = self.usernameLabelTopConstraint.constant;
    if ( parentUser != nil )
    {
        //Will show "reposted" or "remix" text, so reset the username to it's spot towards the top of the cell
        parentText = parentUser.name;
        usernameBottomConstant = self.defaultUsernameBottomConstraintValue;
    }
    
    [self setParentText:parentText];
    self.usernameLabelBottomConstraint.constant = usernameBottomConstant;
    
    // Set username and format date
    self.usernameLabel.text = originalPoster.name;
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

- (void)setDependencyManager:(VDependencyManager *)dependencyManager
{
    _dependencyManager = dependencyManager;
    UIColor *tintColor = [UIColor whiteColor];
    if ( tintColor != nil )
    {
        self.dateLabel.textColor = tintColor;
        self.parentLabel.textColor = tintColor;
        self.dateImageView.tintColor = tintColor;
        [self refreshParentLabelAttributes];
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
