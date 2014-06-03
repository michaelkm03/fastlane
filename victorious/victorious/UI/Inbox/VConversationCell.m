//
//  VConversationCell.m
//  victorious
//
//  Created by Will Long on 1/8/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VConversationCell.h"
#import "VThemeManager.h"
#import "NSDate+timeSince.h"
#import "VConversation+RestKit.h"
#import "VMessage+RestKit.h"
#import "VUser+RestKit.h"

#import "UIButton+VImageLoading.h"

#import "VUserProfileViewController.h"

//VConversationCell

@implementation VConversationCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    self.dateLabel.font = [[VThemeManager sharedThemeManager] themedFontForKey:kVParagraphFont];
    self.dateLabel.textColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVContentTextColor];
    
    self.messageLabel.font = [[VThemeManager sharedThemeManager] themedFontForKey:kVLabel2Font];
    self.messageLabel.textColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVContentTextColor];
    
    self.usernameLabel.font = [[VThemeManager sharedThemeManager] themedFontForKey:kVHeading3Font];
    self.usernameLabel.textColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVLinkColor];
    
    self.profileImageButton.clipsToBounds = YES;
    self.profileImageButton.layer.cornerRadius = CGRectGetHeight(self.profileImageButton.bounds)/2;
    self.profileImageButton.backgroundColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVSecondaryLinkColor];
    self.profileImageButton.layer.borderColor = self.backgroundColor.CGColor;
    self.profileImageButton.layer.borderWidth = 1.0f;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setSeen:(BOOL)seen
{
//    [self.seenView setHidden:seen];
}

- (void)setConversation:(VConversation *)conversation
{
    self.usernameLabel.text  = conversation.user.name;
    
    [self.profileImageButton setImageWithURL:[NSURL URLWithString:conversation.user.pictureUrl]
                            placeholderImage:[UIImage imageNamed:@"profile_thumb"]
                                    forState:UIControlStateNormal];
    
    self.messageLabel.text = conversation.lastMessage.text;
    [self.messageLabel sizeToFit];
    self.dateLabel.text = [conversation.lastMessage.postedAt timeSince];
    self.seen = conversation.lastMessage.isRead.boolValue;
}

- (IBAction)profileButtonAction:(id)sender
{
    VUserProfileViewController* profileViewController = [VUserProfileViewController userProfileWithUser:self.conversation.user];
    [self.parentTableViewController.navigationController pushViewController:profileViewController animated:YES];
}

@end
