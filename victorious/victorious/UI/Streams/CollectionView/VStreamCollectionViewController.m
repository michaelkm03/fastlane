//
//  VStreamCollectionViewController.m
//  victorious
//
//  Created by Will Long on 10/6/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VStreamCollectionViewController.h"

#import "VStreamCollectionViewDataSource.h"
#import "VStreamCollectionCell.h"
#import "VStreamCollectionCellPoll.h"
#import "VMarqueeCollectionCell.h"
#import "VStreamCollectionCellWebContent.h"

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

//Managers
#import "VDependencyManager+VObjectManager.h"
#import "VObjectManager+Sequence.h"
#import "VObjectManager+Login.h"
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

static NSString * const kInitialKey = @"initial";
static NSString * const kMarqueeKey = @"marquee";
static NSString * const kStreamURLPathKey = @"streamUrlPath";
static NSString * const kTitleKey = @"title";
static NSString * const kIsHomeKey = @"isHome";
static NSString * const kCanAddContentKey = @"canAddContent";
static NSString * const kStreamCollectionStoryboardId = @"kStreamCollection";
static CGFloat const kTemplateCLineSpacing = 8;

@interface VStreamCollectionViewController () <VNavigationHeaderDelegate, VNewContentViewControllerDelegate, VMarqueeDelegate, VSequenceActionsDelegate, VUploadProgressViewControllerDelegate>

@property (strong, nonatomic) VStreamCollectionViewDataSource *directoryDataSource;
@property (strong, nonatomic) NSIndexPath *lastSelectedIndexPath;
@property (strong, nonatomic) NSCache *preloadImageCache;
@property (strong, nonatomic) VMarqueeController *marquee;

@property (strong, nonatomic) VSequenceActionController *sequenceActionController;

@property (nonatomic, assign) BOOL hasRefreshed;

@end

@implementation VStreamCollectionViewController

#pragma mark - Factory methods

+ (instancetype)streamViewControllerForStream:(VStream *)stream
{
    VStreamCollectionViewController *streamCollection = (VStreamCollectionViewController *)[[UIStoryboard v_mainStoryboard] instantiateViewControllerWithIdentifier:kStreamCollectionStoryboardId];
    streamCollection.currentStream = stream;
    return streamCollection;
}

#pragma mark VHasManagedDependencies constructor

+ (instancetype)newWithDependencyManager:(VDependencyManager *)dependencyManager
{
    NSAssert([NSThread isMainThread], @"This method must be called on the main thread");
    
    VStream *stream = [VStream streamForPath:[dependencyManager stringForKey:kStreamURLPathKey] inContext:dependencyManager.objectManager.managedObjectStore.mainQueueManagedObjectContext];
    stream.name = [dependencyManager stringForKey:kTitleKey];
    
    VStreamCollectionViewController *streamCollectionVC = [self streamViewControllerForStream:stream];
    
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
    
    NSDictionary *params = @{ VTrackingKeyStreamName : self.currentStream.name };
    [[VTrackingManager sharedInstance] startEvent:VTrackingEventStreamDidAppear parameters:params];

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
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[VTrackingManager sharedInstance] endEvent:VTrackingEventStreamDidAppear];
    
    [[VTrackingManager sharedInstance] trackQueuedEventsWithName:VTrackingEventSequenceDidAppearInStream];
    
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
    self.streamDataSource.hasHeaderCell = NO;
    self.title = currentStream.name;
    [super setCurrentStream:currentStream];
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

- (void)showContentViewWithSequence:(VSequence *)sequence placeHolderImage:(UIImage *)placeHolderImage
{
    VContentViewViewModel *contentViewModel = [[VContentViewViewModel alloc] initWithSequence:sequence];
    VNewContentViewController *contentViewController = [VNewContentViewController contentViewControllerWithViewModel:contentViewModel];
    contentViewController.placeholderImage = placeHolderImage;
    contentViewController.delegate = self;
    
    UINavigationController *contentNav = [[UINavigationController alloc] initWithRootViewController:contentViewController];
    contentNav.navigationBarHidden = YES;
    [self presentViewController:contentNav animated:YES completion:nil];
}

- (void)showWebContentWithSequence:(VSequence *)sequence
{
    VWebBrowserViewController *viewController = [VWebBrowserViewController instantiateFromStoryboard];
    viewController.sequence = sequence;
    [self presentViewController:viewController
                       animated:YES
                     completion:nil];
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
    
    if ( sequence != nil )
    {
        NSDictionary *params = @{ VTrackingKeySequenceId : sequence.remoteId,
                                  VTrackingKeyStreamId : self.currentStream.remoteId,
                                  VTrackingKeyTimeStamp : [NSDate date],
                                  VTrackingKeyUrls : sequence.tracking.cellView };
        [[VTrackingManager sharedInstance] queueEvent:VTrackingEventSequenceDidAppearInStream parameters:params eventId:sequence.remoteId];
    }
    
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
    if ([sequence isVideo])
    {
        [self.sequenceActionController videoRemixActionFromViewController:self asset:[sequence firstNode].assets.firstObject node:[sequence firstNode] sequence:sequence];
    }
    else
    {
        NSIndexPath *path = [self.streamDataSource indexPathForItem:sequence];
        VStreamCollectionCell *cell = (VStreamCollectionCell *)[self.streamDataSource.delegate dataSource:self.streamDataSource cellForIndexPath:path];
        [self.sequenceActionController imageRemixActionFromViewController:self previewImage:cell.previewImageView.image sequence: sequence];
    }
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
    if ( !hashtag || !hashtag.length )
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
    
    // Instantiate and push to stack
    VStreamCollectionViewController *hashtagStream = [VStreamCollectionViewController streamViewControllerForStream:[VStream streamForHashTag:hashtag]];
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
    //Every time we go to the content view, update the sequence
    [[VObjectManager sharedManager] fetchSequenceByID:sequence.remoteId
                                         successBlock:nil
                                            failBlock:nil];
    
    NSDictionary *params = @{ VTrackingKeySequenceId : sequence.remoteId,
                              VTrackingKeyStreamId : self.currentStream.remoteId,
                              VTrackingKeyTimeStamp : [NSDate date],
                              VTrackingKeyUrls : sequence.tracking.cellClick };
    [[VTrackingManager sharedInstance] trackEvent:VTrackingEventSequenceSelected parameters:params];
    
    if ( [sequence isWebContent] )
    {
        [self showWebContentWithSequence:sequence];
    }
    else
    {
        [self showContentViewWithSequence:sequence placeHolderImage:previewImage];
    }
}

#pragma mark - VNewContentViewControllerDelegate

- (void)newContentViewControllerDidClose:(VNewContentViewController *)contentViewController
{
    if ( self.lastSelectedIndexPath != nil )
    {
        [self.collectionView reloadItemsAtIndexPaths:@[self.lastSelectedIndexPath]];
    }
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void)newContentViewControllerDidDeleteContent:(VNewContentViewController *)contentViewController
{
    [self refresh:self.refreshControl];
    [self dismissViewControllerAnimated:YES
                             completion:nil];
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
    [[VTrackingManager sharedInstance] trackQueuedEventsWithName:VTrackingEventSequenceDidAppearInStream];
}

@end
