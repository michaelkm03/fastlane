//
//  VMarqueeStreamItemCell.m
//  victorious
//
//  Created by Will Long on 9/25/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VMarqueeStreamItemCell.h"

// Stream Support
#import "VStreamItem+Fetcher.h"
#import "VSequence+Fetcher.h"
#import "VUser.h"
#import "VSettingManager.h"
#import "VStreamWebViewController.h"

// Views + Helpers
#import "VDefaultProfileButton.h"
#import "UIView+Autolayout.h"
#import "UIImageView+VLoadingAnimations.h"
#import "UIImage+ImageCreation.h"
#import "VThemeManager.h"

// Dependencies
#import "VDependencyManager.h"

CGFloat const kVDetailVisibilityDuration = 3.0f;
CGFloat const kVDetailHideDuration = 2.0f;
static CGFloat const kVDetailHideTime = 0.3f;
static CGFloat const kVDetailBounceHeight = 8.0f;
static CGFloat const kVDetailBounceTime = 0.15f;
static CGFloat const kTitleOffsetForTemplateC = 6.5f;

@interface VMarqueeStreamItemCell ()

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

@property (nonatomic, weak) IBOutlet UIView *backgroundContainer;
@property (nonatomic, weak) IBOutlet UIImageView *previewImageView;
@property (nonatomic, weak) IBOutlet UIImageView *pollOrImageView;
@property (nonatomic, weak) IBOutlet UIView *webViewContainer;
@property (nonatomic, weak) IBOutlet UIView *detailsContainer;
@property (nonatomic, weak) IBOutlet UIView *detailsBackgroundView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *detailsBottomLayoutConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *detailsHeightLayoutConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *labelTopLayoutConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *labelBottomLayoutConstraint;
@property (nonatomic, strong) VStreamWebViewController *webViewController;

@property (nonatomic, weak) IBOutlet VDefaultProfileButton *profileImageButton;

@property (nonatomic, strong) NSTimer *hideTimer;

@end

static CGFloat const kVCellHeightRatio = 0.884375; //from spec, 283 height for 360 width

@implementation VMarqueeStreamItemCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.profileImageButton.layer.borderWidth = 4;
    
    self.nameLabel.font = [[VThemeManager sharedThemeManager] themedFontForKey:kVHeading3Font];
}

- (void)setStreamItem:(VStreamItem *)streamItem
{
    _streamItem = streamItem;
    
    self.nameLabel.text = streamItem.name;

    NSURL *previewImageUrl = [NSURL URLWithString: [streamItem.previewImagePaths firstObject]];
    [self.previewImageView fadeInImageAtURL:previewImageUrl
                           placeholderImage:nil];
    
    self.detailsBackgroundView.backgroundColor = [[VThemeManager sharedThemeManager] preferredBackgroundColor];
    
    if ( [streamItem isKindOfClass:[VSequence class]] )
    {
        VSequence *sequence = (VSequence *)streamItem;
        
        self.pollOrImageView.hidden = ![sequence isPoll];
        
        [self.profileImageButton setProfileImageURL:[NSURL URLWithString:sequence.user.pictureUrl]
                                           forState:UIControlStateNormal];
        
        if ( [sequence isWebContent] )
        {
            [self setupWebViewWithSequence:sequence];
        }
        else
        {
            [self cleanupWebView];
        }
    }
    else
    {
        self.profileImageButton.hidden = YES;
    }
    
    //Timer for marquee details auto-hiding
    [self setDetailsContainerVisible:YES animated:NO];
    [self restartHideTimer];
}

- (void)setHideMarqueePosterImage:(BOOL)hideMarqueePosterImage
{
    if ( self.hideMarqueePosterImage == hideMarqueePosterImage )
    {
        return;
    }
    
    _hideMarqueePosterImage = hideMarqueePosterImage;
    self.profileImageButton.hidden = self.hideMarqueePosterImage;
    if ( self.hideMarqueePosterImage )
    {
        self.labelTopLayoutConstraint.constant -= kTitleOffsetForTemplateC;
        self.labelBottomLayoutConstraint.constant += kTitleOffsetForTemplateC;
        [self layoutIfNeeded];
    }
}

- (void)setDependencyManager:(VDependencyManager *)dependencyManager
{
    [super setDependencyManager:dependencyManager];
    if ( self.dependencyManager != nil )
    {
        self.detailsBackgroundView.backgroundColor = [self.dependencyManager colorForKey:VDependencyManagerBackgroundColorKey];
        self.nameLabel.textColor = [self.dependencyManager colorForKey:VDependencyManagerLinkColorKey];
        self.profileImageButton.layer.borderColor = [self.dependencyManager colorForKey:VDependencyManagerMainTextColorKey].CGColor;
    }
}

- (void)restartHideTimer
{
    [self.hideTimer invalidate];
    self.hideTimer = [NSTimer scheduledTimerWithTimeInterval:kVDetailVisibilityDuration
                                                      target:self
                                                    selector:@selector(hideDetailContainer)
                                                    userInfo:nil
                                                     repeats:NO];
}

#pragma mark - Detail container animation

//Selector hit by timer
- (void)hideDetailContainer
{
    [self setDetailsContainerVisible:NO animated:YES];
}

- (void)setDetailsContainerVisible:(BOOL)visible animated:(BOOL)animated
{
    CGFloat targetConstraintValue = visible ? -kVDetailBounceHeight : - self.detailsContainer.bounds.size.height;
    
    if ( animated )
    {
        [UIView animateWithDuration:kVDetailBounceTime animations:^
        {
            self.detailsBottomLayoutConstraint.constant = 0.0f;
            [self layoutIfNeeded];
        }
        completion:^(BOOL finished)
        {
            [UIView animateWithDuration:kVDetailHideTime animations:^
             {
                 self.detailsBottomLayoutConstraint.constant = targetConstraintValue;
                 [self layoutIfNeeded];
             }];
        }];
    }
    else
    {
        self.detailsBottomLayoutConstraint.constant = targetConstraintValue;
    }
}

#pragma mark - Cell setup

- (void)cleanupWebView
{
    if ( self.webViewController != nil )
    {
        [self.webViewController.view removeFromSuperview];
        self.webViewController = nil;
        self.previewImageView.hidden = NO;
    }
}

- (void)setupWebViewWithSequence:(VSequence *)sequence
{
    if ( self.webViewController == nil )
    {
        self.webViewController = [[VStreamWebViewController alloc] init];
        self.webViewController.view.backgroundColor = [UIColor clearColor];
        [self.webViewContainer addSubview:self.webViewController.view];
        [self.webViewContainer v_addFitToParentConstraintsToSubview:self.webViewController.view];
        self.previewImageView.hidden = YES;
    }
    
    NSString *contentUrl = (NSString *)sequence.previewData;
    [self.webViewController setUrl:[NSURL URLWithString:contentUrl]];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.streamItem = nil;
    [self setDetailsContainerVisible:YES animated:NO];
}

- (IBAction)userSelected:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cell:selectedUser:)])
    {
        [self.delegate cell:self selectedUser:((VSequence *)self.streamItem).user];
    }
}

#pragma mark - VSharedCollectionReusableViewMethods

+ (NSString *)suggestedReuseIdentifier
{
    return NSStringFromClass([self class]);
}

+ (UINib *)nibForCell
{
    return [UINib nibWithNibName:NSStringFromClass([self class])
                          bundle:nil];
}

+ (CGSize)desiredSizeWithCollectionViewBounds:(CGRect)bounds
{
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = width * kVCellHeightRatio;
    return CGSizeMake(width, height);
}

#pragma mark - VBackgroundContainer

- (UIView *)backgroundContainerView
{
    return self.backgroundContainer;
}

@end
