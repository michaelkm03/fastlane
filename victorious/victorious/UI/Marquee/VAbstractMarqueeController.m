//
//  VAbstractMarqueeController.m
//  victorious
//
//  Created by Sharif Ahmed on 3/25/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VAbstractMarqueeController.h"
#import "VAbstractMarqueeCollectionViewCell.h"
#import "VAbstractMarqueeStreamItemCell.h"
#import "VTimerManager.h"
#import "VStreamItem.h"
#import "VStream+Fetcher.h"
#import "VDependencyManager.h"
#import "NSString+VParseHelp.h"
#import "VObjectManager.h"
#import "VDependencyManager+VObjectManager.h"
#import <FBKVOController.h>
#import "VURLMacroReplacement.h"

static NSString * const kStreamURLKey = @"streamURL";
static NSString * const kSequenceIDKey = @"sequenceID";
static NSString * const kSequenceIDMacro = @"%%SEQUENCE_ID%%";
static const CGFloat kDefaultMarqueeTimerFireDuration = 5.0f;

@interface VAbstractMarqueeController ()

@property (nonatomic, readwrite) NSUInteger currentPage;
@property (nonatomic, readwrite) VTimerManager *autoScrollTimerManager;
@property (nonatomic, readwrite) VStreamItem *currentStreamItem;
@property (nonatomic, strong) NSMutableSet *registeredReuseIdentifiers;

@end

@implementation VAbstractMarqueeController

- (instancetype)initWithDependencyManager:(VDependencyManager *)dependencyManager
{
    self = [super init];
    if ( self != nil )
    {
        _dependencyManager = dependencyManager;
        _registeredReuseIdentifiers = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc
{
    if (_collectionView.delegate == self)
    {
        _collectionView.delegate = nil;
    }
    [_autoScrollTimerManager invalidate];
}

#pragma mark - stream updating

- (void)setStream:(VStream *)stream
{
    _stream = stream;
    [self setupWithStream:stream];
}

- (void)setupWithStream:(VStream *)stream
{
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.currentPage = 0;
    [self addKVOToMarqueeItemsOfStream:stream];
}

- (void)addKVOToMarqueeItemsOfStream:(VStream *)stream
{
    [self.KVOController observe:stream
                        keyPath:[self marqueeItemsKeyPath]
                        options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                         action:@selector(marqueeItemsUpdated)];
}

- (NSString *)marqueeItemsKeyPath
{
    return NSStringFromSelector(@selector(marqueeItems));
}

- (void)marqueeItemsUpdated
{
    [self.dataDelegate marquee:self reloadedStreamWithItems:[self.stream.marqueeItems array]];
    [self registerStreamItemCellsWithCollectionView:self.collectionView forMarqueeItems:[self.stream.marqueeItems array]];
    [self.collectionView reloadData];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat pageWidth = self.collectionView.frame.size.width;
    NSUInteger currentPage = self.collectionView.contentOffset.x / pageWidth;
    if ( currentPage != self.currentPage )
    {
        self.currentPage = currentPage;
        if ( self.currentPage < self.stream.marqueeItems.count )
        {
            [self scrolledToPage:self.currentPage];
        }
    }
}

- (void)selectNextTab
{
    CGFloat pageWidth = CGRectGetWidth(self.collectionView.bounds);
    NSUInteger currentPage = ( self.collectionView.contentOffset.x / pageWidth ) + 1;
    if (currentPage == self.stream.marqueeItems.count)
    {
        currentPage = 0;
    }
    
    [self.collectionView setContentOffset:CGPointMake(currentPage * pageWidth, self.collectionView.contentOffset.y) animated:YES];
}

- (void)scrolledToPage:(NSInteger)currentPage
{
    self.currentStreamItem = [self.stream.marqueeItems objectAtIndex:currentPage];
    [self enableTimer];
}

- (void)disableTimer
{
    [self.autoScrollTimerManager invalidate];
    //Hide all detail boxes here
}

- (void)enableTimer
{
    [self.autoScrollTimerManager invalidate];
    self.autoScrollTimerManager = [VTimerManager scheduledTimerManagerWithTimeInterval:[self timerFireInterval]
                                                                                target:self
                                                                              selector:@selector(selectNextTab)
                                                                              userInfo:nil
                                                                               repeats:NO];
}

- (NSTimeInterval)timerFireInterval
{
    return kDefaultMarqueeTimerFireDuration;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.stream.marqueeItems.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self desiredSizeWithCollectionViewBounds:collectionView.bounds];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsZero;
}

//Let the container handle the selection.
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    VStreamItem *item = self.stream.marqueeItems[indexPath.row];
    
    [self.selectionDelegate marquee:self selectedItem:item atIndexPath:indexPath previewImage:nil];
    [self.autoScrollTimerManager invalidate];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VStreamItem *item = [self.stream.marqueeItems objectAtIndex:indexPath.row];
    VAbstractMarqueeStreamItemCell *cell;
    Class marqueeStreamItemCellClass = [[self class] marqueeStreamItemCellClass];
    NSAssert([marqueeStreamItemCellClass isSubclassOfClass:[VAbstractMarqueeStreamItemCell class]], @"Class returned from marqueeStreamItemCellClass must be a subclass of VAbstractMarqueeStreamItemCell");

    NSString *reuseIdentifierForSequence = [marqueeStreamItemCellClass reuseIdentifierForStreamItem:item baseIdentifier:nil];
    
    if (![self.registeredReuseIdentifiers containsObject:reuseIdentifierForSequence])
    {
        [collectionView registerClass:marqueeStreamItemCellClass
           forCellWithReuseIdentifier:reuseIdentifierForSequence];
        [self.registeredReuseIdentifiers addObject:reuseIdentifierForSequence];
    }
    
    cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:[marqueeStreamItemCellClass reuseIdentifierForStreamItem:item baseIdentifier:nil] forIndexPath:indexPath];
    cell.dependencyManager = self.dependencyManager;
    cell.streamItem = item;
    
    return cell;
}

- (void)setCollectionView:(UICollectionView *)collectionView
{
    _collectionView = collectionView;
    [self registerStreamItemCellsWithCollectionView:collectionView forMarqueeItems:[self.stream.marqueeItems array]];
    collectionView.delegate = self;
    collectionView.dataSource = self;
    ((UICollectionViewFlowLayout *)collectionView.collectionViewLayout).sectionInset = UIEdgeInsetsZero;
}

- (void)setDependencyManager:(VDependencyManager *)dependencyManager
{
    _dependencyManager = dependencyManager;
    for ( VAbstractMarqueeStreamItemCell *marqueeItemCell in self.collectionView.visibleCells )
    {
        marqueeItemCell.dependencyManager = dependencyManager;
    }
}

- (void)registerStreamItemCellsWithCollectionView:(UICollectionView *)collectionView forMarqueeItems:(NSArray *)marqueeItems
{
    if ( collectionView == nil || marqueeItems == nil )
    {
        return;
    }
    
    Class marqueeStreamItemCellClass = [[self class] marqueeStreamItemCellClass];
    NSAssert([marqueeStreamItemCellClass isSubclassOfClass:[VAbstractMarqueeStreamItemCell class]], @"Class returned from marqueeStreamItemCellClass must be a subclass of VAbstractMarqueeStreamItemCell");
    for (VStreamItem *marqueeItem in marqueeItems)
    {
        NSString *reuseIdentifierForSequence = [marqueeStreamItemCellClass reuseIdentifierForStreamItem:marqueeItem
                                                                                         baseIdentifier:nil];
        
        if (![self.registeredReuseIdentifiers containsObject:reuseIdentifierForSequence])
        {
            UINib *nib = [marqueeStreamItemCellClass nibForCell];
            [collectionView registerNib:nib
             forCellWithReuseIdentifier:reuseIdentifierForSequence];
            [self.registeredReuseIdentifiers addObject:reuseIdentifierForSequence];
        }
    }
}

- (void)registerCollectionViewCellWithCollectionView:(UICollectionView *)collectionView
{
    NSAssert(false, @"registerCollectionViewCellWithCollectionView: must be implemented by subclasses of VAbstractMarqueeController");
}

- (VAbstractMarqueeCollectionViewCell *)marqueeCellForCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath
{
    NSAssert(false, @"marqueeCellForCollectionView:atIndexPath: must be implemented by subclasses of VAbstractMarqueeController");
    return nil;
}

- (CGSize)desiredSizeWithCollectionViewBounds:(CGRect)bounds
{
    NSAssert(false, @"Subclasses must override desiredSizeWithCollectionViewBounds: in VAbstractMarqueeController");
    return CGSizeZero;
}

- (void)setupStreamItemCell:(VAbstractMarqueeStreamItemCell *)streamItemCell withDependencyManager:(VDependencyManager *)dependencyManager andStreamItem:(VStreamItem *)streamItem
{
    NSAssert(false, @"Subclasses must override setupStreamItemCell:withDependencyManager:andStreamItem: in VAbstractMarqueeController");
}

+ (Class)marqueeStreamItemCellClass
{
    NSAssert(false, @"Subclasses must override marqueeStreamItemCellClass in VAbstractMarqueeController");
    return [VAbstractMarqueeStreamItemCell class];
}

@end
