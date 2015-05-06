//
//  VNotLoggedInProfileCollectionViewCell.m
//  victorious
//
//  Created by Michael Sena on 3/6/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VNotAuthorizedProfileCollectionViewCell.h"

#import "UIView+AutoLayout.h"
#import "VNoContentView.h"
#import "VButton.h"
#import "VDependencyManager.h"

@interface VNotAuthorizedProfileCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIView *noContentViewContainer;
@property (weak, nonatomic) VNoContentView *noContentView;
@property (weak, nonatomic) IBOutlet VButton *loginButton;

@end

@implementation VNotAuthorizedProfileCollectionViewCell

#pragma mark - VSharedCollectionReusableViewMethods

+ (CGSize)desiredSizeWithCollectionViewBounds:(CGRect)bounds
{
    return CGSizeMake(CGRectGetWidth(bounds), 400.0f);
}

#pragma mark - NSObject

- (void)awakeFromNib
{
    VNoContentView *noContentView = [VNoContentView noContentViewWithFrame:self.noContentViewContainer.bounds];
    noContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.noContentViewContainer addSubview:noContentView];
    [self.noContentViewContainer v_addFitToParentConstraintsToSubview:noContentView];
    noContentView.iconImageView.image = [[UIImage imageNamed:@"profileGenericUser"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    noContentView.titleLabel.text = NSLocalizedString(@"You're not logged in!", @"");
    noContentView.messageLabel.text = NSLocalizedString(@"ProfileNotLoggedInMessage", @"User is not logged in message.");
    self.noContentView = noContentView;
    
    [self.loginButton setStyle:VButtonStylePrimary];
    [self.loginButton setTitle:NSLocalizedString(@"Login", @"") forState:UIControlStateNormal];
}

#pragma mark - Properties

- (void)setDependencyManager:(VDependencyManager *)dependencyManager
{
    _dependencyManager = dependencyManager;
    if ( dependencyManager != nil )
    {
        if ( [self.noContentView respondsToSelector:@selector(setDependencyManager:)] )
        {
            self.noContentView.dependencyManager = self.dependencyManager;
        }
        self.noContentView.iconImageView.tintColor = [dependencyManager colorForKey:VDependencyManagerLinkColorKey];
        self.loginButton.primaryColor = [dependencyManager colorForKey:VDependencyManagerLinkColorKey];
        self.loginButton.titleLabel.font = [dependencyManager fontForKey:VDependencyManagerHeading2FontKey];
    }
}

#pragma mark - Target/Action

- (IBAction)loginPressed:(id)sender
{
    [self requestLogin];
}

#pragma mark - Private Methods

- (void)requestLogin
{
    [self.delegate notAuthorizedProfileCellWantsLogin:self];
}

@end