//
//  VStreamViewController.h
//  victorious
//
//  Created by Gary Philipp on 1/16/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VFetchedResultsTableViewController.h"

#import "VCreatePollViewController.h"
#import "VAnimation.h"
#import "VSequenceFilter.h"

typedef NS_ENUM(NSInteger, VStreamScope)
{
    VStreamFilterAll = 0,
    VStreamFilterImages,
    VStreamFilterVideos,
    VStreamFilterPolls
};

@interface VStreamTableViewController : VFetchedResultsTableViewController <VAnimation, VCreateSequenceDelegate>

- (NSArray*)sequenceCategories;
- (VSequenceFilter*)currentFilter;

- (IBAction)showMenu;

@property (strong, nonatomic) NSArray* repositionedCells;;

@end
