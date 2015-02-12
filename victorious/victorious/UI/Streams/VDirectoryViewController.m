//
//  VStreamDirectoryCollectionView.m
//  victorious
//
//  Created by Will Long on 9/8/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VDirectoryViewController.h"

// Data Source
#import "VStreamCollectionViewDataSource.h"

// ViewControllers
#import "VStreamCollectionViewController.h"
#import "VNewContentViewController.h"

// Views
#import "MBProgressHUD.h"
#import "VDirectoryItemCell.h"

//Data Models
#import "VStream+Fetcher.h"
#import "VSequence.h"

#import "VDependencyManager+VObjectManager.h"
#import "VObjectManager.h"
#import "VSettingManager.h"

static NSString * const kStreamDirectoryStoryboardId = @"kStreamDirectory";
static NSString * const kStreamURLPathKey = @"streamUrlPath";

static CGFloat const kDirectoryInset = 10.0f;

@interface VDirectoryViewController () <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, VStreamCollectionDataDelegate, VNewContentViewControllerDelegate>

@end

@implementation VDirectoryViewController

#pragma mark - Initializers

+ (instancetype)streamDirectoryForStream:(VStream *)stream
{
    VDirectoryViewController *streamDirectory = [[VDirectoryViewController alloc] initWithNibName:nil
                                                                                           bundle:nil];
    streamDirectory.currentStream = stream;
    streamDirectory.title = stream.name;
    return streamDirectory;
}

#pragma mark VHasManagedDependencies conforming initializer

+ (instancetype)newWithDependencyManager:(VDependencyManager *)dependencyManager
{
    NSAssert([NSThread isMainThread], @"This method must be called on the main thread");
    VStream *stream = [VStream streamForPath:[dependencyManager stringForKey:kStreamURLPathKey] inContext:dependencyManager.objectManager.managedObjectStore.mainQueueManagedObjectContext];
    stream.name = [dependencyManager stringForKey:VDependencyManagerTitleKey];
    return [self streamDirectoryForStream:stream];
}

#pragma mark - UIView overrides

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Register cells
    UINib *nib = [UINib nibWithNibName:VDirectoryItemCellNameStream bundle:nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:VDirectoryItemCellNameStream];

    self.streamDataSource = [[VStreamCollectionViewDataSource alloc] initWithStream:self.currentStream];
    self.streamDataSource.delegate = self;
    self.streamDataSource.collectionView = self.collectionView;
    self.collectionView.dataSource = self.streamDataSource;
    self.collectionView.delegate = self;
    
    [self refresh:self.refreshControl];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Layout may have changed between awaking from nib and being added to the container of the SoS
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

#pragma mark - CollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)collectionViewLayout;
    
    CGFloat width = CGRectGetWidth(collectionView.bounds);
    width = width - flowLayout.sectionInset.left - flowLayout.sectionInset.right - flowLayout.minimumInteritemSpacing;
    width = floorf(width * 0.5f);
    
    BOOL isStreamOfStreamsRow = [[self.streamDataSource itemAtIndexPath:indexPath] isKindOfClass:[VStream class]];
    
    if (((indexPath.row % 2) == 1) && !isStreamOfStreamsRow)
    {
        NSIndexPath *previousIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section];
        isStreamOfStreamsRow = [[self.streamDataSource itemAtIndexPath:previousIndexPath] isKindOfClass:[VStream class]];
    }
    
    CGFloat height = isStreamOfStreamsRow ? [VDirectoryItemCell desiredStreamOfStreamsHeight] : [VDirectoryItemCell desiredStreamOfContentHeight];
    
    return CGSizeMake(width, height);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    VStreamItem *item = [self.streamDataSource itemAtIndexPath:indexPath];
    //Commented out code is the inital logic for supporting other stream types / sequences in streams.
    if ([item isKindOfClass:[VStream class]] && [((VStream *)item) onlyContainsSequences])
    {
        VStreamCollectionViewController *streamCollection = [VStreamCollectionViewController streamViewControllerForStream:(VStream *)item];
        [self.navigationController pushViewController:streamCollection animated:YES];
    }
    else if ([item isKindOfClass:[VStream class]])
    {
        VDirectoryViewController *sos = [VDirectoryViewController streamDirectoryForStream:(VStream *)item];
        [self.navigationController pushViewController:sos animated:YES];
    }
    else if ([item isKindOfClass:[VSequence class]])
    {
        VContentViewViewModel *contentViewViewModel = [[VContentViewViewModel alloc] initWithSequence:(VSequence *)item];
        VNewContentViewController *contentViewController = [VNewContentViewController contentViewControllerWithViewModel:contentViewViewModel];
        contentViewController.delegate = self;
        [self.navigationController pushViewController:contentViewController animated:YES];
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(self.contentInset.top + kDirectoryInset,
                            self.contentInset.left + kDirectoryInset,
                            self.contentInset.bottom,
                            self.contentInset.right + kDirectoryInset);
}

#pragma mark - VStreamCollectionDataDelegate

- (UICollectionViewCell *)dataSource:(VStreamCollectionViewDataSource *)dataSource cellForIndexPath:(NSIndexPath *)indexPath
{
    VStreamItem *item = [self.currentStream.streamItems objectAtIndex:indexPath.row];
    VDirectoryItemCell *cell;

    cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:VDirectoryItemCellNameStream forIndexPath:indexPath];
    cell.streamItem = item;
    
    return cell;
}

#pragma mark - VNewContentViewControllerDelegate

- (void)newContentViewControllerDidClose:(VNewContentViewController *)contentViewController
{
    [self.navigationController popViewControllerAnimated:YES];
    contentViewController.delegate = nil;
}

- (void)newContentViewControllerDidDeleteContent:(VNewContentViewController *)contentViewController
{
    [self.navigationController popViewControllerAnimated:YES];
    [self refresh:self.refreshControl];
    contentViewController.delegate = nil;
}

@end
