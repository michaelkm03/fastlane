//
//  VDiscoverViewController.m
//  victorious
//
//  Created by Patrick Lynch on 10/3/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VDiscoverViewController.h"
#import "VDiscoverContainerViewController.h"
#import "VDiscoverSuggestedPeopleSectionCell.h"
#import "VStreamItem+Fetcher.h"
#import "VHashtagCell.h"
#import "VDiscoverHeaderView.h"
#import "VDiscoverSuggestedPeopleViewController.h"
#import "VHashtag.h"
#import "VStreamCollectionViewController.h"
#import "VNoContentTableViewCell.h"
#import "VDiscoverViewControllerProtocol.h"
#import "VUser.h"
#import "VConstants.h"
#import "VHashtagStreamCollectionViewController.h"
#import "VDependencyManager.h"
#import "VHasManagedDependencies.h"
#import <KVOController/FBKVOController.h>
#import "VDependencyManager+VCoachmarkManager.h"
#import "VCoachmarkManager.h"
#import "VCoachmarkDisplayer.h"
#import "UIViewController+VLayoutInsets.h"
#import "VDependencyManager+VTracking.h"
#import "VFollowControl.h"
#import "NSArray+VMap.h"
#import "victorious-Swift.h"

@import MBProgressHUD;

static NSString * const kVSuggestedPeopleIdentifier = @"VSuggestedPeopleCell";
static NSString * const kVTrendingTagIdentifier = @"VHashtagCell";
static NSString * const kVHeaderIdentifier = @"VDiscoverHeader";

@interface VDiscoverViewController () <VDiscoverViewControllerProtocol, VDiscoverSuggestedPeopleDelegate, VCoachmarkDisplayer>

@property (nonatomic, strong) VDiscoverSuggestedPeopleViewController *suggestedPeopleViewController;

@property (nonatomic, strong) NSArray<HashtagSearchResultObject *> *trendingTags;
@property (nonatomic, strong) NSArray *sectionHeaderTitles;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) BOOL loadedUserFollowing;

@property (nonatomic, assign) BOOL followingStatusHasChanged;
@property (nonatomic, assign) BOOL wasHiddenByAnotherViewController;

@property (nonatomic, weak) MBProgressHUD *failureHud;

@end

@implementation VDiscoverViewController

@synthesize dependencyManager = _dependencyManager; //< VDiscoverViewControllerProtocol

#pragma mark - View controller life cycle

- (void)loadView
{
    [super loadView];
    
    self.suggestedPeopleViewController = [VDiscoverSuggestedPeopleViewController instantiateFromStoryboard:@"Discover"];
    self.suggestedPeopleViewController.dependencyManager = self.dependencyManager;
    self.suggestedPeopleViewController.delegate = self;
    
    [self addChildViewController:self.suggestedPeopleViewController];
    [self.suggestedPeopleViewController didMoveToParentViewController:self];
    
    // Call this here to ensure that header views are ready by the time the tableview asks for them
    self.sectionHeaderTitles = @[NSLocalizedString( @"Suggested People", @"" ), NSLocalizedString( @"Trending Tags", @"" )];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self registerCells];
    [self refresh:YES];
    
    // Watch for a change in the login status
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewStatusChanged:)
                                                 name:kLoggedInChangedNotification
                                               object:nil];
    VUser *currentUser = [VCurrentUser user];
    
    [self.KVOController observe:currentUser
                        keyPath:NSStringFromSelector(@selector(followedHashtags))
                        options:NSKeyValueObservingOptionNew
                         action:@selector(updatedFollowedTags)];
    
    [self.KVOController observe:currentUser
                        keyPath:NSStringFromSelector(@selector(following))
                        options:NSKeyValueObservingOptionNew
                         action:@selector(updatedFollowedUsers)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.dependencyManager trackViewWillAppear:self withParameters:nil templateClass:[VDiscoverContainerViewController class]];
    
    if ( self.hasLoadedOnce )
    {
        // FIXME: Remove this line and use the original proper reload logic described below
        [self.tableView reloadData];
        
        // Only refresh suggested users if main user has followed someone since the last time they visited
        // and if we're navigating to this view controller from somewhere other than it's own navigation
        // controller or presented view controller
        if (self.followingStatusHasChanged && !self.wasHiddenByAnotherViewController)
        {
            [self.suggestedPeopleViewController refresh:YES];
            self.followingStatusHasChanged = NO;
        }
        else
        {
            [self.suggestedPeopleViewController refresh:NO];
        }
        [self reloadSection:VDiscoverViewControllerSectionTrendingTags];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[self.dependencyManager coachmarkManager] displayCoachmarkViewInViewController:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.dependencyManager trackViewWillDisappear:self];
    
    [[self.dependencyManager coachmarkManager] hideCoachmarkViewInViewController:self animated:animated];
    
    // Note if we're pushing another view controller onto the nav stack or if we're presenting
    // a modal view controller
    self.wasHiddenByAnotherViewController = (self.navigationController.viewControllers.count > 1 || self.presentedViewController);
    self.followingStatusHasChanged = NO;
}

- (void)setDependencyManager:(VDependencyManager *)dependencyManager
{
    _dependencyManager = dependencyManager;
    self.suggestedPeopleViewController.dependencyManager = dependencyManager;
    for ( UITableViewCell *cell in self.tableView.visibleCells )
    {
        if ( [cell respondsToSelector:@selector(setDependencyManager:)] )
        {
            [(id<VHasManagedDependencies>)cell setDependencyManager:dependencyManager];
        }
    }
}

- (void)dealloc
{
    // Kill the login notification
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Loading data

- (void)viewStatusChanged:(NSNotification *)notification
{
    [self refresh:YES];
}

- (void)hashtagsDidFailToLoadWithError:(NSError *)error
{
    self.hasLoadedOnce = YES;
    self.error = (error == nil) ? [[NSError alloc] init] : [error copy];
    self.trendingTags = @[];
    [self reloadSection:VDiscoverViewControllerSectionTrendingTags];
}

- (void)hashtagsDidLoad:(NSArray *)hashtags
{
    self.hasLoadedOnce = YES;
    self.error = nil;
    self.trendingTags = hashtags;
    
    // If logged in, load any tags already being followed
    if ( [VCurrentUser user] != nil )
    {
        [self updatedFollowedTags];
    }
    else
    {
        [self reloadSection:VDiscoverViewControllerSectionTrendingTags];
    }
}

- (void)refresh:(BOOL)shouldClearCurrentContent
{
    if ( shouldClearCurrentContent )
    {
        self.hasLoadedOnce = NO;
        self.trendingTags = @[];
        [self.tableView reloadData];
    }
    
    [self.suggestedPeopleViewController refresh:shouldClearCurrentContent];
    [self reload];
}

- (void)reload
{
    TrendingHashtagOperation *operation = [[TrendingHashtagOperation alloc] init];
    [operation queueOn:operation.defaultQueue completionBlock:^(NSError *_Nullable error)
    {
        if (error == nil)
        {
            NSArray *hashtags = operation.results;
            [self hashtagsDidLoad:hashtags];
        }
        else
        {
            [self hashtagsDidFailToLoadWithError:error];
        }
    }];
}

- (void)updatedFollowedTags
{
    self.loadedUserFollowing = YES;
    [self reloadSection:VDiscoverViewControllerSectionTrendingTags];
}

- (void)updatedFollowedUsers
{
    self.followingStatusHasChanged = YES;
}

#pragma mark - VDiscoverViewControllerProtocol

@synthesize hasLoadedOnce;

- (BOOL)isShowingNoData
{
    BOOL tagFollowStatesAreValid = [VCurrentUser user] == nil || self.loadedUserFollowing;
    return self.trendingTags.count == 0 || self.error != nil || !tagFollowStatesAreValid;
}

#pragma mark - UI setup

- (void)registerCells
{
    [self.tableView registerNib:[UINib nibWithNibName:kVTrendingTagIdentifier bundle:nil] forCellReuseIdentifier:kVTrendingTagIdentifier];
    [self.tableView registerClass:[VDiscoverSuggestedPeopleSectionCell class] forCellReuseIdentifier:kVSuggestedPeopleIdentifier];
    [self.tableView registerNib:[VDiscoverHeaderView nibForHeader] forHeaderFooterViewReuseIdentifier:kVHeaderIdentifier];
    
    [VNoContentTableViewCell registerNibWithTableView:self.tableView];
}

#pragma mark - VDiscoverSuggestedPeopleDelegate

- (void)suggestedPeopleDidFailToLoad
{
    [self reloadSection:VDiscoverViewControllerSectionSuggestedPeople];
}

- (void)suggestedPeopleDidFinishLoading
{
    [self reloadSection:VDiscoverViewControllerSectionSuggestedPeople];
}
     
- (void)reloadSection:(NSInteger)section
{
    [self.tableView reloadData];
}

- (UIViewController *)componentRootViewController
{
    return self;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return VDiscoverViewControllerSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ( section == VDiscoverViewControllerSectionSuggestedPeople )
    {
        // There's always one suggested people row which shows either the suggested people collection view or an no data cell cell
        return 1;
    }
    if ( section == VDiscoverViewControllerSectionTrendingTags )
    {
        return self.isShowingNoData ? 1 : self.trendingTags.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if ( indexPath.section == VDiscoverViewControllerSectionSuggestedPeople )
    {
        if ( self.suggestedPeopleViewController.isShowingNoData )
        {
            VNoContentTableViewCell *defaultCell = [VNoContentTableViewCell createCellFromTableView:tableView];
            if ( self.suggestedPeopleViewController.hasLoadedOnce )
            {
                // Only set the error message once something has been loaded, otherwise we see the error message before first load
                defaultCell.message = NSLocalizedString( @"DiscoverSuggestedPeopleError", @"");
            }
            else
            {
                defaultCell.isLoading = YES;
            }
            cell = defaultCell;
        }
        else
        {
            VDiscoverSuggestedPeopleSectionCell *customCell = (VDiscoverSuggestedPeopleSectionCell *) [tableView dequeueReusableCellWithIdentifier:kVSuggestedPeopleIdentifier forIndexPath:indexPath];
            
            if ( ![customCell.subviews containsObject:self.suggestedPeopleViewController.collectionView] )
            {
                [customCell addSubview:self.suggestedPeopleViewController.collectionView];
                self.suggestedPeopleViewController.collectionView.frame = customCell.bounds;
            }
            
            customCell.backgroundColor = [UIColor clearColor];
            cell = customCell;
            self.suggestedPeopleViewController.hasLoadedOnce = YES;
        }
    }
    else if ( indexPath.section == VDiscoverViewControllerSectionTrendingTags )
    {
        if ( self.isShowingNoData )
        {
            VNoContentTableViewCell *defaultCell = [VNoContentTableViewCell createCellFromTableView:tableView];
            if ( self.hasLoadedOnce )
            {
                // Only set the error message once something has been loaded, otherwise we see the error message before first load
                defaultCell.message = NSLocalizedString( @"DiscoverTrendingTagsError", @"");
            }
            else
            {
                defaultCell.isLoading = YES;
            }
            cell = defaultCell;
        }
        else
        {
            VHashtagCell *customCell = (VHashtagCell *)[tableView dequeueReusableCellWithIdentifier:kVTrendingTagIdentifier forIndexPath:indexPath];
            
            HashtagSearchResultObject *hashtag = self.trendingTags[ indexPath.row ];
            NSString *hashtagText = hashtag.tag;
            [customCell setHashtagText:hashtagText];
            [self updateFollowControl:customCell.followControl forHashtag:hashtagText];
            
            __weak VHashtagCell *weakCell = customCell;
            __weak VDiscoverViewController *weakSelf = self;
            customCell.followControl.onToggleFollow = ^(void)
            {
                __strong VHashtagCell *strongCell = weakCell;
                __strong VDiscoverViewController *strongSelf = weakSelf;
                if ( strongCell == nil || strongSelf == nil )
                {
                    return;
                }
                
                // Check if already subscribed to hashtag then subscribe or unsubscribe accordingly
                RequestOperation *operation;
                if ([[VCurrentUser user] isFollowingHashtagString:hashtagText] )
                {
                    operation = [[UnfollowHashtagOperation alloc] initWithHashtag:hashtagText];
                }
                else
                {
                    operation = [[FollowHashtagOperation alloc] initWithHashtag:hashtagText];
                }
                [operation queueOn:operation.defaultQueue completionBlock:^(NSError *_Nullable error) {
                    [strongSelf updateFollowControl:strongCell.followControl forHashtag:hashtagText];
                }];
            };
            
            customCell.dependencyManager = self.dependencyManager;
            cell = customCell;
        }
    }
    
    if ([cell respondsToSelector:@selector(setDependencyManager:)])
    {
        [(id <VHasManagedDependencies>)cell setDependencyManager:self.dependencyManager];
    }
    
    return cell;
}

- (void)updateFollowControl:(VFollowControl *)followControl forHashtag:(NSString *)hashtag
{
    VFollowControlState controlState;
    if ( [[VCurrentUser user] isFollowingHashtagString:hashtag] )
    {
        controlState = VFollowControlStateFollowed;
    }
    else
    {
        controlState = VFollowControlStateUnfollowed;
    }
    [followControl setControlState:controlState animated:YES];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ( section >= 0 && section < VDiscoverViewControllerSectionsCount )
    {
        return [VDiscoverHeaderView desiredHeight];
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    VDiscoverHeaderView *headerView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:kVHeaderIdentifier];
    headerView.title = [self.sectionHeaderTitles[section] uppercaseStringWithLocale:[NSLocale currentLocale]];
    headerView.dependencyManager = self.dependencyManager;
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == VDiscoverViewControllerSectionSuggestedPeople ? [VDiscoverSuggestedPeopleSectionCell cellHeight] : [VHashtagCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // No actions available for kTableViewSectionSuggestedPeople
    if ( indexPath.section == VDiscoverViewControllerSectionTrendingTags && self.isShowingNoData == NO )
    {
        HashtagSearchResultObject *hashtag = self.trendingTags[ indexPath.row ];
        // Tracking
        NSDictionary *params = @{ VTrackingKeyHashtag : hashtag.tag ?: @"" };
        [[VTrackingManager sharedInstance] trackEvent:VTrackingEventUserDidSelectTrendingHashtag parameters:params];
        
        // Show hashtag stream
        [self showStreamWithHashtag:hashtag];
    }
}

#pragma mark - Show Hashtag Stream

- (void)showStreamWithHashtag:(HashtagSearchResultObject *)hashtag
{
    VHashtagStreamCollectionViewController *vc = [self.dependencyManager hashtagStreamWithHashtag:hashtag.tag];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - VCoachmarkDisplayer

- (NSString *)screenIdentifier
{
    return [self.dependencyManager stringForKey:VDependencyManagerIDKey];
}

- (BOOL)selectorIsVisible
{
    return !self.navigationController.navigationBarHidden;
}

- (UIEdgeInsets)v_layoutInsets
{
    return [self.parentViewController v_layoutInsets];
}

#pragma mark - VTabMenuContainedViewControllerNavigation

- (void)reselected
{
    [self.tableView setContentOffset:CGPointZero animated:YES];
}

@end
