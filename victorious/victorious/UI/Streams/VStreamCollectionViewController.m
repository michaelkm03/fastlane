//
//  VStreamCollectionViewController.m
//  victorious
//
//  Created by Will Long on 10/6/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VScaffoldViewController.h"
#import "VStreamCollectionViewController.h"
#import "VStreamCollectionViewDataSource.h"
#import "VStreamCollectionCell.h"
#import "VStreamCollectionCellPoll.h"
#import "VMarqueeCollectionCell.h"
#import "VStreamCollectionCellWebContent.h"

#warning Temporary
#import "VRootViewController.h"

//Controllers
#import "VCommentsContainerViewController.h"
#import "VUserProfileViewController.h"
#import "VMarqueeController.h"
#import "VAuthorizationViewControllerFactory.h"
#import "VSequenceActionController.h"
#import "VWebBrowserViewController.h"
#import "VNewContentViewController.h"

//Views
#import "VNavigationHeaderView.h"
#import "VNoContentView.h"
#import "MBProgressHUD.h"

//Data models
#import "VStream+Fetcher.h"
#import "VSequence+Fetcher.h"
#import "VNode+Fetcher.h"
#import "VUser.h"
#import "VHashtag.h"

//Managers
#import "VDependencyManager+VObjectManager.h"
#import "VObjectManager+Sequence.h"
#import "VObjectManager+Login.h"
#import "VObjectManager+Discover.h"
#import "VThemeManager.h"
#import "VSettingManager.h"

//Categories
#import "NSArray+VMap.h"
#import "UIImage+ImageCreation.h"
#import "UIImageView+Blurring.h"
#import "UIStoryboard+VMainStoryboard.h"
#import "UIViewController+VNavMenu.h"

#import "VConstants.h"
#import "VTracking.h"

static NSString * const kStreamsKey = @"streams";
static NSString * const kInitialKey = @"initial";
static NSString * const kMarqueeKey = @"marquee";
static NSString * const kStreamURLPathKey = @"streamUrlPath";
static NSString * const kTitleKey = @"title";
static NSString * const kIsHomeKey = @"isHome";
static NSString * const kCanAddContentKey = @"canAddContent";
static NSString * const kStreamCollectionStoryboardId = @"StreamCollection";
static CGFloat const kTemplateCLineSpacing = 8;

@interface VStreamCollectionViewController () <VNavigationHeaderDelegate, VMarqueeDelegate, VSequenceActionsDelegate, VUploadProgressViewControllerDelegate, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) VStreamCollectionViewDataSource *directoryDataSource;
@property (strong, nonatomic) NSIndexPath *lastSelectedIndexPath;
@property (strong, nonatomic) NSCache *preloadImageCache;
@property (strong, nonatomic) VMarqueeController *marquee;

@property (strong, nonatomic) VSequenceActionController *sequenceActionController;

@property (nonatomic, assign) BOOL hasRefreshed;
@property (nonatomic, assign) BOOL isSubscribedToHashtag;
@property (nonatomic, strong) NSString *selectedHashtag;
@property (nonatomic, weak) MBProgressHUD *failureHUD;

@end

@implementation VStreamCollectionViewController

#pragma mark - Factory methods

+ (instancetype)hashtagStreamWithHashtag:(NSString *)hashtag
{
    // Check if hashtag is being followed or not
    NSString *tagTitle = [@"#" stringByAppendingString:hashtag];
    NSString *tagString = [hashtag lowercaseString];

    VStream *defaultStream = [VStream streamForHashTag:tagString];
    VStreamCollectionViewController *streamVC = [self streamViewControllerForDefaultStream:defaultStream
                                                                             andAllStreams:@[ defaultStream ]
                                                                                     title:tagTitle];
    
    streamVC.selectedHashtag = hashtag;
    streamVC.dependencyManager = [[VRootViewController rootViewController] dependencyManager];
    
    return streamVC;
}

+ (instancetype)streamViewControllerForDefaultStream:(VStream *)stream andAllStreams:(NSArray *)allStreams title:(NSString *)title
{
    VStreamCollectionViewController *streamCollection = [self streamViewControllerForStream:stream];
    
    streamCollection.allStreams = allStreams;
    
    NSMutableArray *titles = [[NSMutableArray alloc] initWithCapacity:allStreams.count];
    for (VStream *stream in allStreams)
    {
        [titles addObject:stream.name];
    }
    
    streamCollection.title = title;
    [streamCollection v_addNewNavHeaderWithTitles:titles];
    streamCollection.navHeaderView.delegate = streamCollection;
    NSInteger selectedStream = [allStreams indexOfObject:stream];
    streamCollection.navHeaderView.navSelector.currentIndex = selectedStream;
    streamCollection.dependencyManager = [[VRootViewController rootViewController] dependencyManager];
    
    return streamCollection;
}

+ (instancetype)streamViewControllerForStream:(VStream *)stream
{
    VStreamCollectionViewController *streamCollection = (VStreamCollectionViewController *)[[UIStoryboard v_mainStoryboard] instantiateViewControllerWithIdentifier:kStreamCollectionStoryboardId];
    
    streamCollection.defaultStream = stream;
    streamCollection.currentStream = stream;
    
    return streamCollection;
}

#pragma mark VHasManagedDependencies

+ (instancetype)newWithDependencyManager:(VDependencyManager *)dependencyManager
{
    NSAssert([NSThread isMainThread], @"This method must be called on the main thread");
    
    __block VStream *defaultStream = nil;
    NSArray *streamConfiguration = [dependencyManager arrayForKey:kStreamsKey];
    NSArray *allStreams = [streamConfiguration v_map:^(NSDictionary *streamConfig)
    {
        VStream *stream = [VStream streamForPath:streamConfig[kStreamURLPathKey] inContext:dependencyManager.objectManager.managedObjectStore.mainQueueManagedObjectContext];
        stream.name = streamConfig[kTitleKey];
        if ([streamConfig[kInitialKey] boolValue])
        {
            defaultStream = stream;
        }
        return stream;
    }];
    
    if (defaultStream == nil && allStreams.count > 0)
    {
        defaultStream = allStreams[0];
    }
    
    VStreamCollectionViewController *streamCollectionVC = [self streamViewControllerForDefaultStream:defaultStream andAllStreams:allStreams title:[dependencyManager stringForKey:kTitleKey]];
    
    if ( [[dependencyManager numberForKey:kIsHomeKey] boolValue] )
    {
        [streamCollectionVC v_addUploadProgressView];
        streamCollectionVC.uploadProgressViewController.delegate = streamCollectionVC;
        streamCollectionVC.navHeaderView.showHeaderLogoImage = YES;
    }
    
    if ( [[dependencyManager numberForKey:@"experiments.marquee_enabled"] boolValue] )
    {
        streamCollectionVC.shouldDisplayMarquee = YES;
    }
    
    if ( [[dependencyManager numberForKey:kCanAddContentKey] boolValue] )
    {
        [streamCollectionVC v_addCreateSequenceButton];
    }
    
    NSNumber *cellVisibilityRatio = [dependencyManager numberForKey:@"experiments.stream_atf_view_threshold"];
    if ( cellVisibilityRatio != nil )
    {
        streamCollectionVC.trackingMinRequiredCellVisibilityRatio = cellVisibilityRatio.floatValue;
    }
    
    streamCollectionVC.dependencyManager = dependencyManager;

    return streamCollectionVC;
}

#pragma mark - View Heirarchy

- (void)dealloc
{
    self.marquee = nil;
    self.streamDataSource.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.hasRefreshed = NO;
    self.sequenceActionController = [[VSequenceActionController alloc] init];
    
    [self.collectionView registerNib:[VMarqueeCollectionCell nibForCell]
          forCellWithReuseIdentifier:[VMarqueeCollectionCell suggestedReuseIdentifier]];
    [self.collectionView registerNib:[VStreamCollectionCell nibForCell]
          forCellWithReuseIdentifier:[VStreamCollectionCell suggestedReuseIdentifier]];
    [self.collectionView registerNib:[VStreamCollectionCellPoll nibForCell]
          forCellWithReuseIdentifier:[VStreamCollectionCellPoll suggestedReuseIdentifier]];
    [self.collectionView registerNib:[VStreamCollectionCellWebContent nibForCell]
          forCellWithReuseIdentifier:[VStreamCollectionCellWebContent suggestedReuseIdentifier]];
    
    self.collectionView.backgroundColor = [[VThemeManager sharedThemeManager] preferredBackgroundColor];
    
    self.streamDataSource = [[VStreamCollectionViewDataSource alloc] initWithStream:self.currentStream];
    self.streamDataSource.delegate = self;
    self.streamDataSource.collectionView = self.collectionView;
    self.collectionView.dataSource = self.streamDataSource;
    
    
    // Fetch Users Hashtags
   [self fetchHashtagsForLoggedInUser];
    
    // Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataSourceDidChange:)
                                                 name:VStreamCollectionDataSourceDidChangeNotification
                                               object:self.streamDataSource];
    

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSString *streamName = self.currentStream.name;
    if ( streamName != nil )
    {
        NSDictionary *params = @{ VTrackingKeyStreamName : self.currentStream.name };
        [[VTrackingManager sharedInstance] startEvent:VTrackingEventStreamDidAppear parameters:params];
    }

    [self.navHeaderView updateUIForVC:self];//Update the header view in case the nav stack has changed.
    
    if (!self.streamDataSource.count)
    {
        [self refresh:self.refreshControl];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.collectionView flashScrollIndicators];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    [self updateCellVisibilityTracking];
    
    [self updateCurrentlyPlayingMediaAsset];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[VTrackingManager sharedInstance] endEvent:VTrackingEventStreamDidAppear];
    
    [[VTrackingManager sharedInstance] clearQueuedEventsWithName:VTrackingEventSequenceDidAppearInStream];
    
    [self.preloadImageCache removeAllObjects];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    self.preloadImageCache = nil;
}

#pragma mark - Properties

- (VMarqueeController *)marquee
{
    if (!_marquee)
    {
        VStream *marquee = [VStream streamForMarqueeInContext:[VObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext];
        _marquee = [[VMarqueeController alloc] initWithStream:marquee];
        _marquee.delegate = self;
    }
    return _marquee;
}

- (NSCache *)preloadImageCache
{
    if (!_preloadImageCache)
    {
        self.preloadImageCache = [[NSCache alloc] init];
        self.preloadImageCache.countLimit = 20;
    }
    return _preloadImageCache;
}

- (void)setCurrentStream:(VStream *)currentStream
{
    if ([currentStream.apiPath isEqualToString:self.defaultStream.apiPath])
    {
        self.streamDataSource.hasHeaderCell =  self.shouldDisplayMarquee && self.marquee.streamDataSource.count;
    }
    else
    {
        self.streamDataSource.hasHeaderCell = NO;
    }
    
    [super setCurrentStream:currentStream];
}

- (void)setShouldDisplayMarquee:(BOOL)shouldDisplayMarquee
{
    _shouldDisplayMarquee = shouldDisplayMarquee;
    if (self.currentStream == self.defaultStream)
    {
        self.streamDataSource.hasHeaderCell = shouldDisplayMarquee;
    }
}

#pragma mark - Fetch Users Tags

- (void)fetchHashtagsForLoggedInUser
{
    VSuccessBlock successBlock = ^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
    {
        [self updateHashtagNavButton:resultObjects];
    };
    
    VFailBlock failureBlock = ^(NSOperation *operation, NSError *error)
    {
        VLog(@"%@\n%@", operation, error);
    };
    
    [[VObjectManager sharedManager] getHashtagsSubscribedToWithPageType:VPageTypeFirst
                                                           perPageLimit:1000
                                                           successBlock:successBlock
                                                              failBlock:failureBlock];
}

- (void)updateHashtagNavButton:(NSArray *)hashtags
{
    __block NSString *buttonImageName = @"streamFollowHashtag";
    __block BOOL subscribed = NO;
    
    VUser *mainUser = [[VObjectManager sharedManager] mainUser];
    NSMutableOrderedSet *tagSet = [mainUser.hashtags mutableCopy];
    
    [hashtags enumerateObjectsUsingBlock:^(VHashtag *hashtag, NSUInteger idx, BOOL *stop) {
        [tagSet addObject:hashtag];
        if ([hashtag.tag isEqualToString:self.selectedHashtag])
        {
            buttonImageName = @"followedHashtag";
            subscribed = YES;
        }
    }];
    
    mainUser.hashtags = tagSet;
    [mainUser.managedObjectContext save:nil];
    
    if (self.selectedHashtag)
    {
        UIImage *hashtagButtonImage = [[UIImage imageNamed:buttonImageName]  imageWithRenderingMode:UIImageRenderingModeAutomatic];
        
        [self.navHeaderView setRightButtonImage:hashtagButtonImage withAction:@selector(followUnfollowHashtagButtonAction:) onTarget:nil];
        self.isSubscribedToHashtag = subscribed;
    }
}

#pragma mark - VMarqueeDelegate

- (void)marqueeRefreshedContent:(VMarqueeController *)marquee
{
    self.streamDataSource.hasHeaderCell = self.marquee.streamDataSource.count;
}

- (void)marquee:(VMarqueeController *)marquee selectedItem:(VStreamItem *)streamItem atIndexPath:(NSIndexPath *)path previewImage:(UIImage *)image
{
    if ( [streamItem isKindOfClass:[VSequence class]] )
    {
        [self showContentViewForSequence:(VSequence *)streamItem withPreviewImage:image];
    }
}

- (void)marquee:(VMarqueeController *)marquee selectedUser:(VUser *)user atIndexPath:(NSIndexPath *)path
{
    //If this cell is from the profile we should disable going to the profile
    BOOL fromProfile = NO;
    for (UIViewController *vc in self.navigationController.viewControllers)
    {
        if ([vc isKindOfClass:[VUserProfileViewController class]])
        {
            fromProfile = YES;
        }
    }
    if (fromProfile)
    {
        return;
    }
    
    VUserProfileViewController *profileViewController = [VUserProfileViewController userProfileWithUser:user];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.section != [self.streamDataSource sectionIndexForContent] )
    {
        return;
    }
    
    self.lastSelectedIndexPath = indexPath;
    
    VSequence *sequence = (VSequence *)[self.streamDataSource itemAtIndexPath:indexPath];
    UIImageView *previewImageView = nil;
    UICollectionViewCell *cell = (VStreamCollectionCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:[VStreamCollectionCell class]])
    {
        previewImageView = ((VStreamCollectionCell *)cell).previewImageView;
    }
    else if ([cell isKindOfClass:[VMarqueeCollectionCell class]])
    {
        previewImageView = ((VMarqueeCollectionCell *)cell).currentPreviewImageView;
    }
    
    [self showContentViewForSequence:sequence withPreviewImage:previewImageView.image];
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.streamDataSource.hasHeaderCell && indexPath.section == 0)
    {
        return [VMarqueeCollectionCell desiredSizeWithCollectionViewBounds:self.view.bounds];
    }
    
    VSequence *sequence = (VSequence *)[self.streamDataSource itemAtIndexPath:indexPath];
    if ([(VSequence *)[self.currentStream.streamItems objectAtIndex:indexPath.row] isPoll]
        &&[[VSettingManager sharedManager] settingEnabledForKey:VSettingsTemplateCEnabled])
    {
        return [VStreamCollectionCellPoll actualSizeWithCollectionViewBounds:self.collectionView.bounds sequence:sequence];
    }
    else if ([(VSequence *)[self.currentStream.streamItems objectAtIndex:indexPath.row] isPoll])
    {
        return [VStreamCollectionCellPoll desiredSizeWithCollectionViewBounds:self.collectionView.bounds];
    }
    else if ([[VSettingManager sharedManager] settingEnabledForKey:VSettingsTemplateCEnabled])
    {
        return [VStreamCollectionCell actualSizeWithCollectionViewBounds:self.collectionView.bounds sequence:sequence];
    }
    return [VStreamCollectionCell desiredSizeWithCollectionViewBounds:self.collectionView.bounds];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return [[VSettingManager sharedManager] settingEnabledForKey:VSettingsTemplateCEnabled] ? kTemplateCLineSpacing : 0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    if (section == 0)
    {
        return self.contentInset;
    }
    return UIEdgeInsetsZero;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( [cell isKindOfClass:[VStreamCollectionCell class]] )
    {
        [((VStreamCollectionCell *)cell) pauseVideo];
    }
}

#pragma mark - Activity indivator footer

- (BOOL)shouldDisplayActivityViewFooterForCollectionView:(UICollectionView *)collectionView inSection:(NSInteger)section
{
    return [super shouldDisplayActivityViewFooterForCollectionView:collectionView inSection:section];
}

#pragma mark - VStreamCollectionDataDelegate

- (UICollectionViewCell *)dataSource:(VStreamCollectionViewDataSource *)dataSource cellForIndexPath:(NSIndexPath *)indexPath
{
    if (self.streamDataSource.hasHeaderCell && indexPath.section == 0)
    {
        VMarqueeCollectionCell *cell = [dataSource.collectionView dequeueReusableCellWithReuseIdentifier:[VMarqueeCollectionCell suggestedReuseIdentifier]
                                                                                            forIndexPath:indexPath];
        cell.marquee = self.marquee;
        CGSize desiredSize = [VMarqueeCollectionCell desiredSizeWithCollectionViewBounds:self.view.bounds];
        cell.bounds = CGRectMake(0, 0, desiredSize.width, desiredSize.height);
        [cell restartAutoScroll];
        return cell;
    }
    
    VSequence *sequence = (VSequence *)[self.currentStream.streamItems objectAtIndex:indexPath.row];
    VStreamCollectionCell *cell;
    
    if ([sequence isPoll])
    {
        cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:[VStreamCollectionCellPoll suggestedReuseIdentifier]
                                                              forIndexPath:indexPath];
    }
    else if ([sequence isPreviewWebContent])
    {
        NSString *identifier = [VStreamCollectionCellWebContent suggestedReuseIdentifier];
        VStreamCollectionCellWebContent *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier
                                                                                               forIndexPath:indexPath];
        cell.sequence = sequence;
        return cell;
    }
    else
    {
        cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:[VStreamCollectionCell suggestedReuseIdentifier]
                                                              forIndexPath:indexPath];
    }
    cell.delegate = self.actionDelegate ?: self;
    cell.sequence = sequence;
    
    [self preloadSequencesAfterIndexPath:indexPath forDataSource:dataSource];
    
    return cell;
}

- (void)preloadSequencesAfterIndexPath:(NSIndexPath *)indexPath forDataSource:(VStreamCollectionViewDataSource *)dataSource
{
    if ([dataSource count] > (NSUInteger)indexPath.row + 2u)
    {
        NSIndexPath *preloadPath = [NSIndexPath indexPathForRow:indexPath.row + 2 inSection:indexPath.section];
        VSequence *preloadSequence = (VSequence *)[dataSource itemAtIndexPath:preloadPath];
        
        for (NSURL *imageUrl in [preloadSequence initialImageURLs])
        {
            UIImageView *preloadView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
            [preloadView setImageWithURL:imageUrl];
            
            [self.preloadImageCache setObject:preloadView forKey:imageUrl.absoluteString];
        }
    }
}

#pragma mark - VNavigationHeaderDelegate

- (BOOL)navSelector:(UIView<VNavigationSelectorProtocol> *)navSelector changedToIndex:(NSInteger)index
{
    VStream *stream = self.allStreams[index];
    if ( stream.apiPath != nil
        && [stream.apiPath rangeOfString:VStreamFollowerStreamPath].location != NSNotFound
        && ![VObjectManager sharedManager].authorized)
    {
        [self presentViewController:[VAuthorizationViewControllerFactory requiredViewControllerWithObjectManager:[VObjectManager sharedManager]] animated:YES completion:NULL];
        return NO;
    }
    
    if (self.allStreams.count <= (NSUInteger)index)
    {
        return NO;
    }
    
    [[VTrackingManager sharedInstance] clearQueuedEventsWithName:VTrackingEventSequenceDidAppearInStream];
    
    self.currentStream = self.allStreams[index];
    
    //Only reload if we have no items, the filter is not loading, and we have a refresh control (if theres no refreshControl the view isn't done loading)
    if (!self.currentStream.streamItems.count && !self.streamDataSource.isFilterLoading && self.refreshControl)
    {
        [self refresh:self.refreshControl];
    }
    
    return YES;
}

#pragma mark - VUploadProgressViewControllerDelegate methods

- (void)uploadProgressViewController:(VUploadProgressViewController *)upvc isNowDisplayingThisManyUploads:(NSInteger)uploadCount
{
    if (uploadCount)
    {
        [self v_showUploads];
    }
    else
    {
        [self v_hideUploads];
    }
}

#pragma mark - VSequenceActionsDelegate

- (void)willCommentOnSequence:(VSequence *)sequenceObject fromView:(VStreamCollectionCell *)streamCollectionCell
{
    [self.sequenceActionController showCommentsFromViewController:self sequence:sequenceObject];
}

- (void)selectedUserOnSequence:(VSequence *)sequence fromView:(VStreamCollectionCell *)streamCollectionCell
{
    [self.sequenceActionController showPosterProfileFromViewController:self sequence:sequence];
}

- (void)willRemixSequence:(VSequence *)sequence fromView:(UIView *)view
{
#warning Hacktastic
    [self.sequenceActionController showRemixOnViewController:self
                                                withSequence:sequence
                                        andDependencyManager:[VRootViewController rootViewController].dependencyManager];
}

- (void)willShareSequence:(VSequence *)sequence fromView:(UIView *)view
{
    [self.sequenceActionController shareFromViewController:self sequence:sequence node:[sequence firstNode]];
}

- (BOOL)willRepostSequence:(VSequence *)sequence fromView:(UIView *)view
{
    return [self.sequenceActionController repostActionFromViewController:self node:[sequence firstNode]];
}

- (void)willFlagSequence:(VSequence *)sequence fromView:(UIView *)view
{
    [self.sequenceActionController flagSheetFromViewController:self sequence:sequence];
}

- (void)hashTag:(NSString *)hashtag tappedFromSequence:(VSequence *)sequence fromView:(UIView *)view
{
    // Error checking
    if ( hashtag == nil || !hashtag.length )
    {
        return;
    }
    
    // Prevent another stream view for the current tag from being pushed
    if ( self.currentStream.hashtag && self.currentStream.hashtag.length )
    {
        if ( [[self.currentStream.hashtag lowercaseString] isEqualToString:[hashtag lowercaseString]] )
        {
            return;
        }
    }
    
    // Instanitate and push to stack
    VStreamCollectionViewController *hashtagStream = [VStreamCollectionViewController hashtagStreamWithHashtag:hashtag];
    [self.navigationController pushViewController:hashtagStream animated:YES];
}

#pragma mark - Actions

- (void)setBackgroundImageWithURL:(NSURL *)url
{
    //Don't set the background image for template c
    if ([[VSettingManager sharedManager] settingEnabledForKey:VSettingsTemplateCEnabled])
    {
        return;
    }
    
    UIImageView *newBackgroundView = [[UIImageView alloc] initWithFrame:self.collectionView.backgroundView.frame];
    
    UIImage *placeholderImage = [UIImage resizeableImageWithColor:[[UIColor whiteColor] colorWithAlphaComponent:0.7f]];
    [newBackgroundView setBlurredImageWithURL:url
                             placeholderImage:placeholderImage
                                    tintColor:[[UIColor whiteColor] colorWithAlphaComponent:0.7f]];
    
    self.collectionView.backgroundView = newBackgroundView;
}

- (void)showContentViewForSequence:(VSequence *)sequence withPreviewImage:(UIImage *)previewImage
{
    NSDictionary *params = @{ VTrackingKeySequenceId : sequence.remoteId,
                              VTrackingKeyStreamId : self.currentStream.remoteId,
                              VTrackingKeyTimeStamp : [NSDate date],
                              VTrackingKeyUrls : sequence.tracking.cellClick };
    [[VTrackingManager sharedInstance] trackEvent:VTrackingEventSequenceSelected parameters:params];
    
    [[self.dependencyManager scaffoldViewController] showContentViewWithSequence:sequence commentId:nil placeHolderImage:previewImage];
}

#pragma mark - Hashtag Button Actions

- (void)followUnfollowHashtagButtonAction:(UIButton *)sender
{
    // Check if logged in before attempting to subscribe / unsubscribe
    if (![VObjectManager sharedManager].authorized)
    {
        [self presentViewController:[VAuthorizationViewControllerFactory requiredViewControllerWithObjectManager:[VObjectManager sharedManager]] animated:YES completion:NULL];
        return;
    }
    
    // Disable the sub/unsub button
    sender.userInteractionEnabled = NO;
    sender.alpha = 0.3f;

    if (self.isSubscribedToHashtag)
    {
        [self unfollowHashtagAction:sender];
    }
    else
    {
        [self followHashtagAction:sender];
    }
}

- (void)followHashtagAction:(UIButton *)sender
{
    VSuccessBlock successBlock = ^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
    {
        // Animate follow button
        self.isSubscribedToHashtag = YES;
        [self updateSubscribeStatusAnimated:YES button:sender];
    };
    
    VFailBlock failureBlock = ^(NSOperation *operation, NSError *error)
    {
        self.failureHUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        self.failureHUD.mode = MBProgressHUDModeText;
        self.failureHUD.detailsLabelText = NSLocalizedString(@"HashtagSubscribeError", @"");
        [self.failureHUD hide:YES afterDelay:3.0f];
        
        // Set button back to normal state
        sender.userInteractionEnabled = YES;
        sender.alpha = 1.0f;
    };
    
    // Backend Subscribe to Hashtag call
    [[VObjectManager sharedManager] subscribeToHashtag:self.selectedHashtag
                                          successBlock:successBlock
                                             failBlock:failureBlock];
}

- (void)unfollowHashtagAction:(UIButton *)sender
{
    VSuccessBlock successBlock = ^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
    {
        self.isSubscribedToHashtag = NO;
        [self updateSubscribeStatusAnimated:YES button:sender];
    };
    
    VFailBlock failureBlock = ^(NSOperation *operation, NSError *error)
    {
        self.failureHUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        self.failureHUD.mode = MBProgressHUDModeText;
        self.failureHUD.detailsLabelText = NSLocalizedString(@"HashtagUnsubscribeError", @"");
        [self.failureHUD hide:YES afterDelay:3.0f];
        
        // Set button back to normal state
        sender.userInteractionEnabled = YES;
        sender.alpha = 1.0f;
    };
    
    // Backend Unsubscribe to Hashtag call
    [[VObjectManager sharedManager] unsubscribeToHashtag:self.selectedHashtag
                                            successBlock:successBlock
                                               failBlock:failureBlock];
}

#pragma mark - Follow / Unfollow Hashtag Completion Method

- (void)updateSubscribeStatusAnimated:(BOOL)animated button:(UIButton *)sender
{
    NSString *buttonImageName = @"streamFollowHashtag";
    
    if (self.isSubscribedToHashtag)
    {
        buttonImageName = @"followedHashtag";
    }

    // Reset the hashtag button image
    UIImage *hashtagButtonImage = [[UIImage imageNamed:buttonImageName] imageWithRenderingMode:UIImageRenderingModeAutomatic];
    [self.navHeaderView setRightButtonImage:hashtagButtonImage withAction:nil onTarget:nil];
    
    
    // Set button back to normal state
    sender.userInteractionEnabled = YES;
    sender.alpha = 1.0f;

    // Fire NSNotification to signal change in the status of this hashtag
    [[NSNotificationCenter defaultCenter] postNotificationName:kHashtagStatusChangedNotification
                                                        object:nil];
}

#pragma mark - Notifications

- (void)dataSourceDidChange:(NSNotification *)notification
{
    self.hasRefreshed = YES;
    [self updateNoContentViewAnimated:YES];
}

- (void)updateNoContentViewAnimated:(BOOL)animated
{
    if (!self.noContentView)
    {
        return;
    }
    
    void (^noContentUpdates)(void);
    
    if (self.streamDataSource.stream.streamItems.count <= 0)
    {
        if (![self.collectionView.backgroundView isEqual:self.noContentView])
        {
            self.collectionView.backgroundView = self.noContentView;
        }
        
        self.refreshControl.layer.zPosition = self.collectionView.backgroundView.layer.zPosition + 1;
        
        noContentUpdates = ^void(void)
        {
            self.collectionView.backgroundView.alpha = (self.hasRefreshed && self.noContentView) ? 1.0f : 0.0f;
        };
    }
    else
    {
        noContentUpdates = ^void(void)
        {
            UIImage *newImage = [UIImage resizeableImageWithColor:[[VThemeManager sharedThemeManager] preferredBackgroundColor]];
            self.collectionView.backgroundView = [[UIImageView alloc] initWithImage:newImage];
        };
    }
    
    if (animated)
    {
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:noContentUpdates
                         completion:nil];
    }
    else
    {
        noContentUpdates();
    }
}

- (void)didEnterBackground:(NSNotification *)notification
{
    [[VTrackingManager sharedInstance] clearQueuedEventsWithName:VTrackingEventSequenceDidAppearInStream];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    
    [self updateCellVisibilityTracking];
    
    [self updateCurrentlyPlayingMediaAsset];
}

#pragma mark - Cell visibility

- (void)updateCellVisibilityTracking
{
    const CGRect streamVisibleRect = self.collectionView.bounds;
    
    NSArray *visibleCells = self.collectionView.visibleCells;
    [visibleCells enumerateObjectsUsingBlock:^(VStreamCollectionCell *cell, NSUInteger idx, BOOL *stop)
     {
         if ( ![cell isKindOfClass:[VStreamCollectionCell class]] )
         {
             return;
         }
         
         // Calculate visible ratio for the whole cell
         const CGRect intersection = CGRectIntersection( streamVisibleRect, cell.frame );
         const float visibleRatio = CGRectGetHeight( intersection ) / CGRectGetHeight( cell.frame );
         [self collectionViewCell:cell didUpdateCellVisibility:visibleRatio];
     }];
}

- (void)updateCurrentlyPlayingMediaAsset
{
    const CGRect streamVisibleRect = self.collectionView.bounds;
    
    // Was a video begins playing, all other visible cells will be paused
    __block BOOL didPlayVideo = NO;
    
    NSArray *visibleCells = self.collectionView.visibleCells;
    [visibleCells enumerateObjectsUsingBlock:^(VStreamCollectionCell *cell, NSUInteger idx, BOOL *stop)
     {
         if ( ![cell isKindOfClass:[VStreamCollectionCell class]] )
         {
             return;
         }
         
         if ( didPlayVideo )
         {
             [cell pauseVideo];
         }
         else
         {
             // Calculate visible ratio for just the media content of the cell
             const CGRect contentFrameInCell = CGRectMake( CGRectGetMinX(cell.mediaContentFrame) + CGRectGetMinX(cell.frame),
                                                          CGRectGetMinY(cell.mediaContentFrame) + CGRectGetMinY(cell.frame),
                                                          CGRectGetWidth(cell.mediaContentFrame),
                                                          CGRectGetHeight(cell.mediaContentFrame) );
             
             if ( CGRectGetHeight( contentFrameInCell ) > 0.0 )
             {
                 const CGRect contentIntersection = CGRectIntersection( streamVisibleRect, contentFrameInCell );
                 const float mediaContentVisibleRatio = CGRectGetHeight( contentIntersection ) / CGRectGetHeight( contentFrameInCell );
                 if ( mediaContentVisibleRatio >= 0.8f )
                 {
                     [cell playVideo];
                     didPlayVideo = YES;
                 }
                 else
                 {
                     [cell pauseVideo];
                 }
             }
         }
     }];
}

- (void)collectionViewCell:(VStreamCollectionCell *)cell didUpdateCellVisibility:(CGFloat)visibiltyRatio
{
    if ( visibiltyRatio >= self.trackingMinRequiredCellVisibilityRatio )
    {
        const VSequence *sequence = cell.sequence;
        if ( sequence != nil )
        {
            NSDictionary *params = @{ VTrackingKeySequenceId : sequence.remoteId,
                                      VTrackingKeyStreamId : self.currentStream.remoteId,
                                      VTrackingKeyTimeStamp : [NSDate date],
                                      VTrackingKeyUrls : sequence.tracking.cellView };
            [[VTrackingManager sharedInstance] queueEvent:VTrackingEventSequenceDidAppearInStream
                                               parameters:params
                                                  eventId:sequence.remoteId];
        }
    }
}

@end