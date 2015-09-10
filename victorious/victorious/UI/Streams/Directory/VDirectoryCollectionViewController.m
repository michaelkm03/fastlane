//
//  VDirectoryCollectionViewController.m
//  victorious
//
//  Created by Sharif Ahmed on 3/24/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VDirectoryCollectionViewController.h"
#import "VDependencyManager+VObjectManager.h"
#import "VStream+Fetcher.h"
#import "NSString+VParseHelp.h"
#import "VObjectManager.h"
#import "VAbstractMarqueeController.h"
#import "VUserProfileViewController.h"
#import "VDirectoryCellFactory.h"
#import "VDirectoryCellUpdateableFactory.h"
#import "VStreamItem+Fetcher.h"
#import "VStreamItem.h"
#import "VDependencyManager+VTabScaffoldViewController.h"
#import "VTabScaffoldViewController.h"
#import "VStreamCollectionViewController.h"
#import "VURLMacroReplacement.h"
#import "VDirectoryCollectionFlowLayout.h"
#import "VDependencyManager+VUserProfile.h"
#import "VShowcaseDirectoryCell.h"
#import "VCoachmarkDisplayer.h"
#import "VCoachmarkManager.h"
#import "VDependencyManager+VCoachmarkManager.h"
#import "VDependencyManager+VNavigationItem.h"
#import "VDependencyManager+VTracking.h"
#import "VTracking.h"
#import "UIViewController+VAccessoryScreens.h"
#import "victorious-Swift.h"

static NSString * const kStreamURLKey = @"streamURL";
static NSString * const kMarqueeKey = @"marqueeCell";

static NSString * const kDestinationDirectoryKey = @"destinationDirectory";
static NSString * const kStreamCollectionKey = @"destinationStream";
static NSString * const kSequenceIDKey = @"sequenceID";
static NSString * const kSequenceNameKey = @"sequenceName";
static NSString * const kSequenceIDMacro = @"%%SEQUENCE_ID%%";

@interface VDirectoryCollectionViewController () <VMarqueeSelectionDelegate, VMarqueeDataDelegate, VDirectoryCollectionFlowLayoutDelegate, VCoachmarkDisplayer, VStreamContentCellFactoryDelegate>

@property (nonatomic, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong) NSObject <VDirectoryCellFactory> *directoryCellFactory;

/**
 *  The dependencyManager used to style the directory and its cells
 */
@property (nonatomic, strong) VDependencyManager *dependencyManager;

/**
 *  The marquee controller that will provide and manage marquee cells when a marquee is displayed
 */
@property (nonatomic, strong) VAbstractMarqueeController *marqueeController;

@end

@implementation VDirectoryCollectionViewController

@synthesize collectionView = _collectionView;

#pragma mark - Initializers

+ (instancetype)streamDirectoryForStream:(VStream *)stream dependencyManager:(VDependencyManager *)dependencyManager andDirectoryCellFactory:(NSObject <VDirectoryCellFactory> *)directoryCellFactory
{
    //Check that we have all necessary components to show a directory
    if ( directoryCellFactory == nil || dependencyManager == nil)
    {
        /*
         Return nil if the directory cell factory dependency manager are missing as they're both
         integral to being setup properly.
         */
        return nil;
    }
    
    VAbstractMarqueeController *marqueeController = [dependencyManager templateValueOfType:[VAbstractMarqueeController class] forKey:kMarqueeKey];
    if ( marqueeController == nil )
    {
        return nil;
    }
    
    VDirectoryCollectionViewController *streamDirectory = [[[self class] alloc] initWithNibName:nil bundle:nil];
    streamDirectory.currentStream = stream;
    streamDirectory.title = stream.name;
    streamDirectory.dependencyManager = dependencyManager;
    streamDirectory.directoryCellFactory = directoryCellFactory;
    if ( [directoryCellFactory isKindOfClass:[VStreamContentCellFactory class]] )
    {
        VStreamContentCellFactory *streamItemFactory = (VStreamContentCellFactory *)directoryCellFactory;
        streamItemFactory.delegate = streamDirectory;
    }
    
    VDirectoryCollectionFlowLayout *flowLayout = streamDirectory.directoryCellFactory.collectionViewFlowLayout;
    flowLayout.delegate = streamDirectory;
    UICollectionViewFlowLayout *layout = flowLayout ?: [[UICollectionViewFlowLayout alloc] init];
    streamDirectory.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    streamDirectory.marqueeController = marqueeController;
    streamDirectory.marqueeController.stream = stream;
    [streamDirectory.marqueeController registerCollectionViewCellWithCollectionView:streamDirectory.collectionView];
    streamDirectory.marqueeController.selectionDelegate = streamDirectory;
    streamDirectory.marqueeController.dataDelegate = streamDirectory;
    
    return streamDirectory;
}

#pragma mark - VHasManagedDependencies conforming initializer

+ (instancetype)newWithDependencyManager:(VDependencyManager *)dependencyManager
{
    NSAssert([NSThread isMainThread], @"This method must be called on the main thread");
    
    NSString *url = [dependencyManager stringForKey:kStreamURLKey];
    NSString *sequenceID = [dependencyManager stringForKey:kSequenceIDKey];
    if ( sequenceID != nil )
    {
        VURLMacroReplacement *urlMacroReplacement = [[VURLMacroReplacement alloc] init];
        url = [urlMacroReplacement urlByPartiallyReplacingMacrosFromDictionary:@{ kSequenceIDMacro: sequenceID }
                                                                   inURLString:url];
    }
    
    NSString *path = [url v_pathComponent];
    VStream *stream = [VStream streamForPath:path inContext:dependencyManager.objectManager.managedObjectStore.mainQueueManagedObjectContext];
    stream.name = [dependencyManager stringForKey:VDependencyManagerTitleKey];
    NSObject <VDirectoryCellFactory> *cellFactory = [[VDirectoryContentCellFactory alloc] initWithDependencyManager:dependencyManager];
    return [self streamDirectoryForStream:stream dependencyManager:dependencyManager andDirectoryCellFactory:cellFactory];
}

- (void)dealloc
{
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
}

#pragma mark - Shared setup

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateHeaderCellVisibility];
    
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.collectionView];
    NSDictionary *views = @{ @"collectionView" : self.collectionView };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    
    self.view.backgroundColor = [[self.dependencyManager colorForKey:VDependencyManagerBackgroundColorKey] colorWithAlphaComponent:1.0f];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self.directoryCellFactory registerCellsWithCollectionView:self.collectionView];
    
    self.streamDataSource = [[VStreamCollectionViewDataSource alloc] initWithStream:self.currentStream];
    self.streamDataSource.delegate = self;
    self.streamDataSource.collectionView = self.collectionView;
    self.collectionView.dataSource = self.streamDataSource;
    self.collectionView.delegate = self;
    
    [self refresh:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self v_addBadgingToAccessoryScreensWithDependencyManager:self.dependencyManager];
    
    [[self.dependencyManager coachmarkManager] displayCoachmarkViewInViewController:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.dependencyManager trackViewWillDisappear:self];
    
    [[self.dependencyManager coachmarkManager] hideCoachmarkViewInViewController:self animated:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.dependencyManager configureNavigationItem:self.navigationItem];
    
    [self v_addAccessoryScreensWithDependencyManager:self.dependencyManager];
    
    [self.dependencyManager trackViewWillAppear:self];
    
    // Layout may have changed between awaking from nib and being added to the container of the SoS
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)updateHeaderCellVisibility
{
    self.streamDataSource.hasHeaderCell = self.marqueeController.stream.marqueeItems.count > 0;
}

#pragma mark - VMarqueeControllerDataDelegate

- (void)marquee:(VAbstractMarqueeController *)marquee reloadedStreamWithItems:(NSArray *)streamItems
{
    [self updateHeaderCellVisibility];
}

#pragma mark - VMarqueeControllerSelectionDelegate

- (void)marquee:(VAbstractMarqueeController *)marquee selectedItem:(VStreamItem *)streamItem atIndexPath:(NSIndexPath *)path previewImage:(UIImage *)image
{
    NSDictionary *params = @{ VTrackingKeyName : streamItem.name ?: @"",
                              VTrackingKeyRemoteId : streamItem.remoteId ?: @"" };
    [[VTrackingManager sharedInstance] trackEvent:VTrackingEventUserDidSelectItemFromMarquee parameters:params];
    
    StreamCellContext *event = [[StreamCellContext alloc] initWithStreamItem:streamItem
                                                                      stream:self.currentStream
                                                                   fromShelf:YES];
    
    [self navigateToDisplayStreamItemWithEvent:event];
}

- (void)marquee:(VAbstractMarqueeController *)marquee selectedUser:(VUser *)user atIndexPath:(NSIndexPath *)path
{
    VUserProfileViewController *profileViewController = [self.dependencyManager userProfileViewControllerWithUser:user];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

#pragma mark - misc marquee helpers

- (BOOL)isMarqueeSection:(NSUInteger)section
{
    return ( self.streamDataSource.hasHeaderCell && section == 0 );
}

- (CGSize)marqueeSizeWithCollectionViewBounds:(CGRect)collectionViewBounds
{
    return [self.marqueeController desiredSizeWithCollectionViewBounds:collectionViewBounds];
}

#pragma mark - VDirectoryCollectionFlowLayoutMarqueeDelegate

- (BOOL)hasMarqueeCell
{
    return self.streamDataSource.hasHeaderCell;
}

#pragma mark - UICollectionViewDataSource

- (CGSize)collectionView:(UICollectionView *)localCollectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( [self isMarqueeSection:indexPath.section] )
    {
        //Return size for the marqueeCell that is provided by our superclass
        return [self.marqueeController desiredSizeWithCollectionViewBounds:localCollectionView.bounds];
    }
    
    return [self.directoryCellFactory sizeWithCollectionViewBounds:localCollectionView.bounds ofCellForStreamItem:[self.currentStream.streamItems objectAtIndex:indexPath.row]];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    UIEdgeInsets edgeInsets = UIEdgeInsetsZero;
    if ( section == 0 )
    {
        edgeInsets = UIEdgeInsetsMake(self.topInset,
                                      0.0f,
                                      0.0f,
                                      0.0f);
    }
    
    if ( ![self isMarqueeSection:section] )
    {
        //We're dealing with a directory section, add the edge insets from the factory
        UIEdgeInsets factoryInsets = self.directoryCellFactory.sectionInsets;
        edgeInsets.top += factoryInsets.top;
        edgeInsets.right += factoryInsets.right;
        edgeInsets.bottom += factoryInsets.bottom;
        edgeInsets.left += factoryInsets.left;
    }
    
    return edgeInsets;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    return CGSizeZero;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    VStreamItem *streamItem = [self.streamDataSource itemAtIndexPath:indexPath];
    
    StreamCellContext *event = [[StreamCellContext alloc] initWithStreamItem:streamItem
                                                                      stream:self.currentStream
                                                                   fromShelf:NO];
    
    [self navigateToDisplayStreamItemWithEvent:event];
}

- (void)navigateToDisplayStreamItemWithEvent:(StreamCellContext *)event
{
    VStreamItem *streamItem = event.streamItem;
    
    if ( streamItem.isSingleStream )
    {
        VStreamCollectionViewController *streamCollection = [self.dependencyManager templateValueOfType:[VStreamCollectionViewController class]
                                                                                                 forKey:kStreamCollectionKey
                                                                                  withAddedDependencies:@{ kSequenceIDKey: streamItem.remoteId, VDependencyManagerTitleKey: streamItem.name }];
        [self.navigationController pushViewController:streamCollection animated:YES];
    }
    else if ( streamItem.isContent )
    {
        [self.streamTrackingHelper onStreamCellSelectedWithCellEvent:event additionalInfo:nil];
        
        NSString *streamId = [self.marqueeController.stream hasShelfID] && event.fromShelf ? self.marqueeController.stream.shelfId : self.marqueeController.stream.streamId;
        [[self.dependencyManager scaffoldViewController] showContentViewWithSequence:(VSequence *)streamItem streamID:streamId commentId:nil placeHolderImage:nil];
    }
    else if ( [streamItem isKindOfClass:[VStream class]] )
    {
        VDirectoryCollectionViewController *destinationDirectory = [self.dependencyManager templateValueOfType:[VDirectoryCollectionViewController class]
                                                                                                                forKey:kDestinationDirectoryKey
                                                                                                 withAddedDependencies:@{ kSequenceIDKey: streamItem.remoteId, VDependencyManagerTitleKey: streamItem.name }];
        [self.navigationController pushViewController:destinationDirectory animated:YES];
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return [self.directoryCellFactory minimumInterItemSpacing];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return [self.directoryCellFactory minimumLineSpacing];
}

#pragma mark - VStreamCollectionDataDelegate

- (UICollectionViewCell *)dataSource:(VStreamCollectionViewDataSource *)dataSource cellForIndexPath:(NSIndexPath *)indexPath
{
    if ( [self isMarqueeSection:indexPath.section] )
    {
        return (UICollectionViewCell *)[self.marqueeController marqueeCellForCollectionView:self.collectionView atIndexPath:indexPath];
    }
    
    return [self.directoryCellFactory collectionView:self.collectionView cellForStreamItem:[self.currentStream.streamItems objectAtIndex:indexPath.row] atIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)localCollectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( ![self isMarqueeSection:indexPath.section] && [self.directoryCellFactory respondsToSelector:@selector(prepareCell:forDisplayInCollectionView:atIndexPath:)] )
    {
        //Allow directory cell factory to prepare cell for display
        [(id <VDirectoryCellUpdeatableFactory>)self.directoryCellFactory prepareCell:cell forDisplayInCollectionView:localCollectionView atIndexPath:indexPath];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ( [super respondsToSelector:@selector(scrollViewDidScroll:)] )
    {
        [super scrollViewDidScroll:scrollView];
    }
    
    if ( [scrollView isKindOfClass:[UICollectionView class]] && [self.directoryCellFactory respondsToSelector:@selector(collectionViewDidScroll:)] )
    {
        [(id <VDirectoryCellUpdeatableFactory>)self.directoryCellFactory collectionViewDidScroll:(UICollectionView *)scrollView];
    }
}

#pragma mark - VCoachmarkDisplayer

- (NSString *)screenIdentifier
{
    return [self.dependencyManager stringForKey:VDependencyManagerIDKey];
}

#pragma mark - VTabMenuContainedViewControllerNavigation

- (void)reselected
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.collectionView setContentOffset:CGPointZero animated:YES];
}

@end