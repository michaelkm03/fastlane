//
//  VStreamDirectoryCollectionView.m
//  victorious
//
//  Created by Will Long on 9/8/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VDirectoryViewController.h"

#import "VDirectoryDataSource.h"
#import "VDirectoryItemCell.h"

#import "VStreamTableViewController.h"
#import "VContentViewController.h"
#import "VNavigationHeaderView.h"
#import "UIViewController+VSideMenuViewController.h"

//Data Models
#import "VStream.h"
#import "VSequence.h"

#warning test imports
#import "VObjectManager.h"
#import "VStream+Fetcher.h"
#import "VConstants.h"

NSString * const kStreamDirectoryStoryboardId = @"kStreamDirectory";

@interface VDirectoryViewController () <UICollectionViewDelegate, VNavigationHeaderDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic, readwrite) VDirectoryDataSource *directoryDataSource;
@property (nonatomic, strong) VStream *stream;

@property (nonatomic, strong) VNavigationHeaderView *navHeaderView;
@property (nonatomic, strong) NSLayoutConstraint *headerYConstraint;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end


@implementation VDirectoryViewController

+ (instancetype)streamDirectoryForStream:(VStream *)stream
{
    UIViewController *currentViewController = [[UIApplication sharedApplication] delegate].window.rootViewController;
    VDirectoryViewController *streamDirectory = (VDirectoryViewController*)[currentViewController.storyboard instantiateViewControllerWithIdentifier: kStreamDirectoryStoryboardId];
    
//#warning test code
//    VStream *aDirectory = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([VStream class]) inManagedObjectContext:[VObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext];
//    aDirectory.name = @"test";
//    VStream *homeStream = [VStream streamForCategories: [VUGCCategories() arrayByAddingObjectsFromArray:VOwnerCategories()]];
//    VStream *communityStream = [VStream streamForCategories: VUGCCategories()];
//    VStream *ownerStream = [VStream streamForCategories: VOwnerCategories()];
//    homeStream.name = @"Home";
//    homeStream.previewImagesObject = @"http://victorious.com/img/logo.png";
//    [homeStream addStreamsObject:aDirectory];
//    
//    communityStream.name = @"Community";
//    communityStream.previewImagesObject = @"https://www.google.com/images/srpr/logo11w.png";
//    [communityStream addStreamsObject:aDirectory];
//    
//    ownerStream.name = @"Owner";
//    ownerStream.previewImagesObject = @"https://www.google.com/images/srpr/logo11w.png";
//    [ownerStream addStreamsObject:aDirectory];
//    
//    for (VSequence *sequence in homeStream.streamItems)
//    {
//        [sequence addStreamsObject:aDirectory];
//    }
    
    streamDirectory.stream = stream;
    
    return streamDirectory;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navHeaderView = [VNavigationHeaderView menuButtonNavHeaderWithControlTitles:nil];
    self.navHeaderView.delegate = self;
    [self.view addSubview:self.navHeaderView];
    
    self.headerYConstraint = [NSLayoutConstraint constraintWithItem:self.navHeaderView
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0f
                                                                          constant:0.0f];
    
    NSLayoutConstraint *collectionViewTopConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.navHeaderView
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:1.0f
                                                                          constant:0.0f];
    
    [self.view addConstraints:@[collectionViewTopConstraint, self.headerYConstraint]];
    
    self.directoryDataSource = [[VDirectoryDataSource alloc] initWithStream:self.stream];
    self.collectionView.dataSource = self.directoryDataSource;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh:)
             forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
    self.collectionView.alwaysBounceVertical = YES;
    
    //Register cells
    UINib *nib = [UINib nibWithNibName:kVStreamDirectoryItemCellName bundle:nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:kVStreamDirectoryItemCellName];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navHeaderView updateUI];
}

- (BOOL)prefersStatusBarHidden
{
    return !CGRectContainsRect(self.view.frame, self.navHeaderView.frame);
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)setStream:(VStream *)stream
{
    _stream = stream;
    if ([self isViewLoaded])
    {
        self.directoryDataSource.stream = stream;
        self.collectionView.dataSource = self.directoryDataSource;
    }
}

#pragma mark - Header

- (void)hideHeader
{
    if (!CGRectContainsRect(self.view.frame, self.navHeaderView.frame))
    {
        return;
    }
    
    self.headerYConstraint.constant = -self.navHeaderView.frame.size.height;
    [self.view layoutIfNeeded];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)showHeader
{
    if (CGRectContainsRect(self.view.frame, self.navHeaderView.frame))
    {
        return;
    }
    
    self.headerYConstraint.constant = 0;
    [self.view layoutIfNeeded];
    [self setNeedsStatusBarAppearanceUpdate];
}


- (void)backButtonPressed
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)menuButtonPressed
{
    [self.sideMenuViewController presentMenuViewController];
}

- (void)addButtonPressed
{
    
}

#pragma mark - Refresh
- (IBAction)refresh:(UIRefreshControl *)sender
{
    [self refreshWithCompletion:nil];
}

- (void)refreshWithCompletion:(void(^)(void))completionBlock
{
    [self.directoryDataSource refreshWithSuccess:^(void)
     {
         [self.refreshControl endRefreshing];
         if (completionBlock)
         {
             completionBlock();
         }
     }
                                     failure:^(NSError *error)
     {
         [self.refreshControl endRefreshing];
//         MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.superview animated:YES];
//         hud.mode = MBProgressHUDModeText;
//         hud.labelText = NSLocalizedString(@"RefreshError", @"");
//         hud.userInteractionEnabled = NO;
//         [hud hide:YES afterDelay:3.0];
     }];
    
    [self.refreshControl beginRefreshing];
    self.refreshControl.hidden = NO;
}

- (void)loadNextPageAction
{
    [self.directoryDataSource loadNextPageWithSuccess:^(void)
     {
     }
                                          failure:^(NSError *error)
     {
     }];
}



#pragma mark - CollectionViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint translation = [scrollView.panGestureRecognizer translationInView:scrollView.superview];
    
    if (translation.y < 0 && scrollView.contentOffset.y > CGRectGetHeight(self.navHeaderView.frame))
    {
        [UIView animateWithDuration:.2f animations:^
         {
             [self hideHeader];
         }];
    }
    else if (translation.y > 0)
    {
        [UIView animateWithDuration:.2f animations:^
         {
             [self showHeader];
         }];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    VStreamItem *item = [self.directoryDataSource itemAtIndexPath:indexPath];
    if ([item isKindOfClass:[VStream class]])
    {
        VStreamTableViewController *streamTable = [VStreamTableViewController streamWithDefaultStream:(VStream *)item name:item.name title:item.name];
        [self.navigationController pushViewController:streamTable animated:YES];
    }
    else if ([item isKindOfClass:[VSequence class]])
    {
        VContentViewController *contentViewController = [[VContentViewController alloc] init];
        contentViewController.sequence = (VSequence *)item;
        [self.navigationController pushViewController:contentViewController animated:YES];
    }
}

@end
