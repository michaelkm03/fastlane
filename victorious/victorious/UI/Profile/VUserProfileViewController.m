//
//  VUserProfileViewController.m
//  victorious
//
//  Created by Gary Philipp on 5/8/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VUserProfileViewController.h"
#import "VUser.h"
#import "VLoginViewController.h"
#import "VObjectManager+Users.h"
#import "VObjectManager+DirectMessaging.h"
#import "VProfileEditViewController.h"
#import "VFollowerTableViewController.h"
#import "VFollowingTableViewController.h"
#import "VMessageContainerViewController.h"
#import "UIImage+ImageEffects.h"
#import "UIImageView+Blurring.h"
#import "VObjectManager+Login.h"
#import <UIImageView+WebCache.h>
#import "VStream+Fetcher.h"

#import "VObjectManager+ContentCreation.h"

#import "VInboxViewController.h"

#import "VUserProfileHeaderView.h"
#import "VProfileHeaderCell.h"

#import "VAuthorizedAction.h"
#import "VDependencyManager+VNavigationItem.h"
#import "VDependencyManager+VNavigationMenuItem.h"
#import "VFindFriendsViewController.h"
#import "VSettingManager.h"
#import <FBKVOController.h>
#import <MBProgressHUD.h>
#import "VDependencyManager.h"
#import "VBaseCollectionViewCell.h"
#import "UIImage+ImageCreation.h"

#import "VDependencyManager+VScaffoldViewController.h"

// Authorization
#import "VNotAuthorizedDataSource.h"
#import "VNotAuthorizedProfileCollectionViewCell.h"

static const CGFloat kVSmallUserHeaderHeight = 319.0f;

static void * VUserProfileViewContext = &VUserProfileViewContext;
static void * VUserProfileAttributesContext =  &VUserProfileAttributesContext;
/*
 According to MBProgressHUD.h, a 37 x 37 square is the best fit for a custom view within a MBProgressHUD
 */
static const CGFloat MBProgressHUDCustomViewSide = 37.0f;

// dependency manager keys
static NSString * const kUserProfileViewComponentKey = @"userProfileView";
static NSString * const kUserKey = @"user";
static NSString * const kUserRemoteIdKey = @"remoteId";
static NSString * const kFindFriendsIconKey = @"findFriendsIcon";

@interface VUserProfileViewController () <VUserProfileHeaderDelegate, MBProgressHUDDelegate, VNotAuthorizedDataSourceDelegate>

@property   (nonatomic, strong) VUser                  *profile;
@property (nonatomic, strong) NSNumber *remoteId;

@property (nonatomic, strong) VUserProfileHeaderView *profileHeaderView;
@property (nonatomic, strong) VProfileHeaderCell *currentProfileCell;
@property (nonatomic) CGSize currentProfileSize;

@property (nonatomic, strong) UIImageView              *backgroundImageView;
@property (nonatomic) BOOL                            isMe;

@property (nonatomic, strong) MBProgressHUD *retryHUD;
@property (nonatomic, strong) UIButton *retryProfileLoadButton;

@property (nonatomic, assign) BOOL didEndViewWillAppear;

@property (nonatomic, assign) CGFloat defaultMBProgressHUDMargin;

@property (nonatomic, strong) VNotAuthorizedDataSource *notLoggedInDataSource;

@end

@implementation VUserProfileViewController

+ (instancetype)userProfileWithRemoteId:(NSNumber *)remoteId andDependencyManager:(VDependencyManager *)dependencyManager
{
    NSParameterAssert(dependencyManager != nil);
    VUserProfileViewController   *viewController  =   [[UIStoryboard storyboardWithName:@"Profile" bundle:nil] instantiateInitialViewController];
    
    VUser *mainUser = [VObjectManager sharedManager].mainUser;
    BOOL isMe = (mainUser != nil && remoteId.integerValue == mainUser.remoteId.integerValue);
    
    //Set the dependencyManager before setting the profile since setting the profile creates the profileHeaderView
    viewController.dependencyManager = dependencyManager;

    if ( !isMe )
    {
        viewController.remoteId = remoteId;
    }
    else
    {
        viewController.profile = mainUser;
    }
    
    return viewController;
}

+ (instancetype)userProfileWithUser:(VUser *)aUser andDependencyManager:(VDependencyManager *)dependencyManager
{
    NSParameterAssert(dependencyManager != nil);
    VUserProfileViewController   *viewController  =   [[UIStoryboard storyboardWithName:@"Profile" bundle:nil] instantiateInitialViewController];
    
    //Set the dependencyManager before setting the profile since setting the profile creates the profileHeaderView
    viewController.dependencyManager = dependencyManager;
    
    viewController.profile = aUser;
    
    BOOL isMe = ([VObjectManager sharedManager].mainUser != nil && aUser.remoteId.integerValue == [VObjectManager sharedManager].mainUser.remoteId.integerValue);
    
    if (isMe)
    {
        viewController.title = NSLocalizedString(@"me", "");
    }
    else
    {
        viewController.title = aUser.name ?: @"Profile";
    }
    
    return viewController;
}

+ (instancetype)newWithDependencyManager:(VDependencyManager *)dependencyManager
{
    VUser *user = [dependencyManager templateValueOfType:[VUser class] forKey:kUserKey];
    if ( user != nil )
    {
        return [self userProfileWithUser:user andDependencyManager:dependencyManager];
    }
    
    NSNumber *remoteId = [dependencyManager templateValueOfType:[NSNumber class] forKey:kUserRemoteIdKey];
    if ( remoteId != nil )
    {
        return [self userProfileWithRemoteId:remoteId andDependencyManager:dependencyManager];
    }
    
    return nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil)
    {
        [self userProfileSharedInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil)
    {
        [self userProfileSharedInit];
    }
    return self;
}

- (void)userProfileSharedInit
{
    self.canShowContent = NO;
}

- (BOOL)canShowMarquee
{
    //This will stop our superclass from adjusting the "hasHeaderCell" property, which in turn affects whether or not the profileHeader is shown, based on whether or not this stream contains a marquee
    return NO;
}

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginStatusChanged:) name:kLoggedInChangedNotification object:nil];

    [self.dependencyManager addPropertiesToNavigationItem:self.navigationItem
                                 pushAccessoryMenuItemsOn:self.navigationController];
    
    self.streamDataSource.hasHeaderCell = YES;
    self.collectionView.alwaysBounceVertical = YES;
    
    UIColor *backgroundColor = [self.dependencyManager colorForKey:VDependencyManagerBackgroundColorKey];
    self.collectionView.backgroundColor = backgroundColor;
    
    if (![VObjectManager sharedManager].mainUser)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loginStateDidChange:)
                                                     name:kLoggedInChangedNotification
                                                   object:nil];
    }
    
    [self.KVOController observe:self.currentStream
                        keyPath:@"sequences"
                        options:NSKeyValueObservingOptionNew
                        context:VUserProfileViewContext];
    
    [self.collectionView registerClass:[VProfileHeaderCell class] forCellWithReuseIdentifier:NSStringFromClass([VProfileHeaderCell class])];
    
    [self updateCollectionViewDataSource];
    
    [self loadBackgroundImage];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadBackgroundImage];
    
    if (self.isMe)
    {
        [self addFriendsButton];
    }
    else if ( self.profile == nil && self.remoteId != nil )
    {
        [self loadUserWithRemoteId:self.remoteId];
    }
    else if (!self.isMe && !self.profile.isDirectMessagingDisabled.boolValue)
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"profileCompose"]
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(composeMessage:)];
    }
    
    UIColor *backgroundColor = [self.dependencyManager colorForKey:VDependencyManagerBackgroundColorKey];
    self.view.backgroundColor = backgroundColor;
    
    if ( self.streamDataSource.count != 0 )
    {
        [self shrinkHeaderAnimated:YES];
    }
    
    //If we came from the inbox we can get into a loop with the compose button, so hide it
    BOOL fromInbox = NO;
    for (UIViewController *vc in self.navigationController.viewControllers)
    {
        if ([vc isKindOfClass:[VInboxViewController class]])
        {
            fromInbox = YES;
        }
    }
    if (fromInbox)
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    self.didEndViewWillAppear = YES;
    [self attemptToRefreshProfileUI];
}

- (void)loadBackgroundImage
{
    UIImage *placeholderImage = self.backgroundImageView.image;
    if ( placeholderImage == nil )
    {
        placeholderImage = [[UIImage resizeableImageWithColor:[self.dependencyManager colorForKey:VDependencyManagerBackgroundColorKey]] applyLightEffect];
    }
    
    if ( self.backgroundImageView == nil )
    {
        self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.profileHeaderView insertSubview:self.backgroundImageView atIndex:0];
    }
    
    NSURL *pictureURL = [NSURL URLWithString:self.profile.pictureUrl];
    if ( ![self.backgroundImageView.sd_imageURL isEqual:pictureURL] )
    {
        [self.backgroundImageView setBlurredImageWithURL:pictureURL
                                        placeholderImage:placeholderImage
                                               tintColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
    }
}

- (void)loadUserWithRemoteId:(NSNumber *)remoteId
{
    self.remoteId = remoteId;
    if ( self.retryHUD == nil )
    {
        self.retryHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.defaultMBProgressHUDMargin = self.retryHUD.margin;
    }
    else
    {
        self.retryHUD.margin = self.defaultMBProgressHUDMargin;
        self.retryHUD.mode = MBProgressHUDModeIndeterminate;
    }

    [[VObjectManager sharedManager] fetchUser:self.remoteId
                             withSuccessBlock:^(NSOperation *operation, id result, NSArray *resultObjects)
     {
         [self.retryHUD hide:YES];
         [self.retryProfileLoadButton removeFromSuperview];
         self.retryHUD = nil;
         self.profile = [resultObjects lastObject];
     }
                                    failBlock:^(NSOperation *operation, NSError *error)
     {
         //Handle profile load failure by changing navigationItem title and showing a retry button in the indicator
         self.navigationItem.title = NSLocalizedString(@"Profile load failed!", @"");
         self.retryHUD.mode = MBProgressHUDModeCustomView;
         self.retryHUD.customView = self.retryProfileLoadButton;
         self.retryHUD.margin = 0.0f;
         [self.retryProfileLoadButton setUserInteractionEnabled:YES];
     }];
}

- (void)retryProfileLoad
{
    //Disable user interaction to avoid spamming
    [self.retryProfileLoadButton setUserInteractionEnabled:NO];
    [self loadUserWithRemoteId:self.remoteId];
}

- (UIButton *)retryProfileLoadButton
{
    if ( _retryProfileLoadButton != nil )
    {
        return _retryProfileLoadButton;
    }
    
    /*
     To make a full-HUD button, it needs to have origin (-margin, -margin) and size (margin * 2 + MBProgressHUDCustomViewSide, margin * 2 + MBProgressHUDCustomViewSide).
    */
    CGFloat margin = self.defaultMBProgressHUDMargin;
    CGFloat buttonSide = margin * 2 + MBProgressHUDCustomViewSide;
    _retryProfileLoadButton = [[UIButton alloc] initWithFrame:CGRectMake(-margin, -margin, buttonSide, buttonSide)];
    [_retryProfileLoadButton addTarget:self action:@selector(retryProfileLoad) forControlEvents:UIControlEventTouchUpInside];
    _retryProfileLoadButton.tintColor = [UIColor whiteColor];
    [_retryProfileLoadButton setImage:[[UIImage imageNamed:@"uploadRetryButton"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    return _retryProfileLoadButton;
}

- (VUserProfileHeaderView *)profileHeaderView
{
    if ( _profileHeaderView != nil )
    {
        return _profileHeaderView;
    }
    
    _profileHeaderView =  [VUserProfileHeaderView newView];
    _profileHeaderView.user = self.profile;
    _profileHeaderView.delegate = self;
    _profileHeaderView.dependencyManager = self.dependencyManager;
    return _profileHeaderView;
}

- (void)viewDidLayoutSubviews
{
    CGFloat height = CGRectGetHeight(self.view.bounds) - self.topLayoutGuide.length;
    height = self.streamDataSource.count ? kVSmallUserHeaderHeight : height;
    
    CGFloat width = CGRectGetWidth(self.collectionView.bounds);
    CGSize newProfileSize = CGSizeMake(width, height);

    if ( !CGSizeEqualToSize(newProfileSize, self.currentProfileSize) )
    {
        self.currentProfileSize = newProfileSize;
    }
}

- (void)dealloc
{
    if (self.currentStream != nil)
    {
        [self.KVOController unobserve:self.currentStream keyPath:@"sequences"];
    }
    

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLoggedInChangedNotification object:nil];
    if (self.profile != nil)
    {
        [self stopObservingUserProfile];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[VTrackingManager sharedInstance] setValue:VTrackingValueUserProfile forSessionParameterWithKey:VTrackingKeyContext];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[VTrackingManager sharedInstance] setValue:nil forSessionParameterWithKey:VTrackingKeyContext];
}

#pragma mark - Find Friends

- (void)addFriendsButton
{
    //Previously was C_findFriendsIcon in template C
    UIImage *findFriendsIcon = [self.dependencyManager imageForKey:kFindFriendsIconKey];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:findFriendsIcon
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(findFriendsAction:)];
}

- (IBAction)findFriendsAction:(id)sender
{
    [[VTrackingManager sharedInstance] trackEvent:VTrackingEventUserDidSelectFindFriends];
    
    VAuthorizedAction *authorization = [[VAuthorizedAction alloc] initWithObjectManager:[VObjectManager sharedManager]
                                                                dependencyManager:self.dependencyManager];
    [authorization performFromViewController:self context:VAuthorizationContextInbox completion:^(BOOL authorized)
     {
         if (!authorized)
         {
             return;
         }
         VFindFriendsViewController *ffvc = [VFindFriendsViewController newWithDependencyManager:self.dependencyManager];
         [ffvc setShouldAutoselectNewFriends:NO];
         [self.navigationController pushViewController:ffvc animated:YES];
     }];
}

#pragma mark - Accessors

- (NSString *)viewName
{
    return @"Profile";
}

- (void)setProfile:(VUser *)profile
{
    NSAssert(self.dependencyManager != nil, @"dependencyManager should not be nil in VUserProfileViewController when the profile is set");
    
    if (profile == _profile)
    {
        return;
    }
    
    [self stopObservingUserProfile];
    
    _profile = profile;

    self.isMe = ([VObjectManager sharedManager].mainUser != nil && self.profile != nil && self.profile.remoteId.integerValue == [VObjectManager sharedManager].mainUser.remoteId.integerValue);
    NSString *profileName = profile.name ?: @"Profile";
    
    self.title = self.isMe ? NSLocalizedString(@"me", "") : profileName;
    
    [self.KVOController observe:_profile keyPath:NSStringFromSelector(@selector(name)) options:NSKeyValueObservingOptionNew context:VUserProfileAttributesContext];
    [self.KVOController observe:_profile keyPath:NSStringFromSelector(@selector(location)) options:NSKeyValueObservingOptionNew context:VUserProfileAttributesContext];
    [self.KVOController observe:_profile keyPath:NSStringFromSelector(@selector(tagline)) options:NSKeyValueObservingOptionNew context:VUserProfileAttributesContext];
    [self.KVOController observe:_profile keyPath:NSStringFromSelector(@selector(pictureUrl)) options:NSKeyValueObservingOptionNew context:VUserProfileAttributesContext];
    
    self.currentStream = [VStream streamForUser:self.profile];
    
    //Update title AFTER updating current stream as that update resets the title to nil (because there is nil name in the stream)
    self.navigationItem.title = profileName;

    [self attemptToRefreshProfileUI];
}

- (void)attemptToRefreshProfileUI
{
    //Ensuring viewWillAppear has finished and we have a valid profile ensures smooth profile and stream presentation by avoiding unnecessary refreshes even when loading from a remoteId
    if ( self.didEndViewWillAppear && self.profile != nil )
    {
        CGFloat height = CGRectGetHeight(self.view.bounds) - self.topLayoutGuide.length;
        height = self.streamDataSource.count ? kVSmallUserHeaderHeight : height;
        
        CGFloat width = CGRectGetWidth(self.view.bounds);
        self.currentProfileSize = CGSizeMake(width, height);
        
        self.profileHeaderView.user = self.profile;
        
        if ( self.streamDataSource.count == 0 )
        {
            [self refresh:nil];
        }
        else
        {
            [self shrinkHeaderAnimated:YES];
            [self.collectionView reloadData];
        }
    }
}

#pragma mark - Support

- (void)stopObservingUserProfile
{
    [self.KVOController unobserve:_profile keyPath:NSStringFromSelector(@selector(name))];
    [self.KVOController unobserve:_profile keyPath:NSStringFromSelector(@selector(location))];
    [self.KVOController unobserve:_profile keyPath:NSStringFromSelector(@selector(tagline))];
    [self.KVOController unobserve:_profile keyPath:NSStringFromSelector(@selector(pictureUrl))];
}

- (void)loginStateDidChange:(NSNotification *)notification
{
    if ([VObjectManager sharedManager].mainUser)
    {
        [[VObjectManager sharedManager] isUser:[VObjectManager sharedManager].mainUser
                                     following:self.profile
                                  successBlock:^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
         {
             VUserProfileHeaderView *header = self.profileHeaderView;
             header.isFollowingUser = [resultObjects[0] boolValue];
             header.user = header.user;
         }
                                     failBlock:nil];
    }
}

#pragma mark - Actions

- (void)refreshWithCompletion:(void (^)(void))completionBlock
{
    if (self.collectionView.dataSource == self.notLoggedInDataSource)
    {
        if (completionBlock)
        {
            completionBlock();
        }
        return;
    }
    else
    {
        if ( self.profile != nil )
        {
            void (^fullCompletionBlock)(void) = ^void(void)
            {
                if (self.streamDataSource.count)
                {
                    [self shrinkHeaderAnimated:YES];
                }
                if (completionBlock)
                {
                    completionBlock();
                }
            };
            [super refreshWithCompletion:fullCompletionBlock];
        }
    }
}

- (IBAction)composeMessage:(id)sender
{
    VAuthorizedAction *authorization = [[VAuthorizedAction alloc] initWithObjectManager:[VObjectManager sharedManager]
                                                                dependencyManager:self.dependencyManager];
    [authorization performFromViewController:self context:VAuthorizationContextInbox completion:^(BOOL authorized)
     {
         if (!authorized)
         {
             return;
         }
         
         VMessageContainerViewController *composeController = [VMessageContainerViewController messageViewControllerForUser:self.profile dependencyManager:self.dependencyManager];
         composeController.presentingFromProfile = YES;
         
         if ([self.navigationController.viewControllers containsObject:composeController])
         {
             [self.navigationController popToViewController:composeController animated:YES];
         }
         else
         {
             [self.navigationController pushViewController:composeController animated:YES];
         }
     }];
}

- (void)editProfileHandler
{
    [[VTrackingManager sharedInstance] trackEvent:VTrackingEventUserDidSelectEditProfile];
    
    VAuthorizationContext context = self.isMe ? VAuthorizationContextDefault : VAuthorizationContextFollowUser;
    VAuthorizedAction *authorization = [[VAuthorizedAction alloc] initWithObjectManager:[VObjectManager sharedManager]
                                                                dependencyManager:self.dependencyManager];
    [authorization performFromViewController:self context:context completion:^(BOOL authorized)
     {
         if ( !authorized )
         {
             return;
         }
         
         if ( self.isMe )
         {
             [self performSegueWithIdentifier:@"toEditProfile" sender:self];
         }
         else
         {
             [self toggleFollowUser];
         }
     }];
}

- (void)toggleFollowUser
{
    VUserProfileHeaderView *header = self.profileHeaderView;
    header.editProfileButton.enabled = NO;
    
    [self.profileHeaderView.editProfileButton showActivityIndicator];
    
    VFailBlock fail = ^(NSOperation *operation, NSError *error)
    {
        header.editProfileButton.enabled = YES;
        [header.editProfileButton hideActivityIndicator];
        
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"UnfollowError", @"")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", @"")
                          otherButtonTitles:nil] show];
    };
    
    if ( header.isFollowingUser )
    {
        [[VObjectManager sharedManager] unfollowUser:self.profile
                                        successBlock:^(NSOperation *operation, id result, NSArray *resultObjects)
         {
             header.editProfileButton.enabled = YES;
             header.isFollowingUser = NO;
         }
                                           failBlock:fail];
    }
    else
    {
        [[VObjectManager sharedManager] followUser:self.profile
                                      successBlock:^(NSOperation *operation, id result, NSArray *resultObjects)
         {
             header.editProfileButton.enabled = YES;
             header.isFollowingUser = YES;
         }
                                         failBlock:fail];
    }
}

#pragma mark - Navigation

- (void)followerHandler
{
    [self performSegueWithIdentifier:@"toFollowers" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
    if ( [segue.destinationViewController respondsToSelector:@selector(setDependencyManager:)] )
    {
        [segue.destinationViewController setDependencyManager:self.dependencyManager];
    }
}

- (void)followingHandler
{
    if (self.isMe)
    {
        [self performSegueWithIdentifier:@"toHashtagsAndFollowing" sender:self];
    }
    else
    {
        [self performSegueWithIdentifier:@"toFollowing" sender:self];
    }
}

#pragma mark - Animation

- (void)shrinkHeaderAnimated:(BOOL)animated
{
    if ( !animated )
    {
        self.currentProfileSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), kVSmallUserHeaderHeight);
        [self.currentProfileCell invalidateIntrinsicContentSize];
    }
    else
    {
        self.currentProfileSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), kVSmallUserHeaderHeight);
        CGRect newFrame = self.currentProfileCell.frame;
        newFrame.size.height = self.currentProfileSize.height;
        [UIView animateWithDuration:0.4f
                              delay:0.0f
             usingSpringWithDamping:0.95f
              initialSpringVelocity:0.0f
                            options:UIViewAnimationOptionCurveLinear
                         animations:^
         {
             [self.currentProfileCell setFrame:newFrame];
             [self.currentProfileCell layoutIfNeeded];
         }
                         completion:nil];
    }
}

#pragma mark - VStreamCollectionDataDelegate

- (UICollectionViewCell *)dataSource:(VStreamCollectionViewDataSource *)dataSource cellForIndexPath:(NSIndexPath *)indexPath
{
    if (self.streamDataSource.hasHeaderCell && indexPath.section == 0)
    {
        if ( self.currentProfileCell == nil )
        {
            VProfileHeaderCell *headerCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([VProfileHeaderCell class]) forIndexPath:indexPath];
            headerCell.headerView = self.profileHeaderView;
            self.currentProfileCell = headerCell;
        }
        self.currentProfileCell.hidden = self.profile == nil;
        return self.currentProfileCell;
    }
    VBaseCollectionViewCell *cell = (VBaseCollectionViewCell *)[super dataSource:dataSource cellForIndexPath:indexPath];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.collectionView.dataSource == self.notLoggedInDataSource)
    {
        return [VNotAuthorizedProfileCollectionViewCell desiredSizeWithCollectionViewBounds:collectionView.bounds];
    }
    if (self.streamDataSource.hasHeaderCell && indexPath.section == 0)
    {
        return self.currentProfileSize;
    }
    return [super collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{    
    if (self.streamDataSource.hasHeaderCell && indexPath.section == 0)
    {
        return;
    }
    [super collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

- (void)updateCollectionViewDataSource
{
    if (![[VObjectManager sharedManager] mainUserLoggedIn] && self.representsMainUser)
    {
        self.notLoggedInDataSource = [[VNotAuthorizedDataSource alloc] initWithCollectionView:self.collectionView dependencyManager:self.dependencyManager];
        self.notLoggedInDataSource.delegate = self;
        self.collectionView.dataSource = self.notLoggedInDataSource;
        [self.backgroundImageView setBlurredImageWithClearImage:[UIImage imageNamed:@"Default"]
                                               placeholderImage:nil
                                                      tintColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5f]];
        [self.refreshControl removeFromSuperview];
    }
    else
    {
        self.collectionView.dataSource = self.streamDataSource;
        [self.collectionView addSubview:self.refreshControl];
    }
}

#pragma mark - Notification

- (void)loginStatusChanged:(NSNotification *)notification
{
    if (self.representsMainUser)
    {
        self.profile = [VObjectManager sharedManager].mainUser;
        [self updateCollectionViewDataSource];
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == VUserProfileAttributesContext)
    {
        [self.collectionView reloadData];
        return;
    }
    
    if (context != VUserProfileViewContext)
    {
        return;
    }
    
    if (object == self.currentStream && [keyPath isEqualToString:NSStringFromSelector(@selector(streamItems))])
    {
        if ( self.streamDataSource.count != 0 )
        {
            [self shrinkHeaderAnimated:YES];
        }
    }
    
    [self.currentStream removeObserver:self
                            forKeyPath:NSStringFromSelector(@selector(streamItems))];
}

- (void)setDependencyManager:(VDependencyManager *)dependencyManager
{
    [super setDependencyManager:dependencyManager];
    self.profileHeaderView.dependencyManager = dependencyManager;
}

#pragma mark - VAbstractStreamCollectionViewController

- (void)refresh:(UIRefreshControl *)sender
{
    if (self.collectionView.dataSource == self.notLoggedInDataSource)
    {
        return;
    }
    else
    {
        [super refresh:sender];
    }
}

#pragma mark - VNotAuthorizedDataSourceDelegate

- (void)dataSourceWantsAuthorization:(VNotAuthorizedDataSource *)dataSource
{
    VLoginViewController *viewController = [VLoginViewController newWithDependencyManager:self.dependencyManager];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    viewController.transitionDelegate = [[VTransitionDelegate alloc] initWithTransition:[[VPresentWithBlurTransition alloc] init]];
    [self presentViewController:navigationController animated:YES completion:nil];
}

@end

#pragma mark -

@implementation VDependencyManager (VUserProfileViewControllerAdditions)

- (VUserProfileViewController *)userProfileViewControllerWithUser:(VUser *)user
{
    NSAssert(user != nil, @"user cannot be nil");
    return [self templateValueOfType:[VUserProfileViewController class] forKey:kUserProfileViewComponentKey withAddedDependencies:@{ kUserKey: user }];
}

- (VUserProfileViewController *)userProfileViewControllerWithRemoteId:(NSNumber *)remoteId
{
    NSAssert(remoteId != nil, @"remoteId cannot be nil");
    return [self templateValueOfType:[VUserProfileViewController class] forKey:kUserProfileViewComponentKey withAddedDependencies:@{ kUserRemoteIdKey: remoteId }];
}

@end
