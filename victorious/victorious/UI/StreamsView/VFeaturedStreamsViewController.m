//
//  VFeaturedStreamsViewController.m
//  victoriOS
//
//  Created by David Keegan on 12/19/13.
//  Copyright (c) 2013 Victorious, Inc. All rights reserved.
//

#import "VFeaturedStreamsViewController.h"
#import "VFeaturedViewController.h"
#import "VSequence+RestKit.h"
#import "VSequence+Fetcher.h"
#import "VConstants.h"

static NSString* kStreamCache = @"StreamCache";

@interface VFeaturedStreamsViewController ()
<NSFetchedResultsControllerDelegate, UIScrollViewDelegate>
@property (strong, nonatomic) NSFetchedResultsController* fetchedResultsController;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (strong) NSArray *viewControllers;
@end

@implementation VFeaturedStreamsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self performFetch];
}

- (void)performFetch
{
    NSManagedObjectContext *context = [RKObjectManager sharedManager].managedObjectStore.persistentStoreManagedObjectContext;
    [context performBlockAndWait:^()
     {
         NSError *error;
         if (![self.fetchedResultsController performFetch:&error] && error)
         {
             // Update to handle the error appropriately.
             NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
         }
         [self.superController.tableView reloadData];
     }];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    __block CGRect frame = self.scrollView.bounds;
    @synchronized(self.viewControllers)
    {
        [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop)
        {
            viewController.view.frame = frame;
            [self.scrollView addSubview:viewController.view];
            frame.origin.x += CGRectGetWidth(self.scrollView.bounds);
        }];
        self.scrollView.contentSize = CGSizeMake(CGRectGetMinX(frame), CGRectGetHeight(frame));
    };
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController
{
    if (nil == _fetchedResultsController)
    {
        RKObjectManager* manager = [RKObjectManager sharedManager];
        NSManagedObjectContext *context = manager.managedObjectStore.persistentStoreManagedObjectContext;

        NSFetchRequest *fetchRequest = [self fetchRequest];

        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                            managedObjectContext:context
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:kStreamCache];
        self.fetchedResultsController.delegate = self;
    }

    return _fetchedResultsController;
}

- (NSFetchRequest*)fetchRequest
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[VSequence entityName]];

    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"releasedAt" ascending:YES];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"category == %@", kFeaturedCategory]];
    [fetchRequest setSortDescriptors:@[sort]];
    [fetchRequest setFetchBatchSize:5];

    return fetchRequest;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    self.pageControl.currentPage = 0;
    self.pageControl.numberOfPages = [controller.fetchedObjects count] > 5 ? 5 : [controller.fetchedObjects count];

    NSMutableArray *viewControllers = [NSMutableArray arrayWithCapacity:self.pageControl.numberOfPages];
    for(NSUInteger i = 0; i < self.pageControl.numberOfPages && i < [controller.fetchedObjects count]; ++i)
    {
        VFeaturedViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:kFeaturedCategory];
        viewController.sequence = [controller objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        [self addChildViewController:viewController];
        [viewController didMoveToParentViewController:self];
        [viewControllers addObject:viewController];
    }
    self.viewControllers = [viewControllers copy];
    [self.view setNeedsLayout];
    [self.superController.tableView reloadData];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.pageControl.currentPage = round(scrollView.contentOffset.x/CGRectGetWidth(scrollView.bounds));
}

@end
