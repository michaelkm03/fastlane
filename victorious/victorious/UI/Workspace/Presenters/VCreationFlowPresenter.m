//
//  VCreationFlowPresenter.m
//  victorious
//
//  Created by Michael Sena on 3/10/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VCreationFlowPresenter.h"

// Dependencies
#import "VDependencyManager.h"
#import "VCreationFlowShim.h"

// API
#import "VObjectManager+Users.h"

// Creation UI
#import "VCreationFlowController.h"

#warning Maybe delete these
//#import "VWorkspaceFlowController.h"
#import "VCreatePollViewController.h"
#import "VTextWorkspaceFlowController.h"
#import "VImageToolController.h"
#import "VVideoToolController.h"

// Action sheet
#import "VAlertController.h"
#import "VCreateSheetViewController.h"

// Tracking
#import "VTrackingManager.h"

static NSString * const kCreateSheetKey = @"createSheet";
static NSString * const kCreationFlowKey = @"createFlow";
static NSString * const kImageCreationFlowKey = @"imageCreateFlow";
static NSString * const kGIFCreationFlowKey = @"gifCreateFlow";
static NSString * const kVideoCreateFlow = @"videoCreateFlow";
static NSString * const kPollCreateFlow = @"pollCreateFlow";
static NSString * const kTextCreateFlow = @"textCreateFlow";

@interface VCreationFlowPresenter () <VCreationFlowControllerDelegate>

//@property (nonatomic, strong) VCreationFlowShim *creationFlowShim;

@end

@implementation VCreationFlowPresenter

- (instancetype)initWithViewControllerToPresentOn:(UIViewController *)viewControllerToPresentOn dependencymanager:(VDependencyManager *)dependencyManager
{
    self = [super initWithViewControllerToPresentOn:viewControllerToPresentOn
                                  dependencymanager:dependencyManager];
    if (self != nil)
    {
//        _creationFlowShim = [dependencyManager templateValueOfType:[VCreationFlowShim class]
//                                                           forKey:kCreationFlowKey];
    }
    return self;
}

- (void)present
{
    NSDictionary *addedDependencies = @{kAnimateFromTopKey : @(self.showsCreationSheetFromTop)};

    VCreateSheetViewController *createSheet = [self.dependencyManager templateValueOfType:[VCreateSheetViewController class] forKey:kCreateSheetKey withAddedDependencies:addedDependencies];
    
    if (createSheet != nil)
    {
        [createSheet setCompletionHandler:^(VCreateSheetViewController *createSheetViewController, VCreationType chosenItemIdentifier)
         {
             [createSheetViewController dismissViewControllerAnimated:YES completion:^
              {
                  [self openWorkspaceWithItemIdentifier:chosenItemIdentifier];
              }];
             
         }];
        [self.viewControllerToPresentOn presentViewController:createSheet animated:YES completion:nil];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:NSLocalizedString(@"GenericFailMessage", @"")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self.viewControllerToPresentOn presentViewController:alert animated:YES completion:nil];
    }
}

- (void)openWorkspaceWithItemIdentifier:(VCreationType)identifier
{
    switch (identifier)
    {
        case VCreationTypeImage:
            [[VTrackingManager sharedInstance] trackEvent:VTrackingEventCreateImagePostSelected];
            [self presentCreateFlowWithKey:kImageCreationFlowKey];
            break;
        case VCreationTypeVideo:
            [[VTrackingManager sharedInstance] trackEvent:VTrackingEventCreateVideoPostSelected];
            [self presentCreateFlowWithKey:kVideoCreateFlow];
//            [self presentCreateFlowWithInitialCaptureState:VWorkspaceFlowControllerInitialCaptureStateVideo];
            break;
        case VCreationTypeText:
            [[VTrackingManager sharedInstance] trackEvent:VTrackingEventCreateTextOnlyPostSelected];
            [self presentTextOnlyWorkspace];
            break;
        case VCreationTypeGIF:
            [[VTrackingManager sharedInstance] trackEvent:VTrackingEventCreateGIFPostSelected];
#warning Set this to GIF
            [self presentCreateFlowWithKey:kGIFCreationFlowKey];
            
            break;
        case VCreationTypePoll:
        {
            [[VTrackingManager sharedInstance] trackEvent:VTrackingEventCreatePollSelected];
//            VCreatePollViewController *createViewController = [self.creationFlowShim pollFlowController];
            __weak typeof(self) welf = self;
//            createViewController.completionHandler = ^void(VCreatePollViewControllerResult result)
//            {
//                [welf.viewControllerToPresentOn dismissViewControllerAnimated:YES
//                                                                   completion:nil];
//            };
//            UINavigationController *wrapperNavStack = [[UINavigationController alloc] initWithRootViewController:createViewController];
//            [self.viewControllerToPresentOn presentViewController:wrapperNavStack animated:YES completion:nil];
            break;
        }
        case VCreationTypeUnknown:
            break;
    }
}

- (void)presentCreateFlowWithKey:(NSString *)key
{
    [[VTrackingManager sharedInstance] setValue:VTrackingValueCreatePost forSessionParameterWithKey:VTrackingKeyContext];
    
    VCreationFlowController *flowController = [self.dependencyManager templateValueOfType:[VCreationFlowController class]
                                                                                                  forKey:key];
    flowController.creationFlowDelegate = self;
    [self.viewControllerToPresentOn presentViewController:flowController
                                                 animated:YES
                                               completion:nil];
}

- (void)presentTextOnlyWorkspace
{
//    VTextWorkspaceFlowController *textWorkspaceController = [self.creationFlowShim textFlowController];
//    [self.viewControllerToPresentOn presentViewController:textWorkspaceController.flowRootViewController animated:YES completion:nil];
}

#pragma mark - VCreationFlowController

- (void)creationFLowController:(VCreationFlowController *)creationFlowController
      finishedWithPreviewImage:(UIImage *)previewImage
              capturedMediaURL:(NSURL *)capturedMediaURL
{
    [self.viewControllerToPresentOn dismissViewControllerAnimated:YES completion:nil];
}

@end
