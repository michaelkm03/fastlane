//
//  VStreamViewController.m
//  victorious
//
//  Created by Gary Philipp on 1/16/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VStreamTableViewController.h"
#import "UIViewController+VSideMenuViewController.h"
#import "VConstants.h"

#import "VCommentsContainerViewController.h"
#import "VContentViewController.h"

#import "NSString+VParseHelp.h"
#import "UIImageView+Blurring.h"
#import "UIImage+ImageCreation.h"

#import "VStreamContentSegue.h"
#import "VStreamTransitioningDelegate.h"

//Cells
#import "VStreamViewCell.h"
#import "VStreamPollCell.h"

//ObjectManager
#import "VObjectManager+Sequence.h"

//Data Models
#import "VSequence+RestKit.h"
#import "VSequence+Fetcher.h"
#import "VNode+Fetcher.h"
#import "VAsset.h"

#import "VThemeManager.h"

@interface VStreamTableViewController() <UIViewControllerTransitioningDelegate>
@property (strong, nonatomic) id<UIViewControllerTransitioningDelegate> transitionDelegate;

@property (strong, nonatomic) NSCache* preloadImageCache;
@end

@implementation VStreamTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.transitionDelegate = [[VStreamTransitioningDelegate alloc] init];
    
    self.tableView.backgroundColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVSecondaryAccentColor];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(willCommentSequence:)
     name:kStreamsWillCommentNotification object:nil];
    
    self.preloadImageCache = [[NSCache alloc] init];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    if ([self.fetchedResultsController.fetchedObjects count] < 5)
        [self refreshAction];
    else
        [self.tableView reloadData]; //force a reload incase anything has changed
    
    //Remove the search button from the stream - feature currently deprecated
    self.navigationItem.rightBarButtonItem = nil;

    CGRect navBarFrame = self.navigationController.navigationBar.frame;
    navBarFrame.size.height += navBarFrame.size.height;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.preloadImageCache removeAllObjects];
}

#pragma mark - FetchedResultsControllers
- (NSFetchedResultsController *)makeFetchedResultsController
{
    RKObjectManager* manager = [RKObjectManager sharedManager];
    NSManagedObjectContext *context = manager.managedObjectStore.persistentStoreManagedObjectContext;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[VSequence entityName]];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"releasedAt" ascending:NO];
    [fetchRequest setSortDescriptors:@[sort]];
    [fetchRequest setFetchBatchSize:50];
    
    return [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                               managedObjectContext:context
                                                 sectionNameKeyPath:nil
                                                          cacheName:fetchRequest.entityName];
}

- (NSFetchedResultsController *)makeSearchFetchedResultsController
{
    RKObjectManager* manager = [RKObjectManager sharedManager];
    NSManagedObjectContext *context = manager.managedObjectStore.persistentStoreManagedObjectContext;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[VSequence entityName]];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"releasedAt" ascending:NO];
    [fetchRequest setSortDescriptors:@[sort]];
    [fetchRequest setFetchBatchSize:50];
    
    return  [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                managedObjectContext:context
                                                  sectionNameKeyPath:nil
                                                           cacheName:kSearchCache];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    VSequence* sequence = ((VStreamViewCell*)cell).sequence;
    if (([sequence isForum] || [sequence isVideo])
        && [[[sequence firstNode] firstAsset].type isEqualToString:VConstantsMediaTypeYoutube])
    {
        //This will reload the youtube video so it stops playing
        //TODO: replace this with a pause control
        ((VStreamViewCell*)cell).sequence = ((VStreamViewCell*)cell).sequence;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    VStreamViewCell* cell = (VStreamViewCell*)[tableView cellForRowAtIndexPath:indexPath];
    
    UIImageView* newBackgroundView = [[UIImageView alloc] initWithFrame:self.tableView.backgroundView.frame];
    
    UIImage* placeholderImage = [UIImage resizeableImageWithColor:[[VThemeManager sharedThemeManager] themedColorForKey:kVBackgroundColor]];
    [newBackgroundView setLightBlurredImageWithURL:[[cell.sequence initialImageURLs] firstObject]
                                  placeholderImage:placeholderImage];
    
    self.tableView.backgroundView = newBackgroundView;
    if (tableView.contentOffset.y == cell.frame.origin.y - kContentMediaViewOffset)
    {
        [self performSegueWithIdentifier:kStreamContentSegueStoryboardID sender:cell];
    }
    else
    {
        [tableView setContentOffset:CGPointMake(cell.frame.origin.x, cell.frame.origin.y - kContentMediaViewOffset) animated:YES];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    VStreamViewCell* cell = (VStreamViewCell*)[self.tableView cellForRowAtIndexPath:self.tableView.indexPathForSelectedRow];
    if (cell)
    {
        [self performSegueWithIdentifier:kStreamContentSegueStoryboardID sender:cell];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint translation = [scrollView.panGestureRecognizer translationInView:scrollView.superview];
    CGRect navBarFrame = self.navigationController.navigationBar.frame;
    
    if (translation.y < 0 && CGRectContainsRect(self.view.frame, navBarFrame))
    {
        navBarFrame.origin.y = -navBarFrame.size.height;
    }
    else if (translation.y > 0 && !CGRectContainsRect(self.view.frame, navBarFrame))
    {
        navBarFrame.origin.y += navBarFrame.size.height;
    }
    else
    {
        return;
    }
    
    [UIView animateWithDuration:.5f animations:^
    {
        self.navigationController.navigationBar.frame = navBarFrame;
    }];
}

#pragma mark - Cells

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kStreamViewCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VSequence* sequence = (VSequence*)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSUInteger cellHeight;
    if ([sequence isPoll] && [[sequence firstNode] firstAsset])
        cellHeight = kStreamPollCellHeight;
    
    else if ([sequence isPoll])
        cellHeight = kStreamDoublePollCellHeight;
    
    else if (([sequence isVideo] ||[sequence isForum]) && [[[sequence firstNode] firstAsset].type isEqualToString:VConstantsMediaTypeYoutube])
        cellHeight = kStreamYoutubeCellHeight;
    
    else
        cellHeight = kStreamViewCellHeight;
    
    return cellHeight;
}

- (VStreamViewCell*)tableView:(UITableView *)tableView streamViewCellForIndex:(NSIndexPath*)indexPath
{
    VSequence* sequence = (VSequence*)[self.fetchedResultsController objectAtIndexPath:indexPath];

    if (([sequence isForum] || [sequence isVideo])
        && [[[sequence firstNode] firstAsset].type isEqualToString:VConstantsMediaTypeYoutube])
        return [tableView dequeueReusableCellWithIdentifier:kStreamYoutubeVideoCellIdentifier
                                               forIndexPath:indexPath];
    
    if ([sequence isPoll] && [[sequence firstNode] firstAsset])
        return [tableView dequeueReusableCellWithIdentifier:kStreamPollCellIdentifier
                                               forIndexPath:indexPath];

    else if ([sequence isPoll])
        return [tableView dequeueReusableCellWithIdentifier:kStreamDoublePollCellIdentifier
                                               forIndexPath:indexPath];

    else if ([sequence isForum] || [sequence isVideo])
        return [tableView dequeueReusableCellWithIdentifier:kStreamVideoCellIdentifier
                                               forIndexPath:indexPath];

    else
        return [tableView dequeueReusableCellWithIdentifier:kStreamViewCellIdentifier
                                               forIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VStreamViewCell *cell = [self tableView:tableView streamViewCellForIndex:indexPath];
    VSequence *info = [self.fetchedResultsController objectAtIndexPath:indexPath];
    ((VStreamViewCell*)cell).parentTableViewController = self;
    [((VStreamViewCell*)cell) setSequence:info];
    
    if ([self.fetchedResultsController.fetchedObjects count] > indexPath.row + 2)
    {
        NSIndexPath* preloadPath = [NSIndexPath indexPathForRow:indexPath.row + 2 inSection:indexPath.section];
        VSequence* preloadSequence = [self.fetchedResultsController objectAtIndexPath:preloadPath];
        
        for (NSURL* imageUrl in [preloadSequence initialImageURLs])
        {
            UIImageView* preloadView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
            [preloadView setImageWithURL:imageUrl];
            
            [self.preloadImageCache setObject:preloadView forKey:imageUrl.absoluteString];
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIView*     animatableContent = [(VTableViewCell *)cell mainView];
    
    animatableContent.layer.opacity = 0.1;
    
    [UIView animateWithDuration:0.5 animations:^{
        animatableContent.layer.opacity = 1.0;
    }];
}

- (void)registerCells
{
    [self.tableView registerNib:[UINib nibWithNibName:kStreamViewCellIdentifier bundle:nil]
         forCellReuseIdentifier:kStreamViewCellIdentifier];
    [self.searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:kStreamViewCellIdentifier bundle:nil] forCellReuseIdentifier:kStreamViewCellIdentifier];
    
    [self.tableView registerNib:[UINib nibWithNibName:kStreamYoutubeCellIdentifier bundle:nil]
         forCellReuseIdentifier:kStreamYoutubeCellIdentifier];
    [self.searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:kStreamYoutubeCellIdentifier bundle:nil] forCellReuseIdentifier:kStreamYoutubeCellIdentifier];
    
    [self.tableView registerNib:[UINib nibWithNibName:kStreamYoutubeVideoCellIdentifier bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:kStreamYoutubeVideoCellIdentifier];
    [self.searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:kStreamYoutubeVideoCellIdentifier bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kStreamYoutubeVideoCellIdentifier];
    
    [self.tableView registerNib:[UINib nibWithNibName:kStreamVideoCellIdentifier bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:kStreamVideoCellIdentifier];
    [self.searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:kStreamVideoCellIdentifier bundle:nil] forCellReuseIdentifier:kStreamVideoCellIdentifier];
    
    [self.tableView registerNib:[UINib nibWithNibName:kStreamPollCellIdentifier bundle:nil]
         forCellReuseIdentifier:kStreamPollCellIdentifier];
    [self.searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:kStreamPollCellIdentifier bundle:nil] forCellReuseIdentifier:kStreamPollCellIdentifier];
    
    [self.tableView registerNib:[UINib nibWithNibName:kStreamDoublePollCellIdentifier bundle:nil]
         forCellReuseIdentifier:kStreamDoublePollCellIdentifier];
    [self.searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:kStreamDoublePollCellIdentifier bundle:nil] forCellReuseIdentifier:kStreamDoublePollCellIdentifier];
}

#pragma mark - Refresh
- (void)refreshAction
{
    if (self.bottomRefreshIndicator.isAnimating)
        return;
    
    [self.bottomRefreshIndicator startAnimating];
    [self.refreshControl beginRefreshing];
    
    [[VObjectManager sharedManager] loadNextPageOfSequencesForCategory:nil
                                                          successBlock:^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
     {
         [self.refreshControl endRefreshing];
         [self.bottomRefreshIndicator stopAnimating];
         
     }
                                                             failBlock:^(NSOperation* operation, NSError* error)
     {
         [self.refreshControl endRefreshing];
         [self.bottomRefreshIndicator stopAnimating];
     }];
}

#pragma mark - Predicates
- (NSPredicate*)scopeTypePredicateForOption:(NSUInteger)searchOption
{
    NSMutableArray* allPredicates = [[NSMutableArray alloc] init];
    for (NSString* categoryName in [self categoriesForOption:searchOption])
    {
        [allPredicates addObject:[self categoryPredicateForString:categoryName]];
    }
    return [NSCompoundPredicate orPredicateWithSubpredicates:allPredicates];
}

- (NSPredicate*)categoryPredicateForString:(NSString*)categoryName
{
    //TODO: double check this, I think its wrong
    return [NSPredicate predicateWithFormat:@"category == %@", categoryName];
}

- (NSArray*)categoriesForOption:(NSUInteger)searchOption
{
    return nil;
}

#pragma mark - Actions
- (IBAction)showMenu
{
    [self.sideMenuViewController presentMenuViewController];
}

#pragma mark - Notifications

- (void)willCommentSequence:(NSNotification *)notification
{
    VStreamViewCell *cell = (VStreamViewCell *)notification.object;
    VCommentsContainerViewController* commentsTable = [VCommentsContainerViewController commentsContainerView];
    commentsTable.sequence = cell.sequence;
    [self.navigationController pushViewController:commentsTable animated:YES];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    ((VStreamTransitioningDelegate*)self.transitionDelegate).indexPathForSelectedCell = self.tableView.indexPathForSelectedRow;
    ((UIViewController*)segue.destinationViewController).transitioningDelegate = self.transitionDelegate;
    ((UIViewController*)segue.destinationViewController).modalPresentationStyle= UIModalPresentationCustom;

    if ([segue.identifier isEqualToString:kStreamContentSegueStoryboardID])
    {
        ((VStreamContentSegue*)segue).selectedCell = sender;
        VContentViewController* contentVC = segue.destinationViewController;
        contentVC.sequence = ((VStreamViewCell*)sender).sequence;
    }
}

- (IBAction)unwindToStreamTable:(UIStoryboardSegue*)sender
{
    
}

@end
