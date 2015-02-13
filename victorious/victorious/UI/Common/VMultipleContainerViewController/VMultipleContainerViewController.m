//
//  VMultipleContainerViewController.m
//  victorious
//
//  Created by Josh Hinman on 12/15/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "UIViewController+VLayoutInsets.h"
#import "VDependencyManager+VScaffoldViewController.h"
#import "VMultipleContainerViewController.h"
#import "VNavigationController.h"
#import "VSelectorViewBase.h"

@interface VMultipleContainerViewController () <UICollectionViewDataSource, UICollectionViewDelegate, VViewSelectorViewControllerDelegate>

@property (nonatomic, strong) VDependencyManager *dependencyManager;
@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) VSelectorViewBase *selector;
@property (nonatomic) BOOL didShowInitial;

@end

static NSString * const kCellReuseID = @"kCellReuseID";
static NSString * const kScreensKey = @"screens";
static NSString * const kSelectorKey =  @"selector";
static NSString * const kInitialKey = @"initial";

@implementation VMultipleContainerViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.extendedLayoutIncludesOpaqueBars = YES;
        _didShowInitial = NO;
    }
    return self;
}

#pragma mark VHasManagedDependencies conforming initializer

- (instancetype)initWithDependencyManager:(VDependencyManager *)dependencyManager
{
    self = [self initWithNibName:nil bundle:nil];
    if (self)
    {
        _dependencyManager = dependencyManager;
        _viewControllers = [dependencyManager arrayOfSingletonValuesOfType:[UIViewController class] forKey:kScreensKey];
        _selector = [[dependencyManager dependencyManagerForNavigationBar] singletonObjectOfType:[VSelectorViewBase class] forKey:kSelectorKey];
        _selector.viewControllers = _viewControllers;
        _selector.delegate = self;
        self.navigationItem.v_supplementaryHeaderView = _selector;
        self.title = [dependencyManager stringForKey:VDependencyManagerTitleKey];
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)loadView
{
    self.view = [[UIView alloc] init];
    
    self.flowLayout = [[UICollectionViewFlowLayout alloc] init];
    self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.flowLayout.sectionInset = UIEdgeInsetsZero;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.scrollEnabled = NO;
    collectionView.scrollsToTop = NO;
    [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kCellReuseID];
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(collectionView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(collectionView)]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ( !self.didShowInitial )
    {
        UIViewController *initialViewController = [self.dependencyManager singletonObjectOfType:[UIViewController class] forKey:kInitialKey];
        if ( initialViewController != nil )
        {
            NSUInteger index = [self.viewControllers indexOfObject:initialViewController];
        
            if ( index == NSNotFound )
            {
                index = 0;
            }
            [self displayViewControllerAtIndex:index animated:NO];
            [self.selector setActiveViewControllerIndex:index];
        }
        self.didShowInitial = YES;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    CGSize newItemSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), CGRectGetHeight(self.collectionView.bounds) - 1);
    if ( !CGSizeEqualToSize(newItemSize, self.flowLayout.itemSize) )
    {
        self.flowLayout.itemSize = newItemSize;
        [self displayViewControllerAtIndex:self.selector.activeViewControllerIndex animated:NO];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
    return NO;
}

#pragma mark - Properties

- (void)setViewControllers:(NSArray *)viewControllers
{
    _viewControllers = [viewControllers copy];
    self.selector.viewControllers = _viewControllers;
    [self.collectionView reloadData];
}

- (void)v_setLayoutInsets:(UIEdgeInsets)layoutInsets
{
    [super v_setLayoutInsets:layoutInsets];
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *obj, NSUInteger idx, BOOL *stop)
    {
        if ( [obj isKindOfClass:[UIViewController class]] )
        {
            obj.v_layoutInsets = layoutInsets;
        }
    }];
}

#pragma mark -

- (UIViewController *)viewControllerAtIndexPath:(NSIndexPath *)indexPath
{
    return self.viewControllers[indexPath.item];
}

- (void)displayViewControllerAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:animated];
    
    UIViewController *viewController = self.viewControllers[index];
    self.navigationItem.rightBarButtonItem = viewController.navigationItem.rightBarButtonItem;
}

#pragma mark - UICollectionViewDelegate methods

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *viewController = [self viewControllerAtIndexPath:indexPath];
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (NSInteger)self.viewControllers.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseID forIndexPath:indexPath];
    UIViewController *viewController = [self viewControllerAtIndexPath:indexPath];
    viewController.v_layoutInsets = self.v_layoutInsets;
    UIView *viewControllerView = viewController.view;
    
    [self addChildViewController:viewController];
    viewControllerView.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:viewControllerView];
    [viewController didMoveToParentViewController:self];
    
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[viewControllerView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(viewControllerView)]];
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[viewControllerView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(viewControllerView)]];
    return cell;
}

#pragma mark - VViewSelectorViewControllerDelegate methods

- (void)viewSelector:(VSelectorViewBase *)viewSelector didSelectViewControllerAtIndex:(NSUInteger)index
{
    [self displayViewControllerAtIndex:index animated:NO];
}

@end
