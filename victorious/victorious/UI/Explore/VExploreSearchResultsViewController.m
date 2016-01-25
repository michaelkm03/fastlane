//
//  VExploreSearchResultsViewController.m
//  victorious
//
//  Created by Tian Lan on 9/4/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VExploreSearchResultsViewController.h"
#import "victorious-Swift.h"

@interface VExploreSearchResultsViewController ()

@property (nonatomic, strong) NSString *lastSearchText;

@end

@implementation VExploreSearchResultsViewController

#pragma mark - Factory Methods

+ (instancetype)newWithDependencyManager:(VDependencyManager *)dependencyManager
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Explore" bundle:nil];
    VExploreSearchResultsViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"search"];
    viewController.dependencyManager = dependencyManager;
    return viewController;
}

@end
