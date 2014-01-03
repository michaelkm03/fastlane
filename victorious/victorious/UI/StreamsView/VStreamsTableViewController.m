//
//  VStreamsTableViewController.m
//  victoriOS
//
//  Created by goWorld on 12/2/13.
//  Copyright (c) 2013 Victorious Inc. All rights reserved.
//

#import "VStreamsTableViewController.h"
#import "VStreamsSubViewController.h"
#import "VSequence.h"
#import "NSString+VParseHelp.h"
#import "UIImageView+AFNetworking.h"
#import "VObjectManager+Sequence.h"
#import "VFeaturedStreamsViewController.h"

#import "VStreamViewCell.h"
#import "VStreamVideoCell.h"
#import "VStreamPollCell.h"

#import "VMenuViewController.h"
#import "VMenuViewControllerTransition.h"

#import "VAddActionViewController.h"
#import "VActionViewControllerTransition.h"

typedef NS_ENUM(NSInteger, VStreamScope)
{
    VStreamFilterAll = 0,
    VStreamFilterImages,
    VStreamFilterVideos,
    VStreamFilterVideoForums,
    VStreamFilterPolls
};

@interface VStreamsTableViewController ()   <NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate>
@property (nonatomic, strong) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController* searchFetchedResultsController;
@property (nonatomic) VStreamScope scopeType;
@property (strong, nonatomic) NSString* filterText;
@property (nonatomic, strong) VFeaturedStreamsViewController* featuredStreamsViewController;
@end

static NSString* kStreamCache = @"StreamCache";
static NSString* kSearchCache = @"SearchCache";

@implementation VStreamsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        // Custom initialization
        _scopeType = VStreamFilterAll;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.featuredStreamsViewController =   [self.storyboard instantiateViewControllerWithIdentifier:@"featured_pages"];

    UIBarButtonItem *searchButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Search"] style:UIBarButtonItemStylePlain target:self action:@selector(displaySearchBar:)];
    UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Add"] style:UIBarButtonItemStylePlain target:self action:@selector(addButtonAction:)];
    self.navigationItem.rightBarButtonItems= @[addButtonItem, searchButtonItem];

    [self registerCells];
    
    NSError *error;
	if (![self.fetchedResultsController performFetch:&error])
    {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
}

- (void)viewWillAppear:(BOOL)animated
{    
    // scroll the search bar off-screen
    CGRect newBounds = self.tableView.bounds;
    newBounds.origin.y = newBounds.origin.y + self.searchDisplayController.searchBar.bounds.size.height;
    self.tableView.bounds = newBounds;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.fetchedResultsController = nil;
}

- (IBAction)refresh:(UIRefreshControl *)sender
{
    SuccessBlock success = ^(NSArray* resultObjects)
    {
        NSError *error;
        if (![self.fetchedResultsController performFetch:&error])
        {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);  // Fail
        }
        
        [self.refreshControl endRefreshing];
    };
    
    FailBlock fail = ^(NSError* error)
    {
        [self.refreshControl endRefreshing];
        VLog(@"Error on loadNextPage: %@", error);
    };
    
    [[[VObjectManager sharedManager] loadNextPageOfSequencesForCategory:[[VCategory findAllObjects] firstObject]
                                                           successBlock:success
                                                              failBlock:fail] start];
}

- (void)registerCells
{
    [self.tableView registerNib:[UINib nibWithNibName:@"VStreamViewCell" bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:kStreamViewCellIdentifier];
    [self.searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:@"VStreamViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kStreamViewCellIdentifier];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"VStreamVideoCell" bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:kStreamVideoCellIdentifier];
    [self.searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:@"VStreamVideoCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kStreamVideoCellIdentifier];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"VStreamPollCell" bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:kStreamPollCellIdentifier];
    [self.searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:@"VStreamPollCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kStreamPollCellIdentifier];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"VStreamDoublePollCell" bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:kStreamDoublePollCellIdentifier];
    [self.searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:@"VStreamDoublePollCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kStreamDoublePollCellIdentifier];
}

- (IBAction)addButtonAction:(id)sender{
    VAddActionViewController *viewController =
    [self.storyboard instantiateViewControllerWithIdentifier:@"add_action"];
    viewController.transitioningDelegate =
    (id <UIViewControllerTransitioningDelegate>)[VActionViewControllerTransitionDelegate new];
    viewController.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:viewController animated:YES completion:nil];
}

#pragma mark - Table view data source

//The follow 2 methods and the majority of the rest of the file was based on the following stack overflow article:
//http://stackoverflow.com/questions/4471289/how-to-filter-nsfetchedresultscontroller-coredata-with-uisearchdisplaycontroll

- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)tableView
{
    return tableView == self.tableView ? self.fetchedResultsController : self.searchFetchedResultsController;
}


- (UITableView*)tableViewForFetchedResultsController:(NSFetchedResultsController*)controller
{
    return controller == self.fetchedResultsController ? self.tableView
                            : self.searchDisplayController.searchResultsTableView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[[self fetchedResultsControllerForTableView:tableView] sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id  sectionInfo = [[[self fetchedResultsControllerForTableView:tableView] sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void)configureCell:(VStreamViewCell *)theCell atIndexPath:(NSIndexPath *)theIndexPath
    forFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController
{
    VSequence *info = [fetchedResultsController objectAtIndexPath:theIndexPath];
    [theCell setSequence:info];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VSequence* sequence = (VSequence*)[[self fetchedResultsControllerForTableView:tableView] objectAtIndexPath:indexPath];
    
    if ([sequence.category isEqualToString:@"video_forum"] ||
        [sequence.category isEqualToString:@"owner_poll"])
        
        return 240;

    return 450;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VSequence* sequence = (VSequence*)[[self fetchedResultsControllerForTableView:tableView] objectAtIndexPath:indexPath];
    
    VStreamViewCell *cell;
    if ([sequence.category isEqualToString:@"video_forum"])
        cell = [tableView dequeueReusableCellWithIdentifier:kStreamVideoCellIdentifier
                                               forIndexPath:indexPath];
    
    else if ([sequence.category isEqualToString:@"owner_poll"])
        cell = [tableView dequeueReusableCellWithIdentifier:kStreamPollCellIdentifier
                                               forIndexPath:indexPath];

    else
        cell = [tableView dequeueReusableCellWithIdentifier:kStreamViewCellIdentifier
                                               forIndexPath:indexPath];
    // Configure the cell...
    [self configureCell:cell atIndexPath:indexPath
        forFetchedResultsController:[self fetchedResultsControllerForTableView:tableView]];

    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 120;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), [self tableView:tableView heightForHeaderInSection:section]);
    UIView* containerView = [[UIView alloc] initWithFrame:frame];

    [self addChildViewController:self.featuredStreamsViewController];
    [containerView addSubview:self.featuredStreamsViewController.view];
    [self.featuredStreamsViewController didMoveToParentViewController:self];
    self.featuredStreamsViewController.view.frame = frame;

    return containerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier: @"toStreamDetails"
                              sender: [tableView cellForRowAtIndexPath:indexPath]];
}

#pragma mark - NSFetchedResultsControllers

- (NSFetchedResultsController *)fetchedResultsController
{
    if (nil == _fetchedResultsController)
    {
        RKObjectManager* manager = [RKObjectManager sharedManager];
        NSManagedObjectContext *context = manager.managedObjectStore.persistentStoreManagedObjectContext;
        
        NSFetchRequest *fetchRequest = [self fetchRequestForContext:context];
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                            managedObjectContext:context
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:kStreamCache];
        self.fetchedResultsController.delegate = self;
    }
    
    return _fetchedResultsController;
}

- (NSFetchedResultsController *)searchFetchedResultsController
{
    if (nil == _searchFetchedResultsController)
    {
        RKObjectManager* manager = [RKObjectManager sharedManager];
        NSManagedObjectContext *context = manager.managedObjectStore.persistentStoreManagedObjectContext;
        
        NSFetchRequest *fetchRequest = [self fetchRequestForContext:context];
        
        self.searchFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                            managedObjectContext:context
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:kSearchCache];
        self.searchFetchedResultsController.delegate = self;
    }
    
    return _searchFetchedResultsController;
}

- (NSFetchRequest*)fetchRequestForContext:(NSManagedObjectContext*)context
{
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[VSequence entityName] inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"display_order" ascending:YES];
    [fetchRequest setSortDescriptors:@[sort]];
    [fetchRequest setFetchBatchSize:50];
    
    return fetchRequest;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [[self tableViewForFetchedResultsController:controller] beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = [self tableViewForFetchedResultsController:controller];
    
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(VStreamViewCell*)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath forFetchedResultsController:[self fetchedResultsControllerForTableView:tableView]];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [[self tableViewForFetchedResultsController:controller] endUpdates];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    //This relies on the scope buttons being in the same order as the VStreamScope enum
    _scopeType = selectedScope;
    [self refreshFetchController:_searchFetchedResultsController
                   withPredicate:[self fetchResultsPredicate]];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    _filterText = searchText;
    
    [self refreshFetchController:_searchFetchedResultsController
                   withPredicate:[self fetchResultsPredicate]];
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [self refreshFetchController:_fetchedResultsController
                   withPredicate:[self fetchResultsPredicate]];
}

#pragma mark - Search Display

- (IBAction)displaySearchBar:(id)sender
{
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    
    NSTimeInterval delay;
    if (self.tableView.contentOffset.y >1000)
        delay = 0.4;
    else
        delay = 0.1;
    [self performSelector:@selector(activateSearch) withObject:nil afterDelay:delay];
}

- (void)activateSearch
{
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    [self.searchDisplayController.searchBar becomeFirstResponder];
    [self refreshFetchController:_searchFetchedResultsController
                   withPredicate:[self fetchResultsPredicate]];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self viewWillAppear:YES];
}

#pragma mark - Filtering

- (NSPredicate*)fetchResultsPredicate
{
    NSMutableArray* allFilters = [[NSMutableArray alloc] init];
    //Type filter
    switch (_scopeType)
    {
        case VStreamFilterVideoForums:
            [allFilters addObject:[NSPredicate predicateWithFormat:@"category == 'video_forum'"]];
            break;
            
        case VStreamFilterPolls:
            [allFilters addObject:[NSPredicate predicateWithFormat:@"category == 'owner_poll'"]];
            break;
            
        case VStreamFilterImages:
            [allFilters addObject:[NSPredicate predicateWithFormat:@"category == 'owner_image'"]];
            break;
            
        case VStreamFilterVideos:
            [allFilters addObject:[NSPredicate predicateWithFormat:@"category == 'video'"]];
            break;
            
        default:
            [allFilters addObject:[self defaultTypePredicate]];
            break;
    }
    
    //Search text filter
    if (_filterText && ![_filterText isEmpty])
    {
        [allFilters addObject:[NSPredicate predicateWithFormat:@"SELF.name CONTAINS[cd] %@", _filterText]];
    }
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:allFilters];
}

- (void)refreshFetchController:(NSFetchedResultsController*)controller
                 withPredicate:(NSPredicate*)predicate
{
    //We must clear the cache before modifying anything.
    NSString* cacheName = (controller == _fetchedResultsController) ? kStreamCache : kSearchCache;
    [NSFetchedResultsController deleteCacheWithName:cacheName];
    
    [controller.fetchRequest setPredicate:predicate];
    
    //We need to perform the fetch again
    NSError *error;
	if (![controller performFetch:&error])
    {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
    
    //Then reload the data
    [[self tableViewForFetchedResultsController:controller] reloadData];
}

- (NSPredicate*)defaultTypePredicate
{
    return [NSPredicate predicateWithFormat:@"category == 'video_forum' || category == 'owner_poll' || category == 'owner_image' || category == 'video'"];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[VMenuViewController class]])
    {
        VMenuViewController *menuViewController = segue.destinationViewController;
        menuViewController.transitioningDelegate =
        (id <UIViewControllerTransitioningDelegate>)[VMenuViewControllerTransitionDelegate new];
        menuViewController.modalPresentationStyle = UIModalPresentationCustom;
    } else if ([segue.identifier isEqualToString:@"toStreamDetails"])
    {
        VStreamsSubViewController *subview = (VStreamsSubViewController *)segue.destinationViewController;
        
        VSequence *sequence = [_fetchedResultsController objectAtIndexPath:[self.tableView indexPathForCell:(UITableViewCell*)sender]];
        
        subview.sequence = sequence;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kStreamsWillSegueNotification
                                                        object:nil];
    [super viewWillDisappear:animated];
}

#pragma mark - VAddActionViewControllerDelegate

- (void)addActionViewController:(VAddActionViewController *)viewController didChooseAction:(VAddActionViewControllerType)action{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
