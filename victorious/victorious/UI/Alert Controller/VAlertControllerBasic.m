//
//  VAlertControllerBasic.m
//  victorious
//
//  Created by Patrick Lynch on 11/21/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VAlertControllerBasic.h"
#import "UIActionSheet+VBlocks.h"
#import "UIAlertView+VBlocks.h"

@interface VAlertControllerBasic ()

@property (nonatomic, strong) VAlertAction *cancelAction;
@property (nonatomic, strong) VAlertAction *destructiveAction;
@property (nonatomic, strong) NSMutableArray *defaultActions;
@property (nonatomic, readonly) UIAlertView *alertView;
@property (nonatomic, readonly) UIActionSheet *actionSheet;

@end

@implementation VAlertControllerBasic

#pragma mark - VAlertController overrides

- (void)addAction:(VAlertAction *)action
{
    switch (action.style)
    {
        case VAlertActionStyleDestructive:
            self.destructiveAction = action;
            break;
            
        case VAlertActionStyleCancel:
            self.cancelAction = action;
            break;
            
        case VAlertActionStyleDefault:
        default:
            if ( self.defaultActions == nil )
            {
                self.defaultActions = [[NSMutableArray alloc] init];
            }
            [self.defaultActions addObject:action];
            break;
    }
}

- (void)removeAllActions
{
    self.defaultActions = nil;
    self.cancelAction = nil;
    self.destructiveAction = nil;
}

- (void)presentInViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    if ( self.style == VAlertControllerStyleActionSheet )
    {
        NSParameterAssert( viewController != nil );
        NSParameterAssert( viewController.view != nil );
        [self.actionSheet showInView:viewController.view];
    }
    else if ( self.style == VAlertControllerStyleAlert )
    {
        [self.alertView show];
    }
}

#pragma mark - Helpers

- (UIActionSheet *)actionSheet
{
    BOOL isStyleValid = self.style == VAlertControllerStyleActionSheet;
    BOOL isContentValid = self.cancelAction != nil || self.destructiveAction != nil  || self.defaultActions.count > 0;
    NSParameterAssert( isStyleValid && isContentValid );
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:self.title
                                                    cancelButtonTitle:nil
                                                       onCancelButton:nil
                                               destructiveButtonTitle:nil
                                                  onDestructiveButton:nil
                                           otherButtonTitlesAndBlocks:nil];
    
    for ( VAlertAction *action in self.defaultActions )
    {
        [actionSheet addButtonWithTitle:action.title block:^void
         {
             [action execute];
         }];
    }
    
    if ( self.destructiveAction != nil )
    {
        actionSheet.destructiveButtonIndex = [actionSheet addButtonWithTitle:self.destructiveAction.title block:^void
                                              {
                                                  [self.destructiveAction execute];
                                              }];
    }
    
    if ( self.cancelAction != nil )
    {
        actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:self.cancelAction.title block:^void
                                         {
                                             [self.cancelAction execute];
                                         }];
    }
    
    return actionSheet;
}

- (UIAlertView *)alertView
{
    BOOL isStyleValid = self.style == VAlertControllerStyleAlert;
    BOOL isContentValid = self.cancelAction != nil || self.defaultActions.count > 0;
    NSParameterAssert( isStyleValid && isContentValid );
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:self.title
                                                        message:self.message
                                              cancelButtonTitle:self.cancelAction != nil ? self.cancelAction.title : nil
                                                 onCancelButton:^void
                              {
                                  if ( self.cancelAction != nil )
                                  {
                                      [self.cancelAction execute];
                                  }
                              }
                                     otherButtonTitlesAndBlocks:nil];
    
    for ( VAlertAction *action in self.defaultActions )
    {
        [alertView addButtonWithTitle:action.title block:^void
         {
             [action execute];
         }];
    }
    
    return alertView;
}

@end