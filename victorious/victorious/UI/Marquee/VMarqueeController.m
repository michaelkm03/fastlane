//
//  VMarqueeController.m
//  victorious
//
//  Created by Will Long on 9/27/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VMarqueeController.h"

#import "VStream+Fetcher.h"
#import "VSequence.h"

#import "VStreamCollectionViewDataSource.h"
#import "VMarqueeStreamItemCell.h"

#import "VGroupedStreamCollectionViewController.h"
#import "VMarqueeTabIndicatorView.h"

#import "VThemeManager.h"

@interface VMarqueeController () <VStreamCollectionDataDelegate, VMarqueeCellDelegate>

@property (nonatomic, weak) IBOutlet UIView *tabContainerView;

@property (nonatomic, strong) VStream *stream;
@property (nonatomic, strong) VStreamCollectionViewDataSource *streamDataSource;
@property (nonatomic, strong) VStreamItem *currentStreamItem;
@property (nonatomic, assign) NSInteger currentPage;

@property (nonatomic, strong) NSTimer *autoScrollTimer;

@end

@implementation VMarqueeController

+ (CGSize)desiredSizeWithCollectionViewBounds:(CGRect)bounds
{
    return [VMarqueeStreamItemCell desiredSizeWithCollectionViewBounds:bounds];
}

- (instancetype)initWithStream:(VStream *)stream
{
    self = [super init];
    if (self)
    {
        self.stream = stream;
        self.streamDataSource = [[VStreamCollectionViewDataSource alloc] initWithStream:stream];
        self.streamDataSource.delegate = self;
        self.streamDataSource.collectionView = self.collectionView;
        self.collectionView.dataSource = self.streamDataSource;
        self.currentPage = 0;
    }
    return self;
}

- (void)dealloc
{
    if (self.collectionView.delegate == self)
    {
        self.collectionView.delegate = nil;
    }
    [self.autoScrollTimer invalidate];
}

- (void)setCollectionView:(UICollectionView *)collectionView
{
    _collectionView = collectionView;
    self.streamDataSource.collectionView = _collectionView;
    collectionView.delegate = self;
    collectionView.dataSource = self.streamDataSource;
}

- (void)selectNextTab
{
    CGFloat pageWidth = self.collectionView.frame.size.width;
    NSInteger currentPage = self.collectionView.contentOffset.x / pageWidth;
    currentPage ++;
    if (currentPage == (NSInteger)self.streamDataSource.count)
    {
        currentPage = 0;
    }
    
    [self.collectionView setContentOffset:CGPointMake(currentPage * pageWidth, self.collectionView.contentOffset.y) animated:YES];
}

- (void)scrolledToPage:(NSInteger)currentPage
{
    self.tabView.currentlySelectedTab = currentPage;
    self.currentStreamItem = [self.streamDataSource itemAtIndexPath:[NSIndexPath indexPathForRow:currentPage inSection:0]];
    [self enableTimer];
}

- (void)refreshWithSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *))failureBlock
{
    [self.streamDataSource loadPage:VPageTypeFirst withSuccess:
     ^{
         [self scrolledToPage:0];
         
         [self.delegate marqueeRefreshedContent:self];
         
         if (successBlock)
         {
             successBlock();
         }
     }
                                      failure:failureBlock];
}

#pragma mark - CollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [VMarqueeStreamItemCell desiredSizeWithCollectionViewBounds:collectionView.bounds];
}

//Let the container handle the selection.
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    VStreamItem *item = [self.streamDataSource itemAtIndexPath:indexPath];
    VMarqueeStreamItemCell *cell = (VMarqueeStreamItemCell *)[collectionView cellForItemAtIndexPath:indexPath];
    UIImage *previewImage = nil;
    if ( [cell isKindOfClass:[VMarqueeStreamItemCell class]] )
    {
        previewImage = cell.previewImageView.image;
    }
    
    [self.delegate marquee:self selectedItem:item atIndexPath:indexPath previewImage:previewImage];
    [self.autoScrollTimer invalidate];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat pageWidth = self.collectionView.frame.size.width;
    NSInteger currentPage = self.collectionView.contentOffset.x / pageWidth;
    if ( currentPage != self.currentPage )
    {
        self.currentPage = currentPage;
        if ( (NSUInteger) self.currentPage < self.streamDataSource.count )
        {
            [self scrolledToPage:self.currentPage];
        }
    }
}

- (void)disableTimer
{
    [self.autoScrollTimer invalidate];
}

- (void)enableTimer
{
    [self.autoScrollTimer invalidate];
    self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:kVDetailVisibilityDuration + kVDetailHideDuration
                                                            target:self
                                                          selector:@selector(selectNextTab)
                                                          userInfo:nil
                                                           repeats:NO];
    NSInteger currentPage = self.currentPage;
    if ( currentPage < [[self streamDataSource] collectionView:self.collectionView numberOfItemsInSection:0] )
    {
        [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(VMarqueeStreamItemCell *cell, NSUInteger idx, BOOL *stop)
         {
             if ( [self.collectionView indexPathForCell:cell].row == currentPage )
             {
                 [cell setDetailsContainerVisible:YES animated:NO];
                 [cell restartHideTimer];
                 *stop = YES;
             }
         }];
    }
}

#pragma mark - VMarqueeCellDelegate

- (void)cell:(VMarqueeStreamItemCell *)cell selectedUser:(VUser *)user
{
    [self.delegate marquee:self selectedUser:user atIndexPath:[self.collectionView indexPathForCell:cell]];
    [self.autoScrollTimer invalidate];
}

#pragma mark - VStreamCollectionDataDelegate

- (UICollectionViewCell *)dataSource:(VStreamCollectionViewDataSource *)dataSource cellForIndexPath:(NSIndexPath *)indexPath
{
    VStreamItem *item = [self.stream.streamItems objectAtIndex:indexPath.row];
    VMarqueeStreamItemCell *cell;
    
    cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:[VMarqueeStreamItemCell suggestedReuseIdentifier] forIndexPath:indexPath];
    CGSize size = [VMarqueeStreamItemCell desiredSizeWithCollectionViewBounds:self.collectionView.bounds];
    cell.bounds = CGRectMake(0, 0, size.width, size.height);
    cell.streamItem = item;
    cell.delegate = self;
    
    return cell;
}

@end
