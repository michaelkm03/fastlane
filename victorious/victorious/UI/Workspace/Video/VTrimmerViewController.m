//
//  VTrimmerViewController.m
//  victorious
//
//  Created by Michael Sena on 12/30/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VTrimmerViewController.h"

// Frameworks
@import AVFoundation;

// Views
#import "VThumbnailCell.h"
#import "VTrimControl.h"

#import "VThemeManager.h"

static NSString *const emptyCellIdentifier = @"emptyCell";

static const CGFloat kTimelineTopPadding = 48.0f;
static const CGFloat kTimelineBottomPadding = 30.0f;
static const CGFloat kTimelineDarkeningAlpha = 0.5f;

@interface VTrimmerViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *thumbnailCollecitonView;

@property (nonatomic, strong) VTrimControl *trimControl;

@property (nonatomic, strong) UIView *trimDimmingView;
@property (nonatomic, strong) NSLayoutConstraint *dimmingViewWidthConstraint;

@property (nonatomic, strong) UIView *currentPlayBackOverlayView;
@property (nonatomic, strong) NSLayoutConstraint *currentPlayBackWidthConstraint;

@end

@implementation VTrimmerViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self prepareThumbnailCollectionView];
    [self prepareDimmingView];
    [self preparePlaybackOverlay];
    [self prepareTrimControl];
}

#pragma mark - Property Accessors

- (void)setMaximumTrimDuration:(CMTime)maximumTrimDuration
{
    _maximumTrimDuration = maximumTrimDuration;
    self.trimControl.maxDuration = maximumTrimDuration;
    [self updateTrimControlTitleWithTime:self.trimControl.selectedDuration];
    [self.thumbnailCollecitonView.collectionViewLayout invalidateLayout];
}

- (void)setMaximumEndTime:(CMTime)maximumEndTime
{
    _maximumEndTime = maximumEndTime;
    [self.thumbnailCollecitonView.collectionViewLayout invalidateLayout];
}

- (CMTimeRange)selectedTimeRange
{
    return CMTimeRangeMake([self currentTimeOffset], self.trimControl.selectedDuration);
}

- (void)setCurrentPlayTime:(CMTime)currentPlayTime
{
    _currentPlayTime = currentPlayTime;
    if (CMTIME_COMPARE_INLINE(currentPlayTime, >, kCMTimeZero))
    {
        Float64 progress = (CMTimeGetSeconds(currentPlayTime) - CMTimeGetSeconds([self currentTimeOffset])) / CMTimeGetSeconds(self.maximumTrimDuration);
        CGFloat playbackOverlayWidth = CGRectGetWidth(self.view.bounds) * progress;
        self.currentPlayBackWidthConstraint.constant = (playbackOverlayWidth >= 0) ? playbackOverlayWidth : 0.0f;
        [self.view layoutIfNeeded];
    }
}

- (void)setThumbnailDataSource:(id<VTrimmerThumbnailDataSource>)thumbnailDataSource
{
    _thumbnailDataSource = thumbnailDataSource;
    
    [self.thumbnailCollecitonView reloadData];
}

#pragma mark - Target/Action

- (void)trimSelectionChanged:(VTrimControl *)trimControl
{
    [self updateAndNotify];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    CGFloat neededTimeLineWidth = [self timelineWidthForFullTrack];
    
    CGFloat frameWidth = CGRectGetHeight(collectionView.bounds);
    neededTimeLineWidth = neededTimeLineWidth - frameWidth;
    NSInteger numberOfFrames = 1;
    
    while (neededTimeLineWidth > 0)
    {
        numberOfFrames++;
        neededTimeLineWidth = neededTimeLineWidth - frameWidth;
    }
    
    return numberOfFrames + 1; // 1 extra for a spacer cell
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [self collectionView:collectionView
                       numberOfItemsInSection:indexPath.section] - 1)
    {
        UICollectionViewCell *emptyCell = [collectionView dequeueReusableCellWithReuseIdentifier:emptyCellIdentifier
                                                                                    forIndexPath:indexPath];
        emptyCell.backgroundColor = [UIColor clearColor];
        emptyCell.contentView.backgroundColor = [UIColor clearColor];
        return emptyCell;
    }
    
    VThumbnailCell *thumnailCell = [collectionView dequeueReusableCellWithReuseIdentifier:[VThumbnailCell suggestedReuseIdentifier]
                                                                             forIndexPath:indexPath];
    CGPoint center = [self.thumbnailCollecitonView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath].center;
    CGFloat percentThrough = center.x / [self timelineWidthForFullTrack];
    CMTime timeForCell = CMTimeMake(self.maximumEndTime.value * percentThrough, self.maximumEndTime.timescale);
    thumnailCell.valueForThumbnail = [NSValue valueWithCMTime:timeForCell];
    __weak VThumbnailCell *weakCell = thumnailCell;
    [self.thumbnailDataSource trimmerViewController:self
                                   thumbnailForTime:timeForCell
                                     withCompletion:^(UIImage *thumbnail, CMTime timeForImage, id generatingDataSource)
     {
         CMTime timeValue = [weakCell.valueForThumbnail CMTimeValue];
         if (CMTIME_COMPARE_INLINE(timeValue, ==, timeForImage))
         {
             dispatch_async(dispatch_get_main_queue(), ^
                            {
                                weakCell.thumbnail = thumbnail;
                            });
         }
     }];
    return thumnailCell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger numberOfItems = [self collectionView:collectionView
                            numberOfItemsInSection:indexPath.section];
    // Empty Cell
    if (indexPath.row == numberOfItems - 1)
    {
        return CGSizeMake(CGRectGetWidth(collectionView.frame) - [self timelineWidthPerSecond], CGRectGetHeight(collectionView.bounds));
    }
    else if (indexPath.row == numberOfItems - 2)
    {
        CGFloat width = [self timelineWidthForFullTrack];
        if (!isnan(width))
        {
            width = width - ((numberOfItems - 2) * CGRectGetHeight(collectionView.bounds));
            return CGSizeMake(width, CGRectGetHeight(collectionView.frame));
        }
    }
    return CGSizeMake(CGRectGetHeight(collectionView.frame), CGRectGetHeight(collectionView.frame));
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0f;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView.isDecelerating)
    {
        [self.delegate trimmerViewControllerEndedSeeking:self];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateAndNotify];
    
    if (!CMTimeRangeContainsTime(self.selectedTimeRange, self.currentPlayTime))
    {
        [self.delegate trimmerViewControllerBeganSeeking:self
                                                  toTime:self.selectedTimeRange.start];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        [self.delegate trimmerViewControllerEndedSeeking:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self.delegate trimmerViewControllerEndedSeeking:self];
}

#pragma mark - Private Methods

- (void)updateAndNotify
{
    if (isnan(CMTimeGetSeconds(self.trimControl.maxDuration)))
    {
        return;
    }
    
    [self updateTrimControlTitleWithTime:self.trimControl.selectedDuration];
    
    if ([self.delegate respondsToSelector:@selector(trimmerViewController:didUpdateSelectedTimeRange:)])
    {
        [self.delegate trimmerViewController:self
                  didUpdateSelectedTimeRange:[self selectedTimeRange]];
    }
    Float64 progress = CMTimeGetSeconds(self.trimControl.selectedDuration) / CMTimeGetSeconds(self.trimControl.maxDuration);
    self.dimmingViewWidthConstraint.constant = CGRectGetWidth(self.view.bounds) - (CGRectGetWidth(self.view.bounds) * progress);
    [self.view layoutIfNeeded];
}

- (void)updateTrimControlTitleWithTime:(CMTime)time
{
    NSString *title = [NSString stringWithFormat:@"%@ %@", [NSString stringWithFormat:@"%.0f", CMTimeGetSeconds(time)], NSLocalizedString(@"s", @"Second time interval abbreviation.")];
    self.trimControl.attributedTitle = [[NSAttributedString alloc] initWithString:title
                                                                       attributes:@{NSFontAttributeName: [[VThemeManager sharedThemeManager] themedFontForKey:kVHeading2Font]}];
}

- (CGFloat)timelineWidthPerSecond
{
    return CGRectGetWidth(self.thumbnailCollecitonView.bounds) / CMTimeGetSeconds(self.maximumTrimDuration);
}

- (CGFloat)timelineWidthForFullTrack
{
    return [self timelineWidthPerSecond] * CMTimeGetSeconds(self.maximumEndTime);
}

- (CMTime)currentTimeOffset
{
    return CMTimeMake(self.thumbnailCollecitonView.contentOffset.x, [self timelineWidthPerSecond]);
}

#pragma mark View Hierarcy Setup

- (void)prepareThumbnailCollectionView
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(CGRectGetHeight(self.view.frame), CGRectGetHeight(self.view.frame));
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.thumbnailCollecitonView = [[UICollectionView alloc] initWithFrame:self.view.bounds
                                                      collectionViewLayout:layout];
    [self.thumbnailCollecitonView registerNib:[VThumbnailCell nibForCell]
                   forCellWithReuseIdentifier:[VThumbnailCell suggestedReuseIdentifier]];
    [self.thumbnailCollecitonView registerClass:[UICollectionViewCell class]
                     forCellWithReuseIdentifier:emptyCellIdentifier];
    self.thumbnailCollecitonView.dataSource = self;
    self.thumbnailCollecitonView.delegate = self;
    self.thumbnailCollecitonView.alwaysBounceHorizontal = NO;
    self.thumbnailCollecitonView.bounces = NO;
    self.thumbnailCollecitonView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.thumbnailCollecitonView];
    self.thumbnailCollecitonView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *viewMap = @{@"collectionView": self.thumbnailCollecitonView};

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[collectionView]|"
                                                                      options:kNilOptions
                                                                      metrics:nil
                                                                        views:viewMap]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-kTimelineTopPadding-[collectionView]-trimSpacingToBottom-|"
                                                                      options:kNilOptions
                                                                      metrics:@{@"kTimelineTopPadding":@(kTimelineTopPadding),
                                                                                @"trimSpacingToBottom":@(kTimelineBottomPadding)}
                                                                        views:viewMap]];
}

- (void)prepareDimmingView
{
    self.trimDimmingView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.trimDimmingView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
    self.trimDimmingView.userInteractionEnabled = NO;
    [self.view addSubview:self.trimDimmingView];
    self.trimDimmingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[trimDimmingView]|"
                                                                      options:kNilOptions
                                                                      metrics:nil
                                                                        views:@{@"trimDimmingView":self.trimDimmingView}]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.trimDimmingView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.thumbnailCollecitonView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.trimDimmingView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.thumbnailCollecitonView
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    self.dimmingViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.trimDimmingView
                                                                   attribute:NSLayoutAttributeWidth
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:nil
                                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                                  multiplier:1.0f
                                                                    constant:0.0f];
    [self.view addConstraint:self.dimmingViewWidthConstraint];
}

- (void)prepareTrimControl
{
    self.trimControl = [[VTrimControl alloc] initWithFrame:CGRectZero];
    self.trimControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.trimControl addTarget:self
                         action:@selector(trimSelectionChanged:)
               forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.trimControl];
    NSDictionary *viewMap = @{@"trimControl": self.trimControl};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[trimControl]|"
                                                                      options:kNilOptions
                                                                      metrics:nil
                                                                        views:viewMap]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[trimControl]-kTimelineBottomPadding-|"
                                                                      options:kNilOptions
                                                                      metrics:@{@"kTimelineBottomPadding":@(kTimelineBottomPadding)}
                                                                        views:viewMap]];
}

- (void)preparePlaybackOverlay
{
    self.currentPlayBackOverlayView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.currentPlayBackOverlayView.userInteractionEnabled = NO;
    self.currentPlayBackOverlayView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:kTimelineDarkeningAlpha];
    [self.view addSubview:self.currentPlayBackOverlayView];
    self.currentPlayBackOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[overlayView]"
                                                                      options:kNilOptions
                                                                      metrics:nil
                                                                        views:@{@"overlayView":self.currentPlayBackOverlayView}]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.currentPlayBackOverlayView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.thumbnailCollecitonView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.currentPlayBackOverlayView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.thumbnailCollecitonView
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    self.currentPlayBackWidthConstraint = [NSLayoutConstraint constraintWithItem:self.currentPlayBackOverlayView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1.0f
                                                                        constant:0.0f];
    [self.view addConstraint:self.currentPlayBackWidthConstraint];
}

@end