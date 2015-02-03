//
//  VSearchResultsTransition.m
//  victorious
//
//  Created by Lawrence Leach on 2/2/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VSearchResultsTransition.h"
#import "VUsersAndTagsSearchViewController.h"
#import "VSearchResultsNavigationController.h"

const static CGFloat kStartTopOffset = 55.0f;
const static CGFloat kStatusBarOffset = 20.0f;

@implementation VSearchResultsTransition

- (void)prepareForTransitionIn:(VTransitionModel *)model
{
    VSearchResultsNavigationController *toViewController = (VSearchResultsNavigationController *)model.toViewController;
    
    toViewController.usersAndTagsSearchViewController.searchResultsContainerView.alpha = 0.0f;
    toViewController.usersAndTagsSearchViewController.searchBarTopConstraint.constant = kStartTopOffset;
    toViewController.usersAndTagsSearchViewController.headerTopConstraint.constant = -toViewController.usersAndTagsSearchViewController.searchBarViewHeightConstraint.constant;
    
    
    [toViewController.usersAndTagsSearchViewController.searchBarTopConstraint.firstItem layoutIfNeeded];
    [toViewController.usersAndTagsSearchViewController.headerTopConstraint.firstItem layoutIfNeeded];
    [toViewController.usersAndTagsSearchViewController.searchResultsTableBottomCosntraint.firstItem layoutIfNeeded];
    [toViewController.usersAndTagsSearchViewController.view layoutIfNeeded];
}

- (void)performTransitionIn:(VTransitionModel *)model completion:(void (^)(BOOL))completion
{
    VSearchResultsNavigationController *toViewController = (VSearchResultsNavigationController *)model.toViewController;
    [UIView animateWithDuration:model.animationDuration
                          delay:0.0f
         usingSpringWithDamping:0.9f
          initialSpringVelocity:0.1f
                        options:kNilOptions
                     animations:^
     {
         toViewController.usersAndTagsSearchViewController.searchBarTopConstraint.constant = 0.0f;
         toViewController.usersAndTagsSearchViewController.headerTopConstraint.constant = 0.0f;
         toViewController.usersAndTagsSearchViewController.searchResultsContainerView.alpha = 1.0f;
         
         [toViewController.usersAndTagsSearchViewController.searchBarTopConstraint.firstItem layoutIfNeeded];
         [toViewController.usersAndTagsSearchViewController.headerTopConstraint.firstItem layoutIfNeeded];
         [toViewController.usersAndTagsSearchViewController.searchResultsTableBottomCosntraint.firstItem layoutIfNeeded];
         [toViewController.usersAndTagsSearchViewController.view layoutIfNeeded];
    }
                     completion:^(BOOL finished)
    {
        completion( YES );
    }];
}

- (void)prepareForTransitionOut:(VTransitionModel *)model
{
    VSearchResultsNavigationController *fromViewController = (VSearchResultsNavigationController *)model.fromViewController;
    
    fromViewController.usersAndTagsSearchViewController.searchResultsContainerView.alpha = 1.0f;
    fromViewController.usersAndTagsSearchViewController.searchBarTopConstraint.constant -= kStatusBarOffset;
    
    [fromViewController.usersAndTagsSearchViewController.searchBarTopConstraint.firstItem layoutIfNeeded];
    [fromViewController.usersAndTagsSearchViewController.headerTopConstraint.firstItem layoutIfNeeded];
    [fromViewController.usersAndTagsSearchViewController.searchResultsTableBottomCosntraint.firstItem layoutIfNeeded];
    [fromViewController.usersAndTagsSearchViewController.view layoutIfNeeded];
}

- (void)performTransitionOut:(VTransitionModel *)model completion:(void (^)(BOOL))completion
{
    VSearchResultsNavigationController *fromViewController = (VSearchResultsNavigationController *)model.fromViewController;
    
    [UIView animateWithDuration:model.animationDuration
                          delay:0.0f
         usingSpringWithDamping:0.9f
          initialSpringVelocity:0.1f
                        options:kNilOptions
                     animations:^
     {
         fromViewController.usersAndTagsSearchViewController.searchResultsContainerView.alpha = 0.0f;
         fromViewController.usersAndTagsSearchViewController.searchBarTopConstraint.constant = kStartTopOffset - kStatusBarOffset;
         fromViewController.usersAndTagsSearchViewController.headerTopConstraint.constant = -fromViewController.usersAndTagsSearchViewController.searchBarViewHeightConstraint.constant;
         
         [fromViewController.usersAndTagsSearchViewController.searchBarTopConstraint.firstItem layoutIfNeeded];
         [fromViewController.usersAndTagsSearchViewController.headerTopConstraint.firstItem layoutIfNeeded];
         [fromViewController.usersAndTagsSearchViewController.searchResultsTableBottomCosntraint.firstItem layoutIfNeeded];
         [fromViewController.usersAndTagsSearchViewController.view layoutIfNeeded];
     }
                     completion:^(BOOL finished)
     {
         completion( YES );
     }];
}

- (BOOL)requiresImageViewFromOriginViewController
{
    return YES;
}

- (NSTimeInterval)transitionInDuration
{
    return 0.5f;
}

- (NSTimeInterval)transitionOutDuration
{
    return 0.5;
}

@end
