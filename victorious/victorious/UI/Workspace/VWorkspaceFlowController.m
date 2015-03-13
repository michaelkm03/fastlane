//
//  VWorkspaceFlowController.m
//  victorious
//
//  Created by Michael Sena on 1/15/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VWorkspaceFlowController.h"

// Dependency
#import "VDependencyManager.h"

// Constants
#import "VConstants.h"

// Tools
#import "VToolController.h"
#import "VImageToolController.h"
#import "VVideoToolController.h"

//TODO: Hackey
#import "VRootViewController.h"

// Category
#import "NSURL+MediaType.h"
#import "UIActionSheet+VBlocks.h"

// ViewControllers
#import "VCameraViewController.h"
#import "VWorkspaceViewController.h"
#import "VPublishViewController.h"

// Models
#import "VSequence+Fetcher.h"
#import "VNode+Fetcher.h"
#import "VAsset+Fetcher.h"
#import "VPublishParameters.h"

// Animators
#import "VPublishBlurOverAnimator.h"
#import "VVCameraShutterOverAnimator.h"
#import "VWorkspaceToWorkspaceAnimator.h"

// Here be dragons
#import <objc/runtime.h>

#import "UIAlertView+VBlocks.h"
#import "MBProgressHUD.h"

@import AssetsLibrary;

NSString * const VWorkspaceFlowControllerInitialCaptureStateKey = @"initialCaptureStateKey";
NSString * const VWorkspaceFlowControllerSequenceToRemixKey = @"sequenceToRemixKey";
NSString * const VWorkspaceFlowControllerPreloadedImageKey = @"preloadedImageKey";

static const char kAssociatedObjectKey;

typedef NS_ENUM(NSInteger, VWorkspaceFlowControllerState)
{
    VWorkspaceFlowControllerStateCapture,
    VWorkspaceFlowControllerStateEdit,
    VWorkspaceFlowControllerStatePublish
};

@interface VWorkspaceFlowController () <UINavigationControllerDelegate, VVideoToolControllerDelegate, VWorkspaceDelegate>

@property (nonatomic, assign) VWorkspaceFlowControllerState state;

@property (nonatomic, strong) NSURL *capturedMediaURL;
@property (nonatomic, strong) NSURL *renderedMeidaURL;

@property (nonatomic, strong, readwrite) UIImage *previewImage;

@property (nonatomic, strong) UINavigationController *flowNavigationController;

@property (nonatomic, weak) VCameraViewController *cameraViewController;

@property (nonatomic, strong) VPublishBlurOverAnimator *transitionAnimator;

@property (nonatomic, readonly) VDependencyManager *dependencyManager;

@end

@implementation VWorkspaceFlowController

+ (instancetype)workspaceFlowControllerWithoutADependencyMangerWithInjection:(NSDictionary *)injectedDependencies
{
    VDependencyManager *globalDependencyManager = [[VRootViewController rootViewController] dependencyManager];
    VWorkspaceFlowController *workspaceFlowController = [globalDependencyManager templateValueOfType:[VWorkspaceFlowController class]
                                                                                              forKey:VDependencyManagerWorkspaceFlowKey
                                                                               withAddedDependencies:injectedDependencies];
    return workspaceFlowController;
}

+ (instancetype)workspaceFlowControllerWithoutADependencyManger
{
    VDependencyManager *globalDependencyManager = [[VRootViewController rootViewController] dependencyManager];
    VWorkspaceFlowController *workspaceFlowController = [globalDependencyManager templateValueOfType:[VWorkspaceFlowController class]
                                                                                              forKey:VDependencyManagerWorkspaceFlowKey];
    return workspaceFlowController;
}

- (instancetype)initWithDependencyManager:(VDependencyManager *)dependencyManager
{
    self = [super init];
    if (self)
    {
        _dependencyManager = dependencyManager;
        _state = VWorkspaceFlowControllerStateCapture;
        _flowNavigationController = [[UINavigationController alloc] init];
        _flowNavigationController.navigationBarHidden = YES;
        _flowNavigationController.delegate = self;
        objc_setAssociatedObject(_flowNavigationController, &kAssociatedObjectKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        _transitionAnimator = [[VPublishBlurOverAnimator alloc] init];
        
        VSequence *sequenceToRemix = [dependencyManager templateValueOfType:[VSequence class] forKey:VWorkspaceFlowControllerSequenceToRemixKey];
        if (sequenceToRemix != nil)
        {
            [self extractCapturedMediaURLwithSequenceToRemix:sequenceToRemix];
            [self transitionFromState:_state
                              toState:VWorkspaceFlowControllerStateEdit];
        }
        else
        {
            [self setupCapture];
        }
        
    }
    return self;
}

- (void)transitionFromState:(VWorkspaceFlowControllerState)oldState
                    toState:(VWorkspaceFlowControllerState)newState
{
    __weak typeof(self) welf = self;
    
    if ((oldState == VWorkspaceFlowControllerStateCapture) && (newState == VWorkspaceFlowControllerStateEdit))
    {
        [self toEditState];
    }
    else if ((oldState == VWorkspaceFlowControllerStateEdit) && (newState == VWorkspaceFlowControllerStateCapture))
    {
        BOOL isRemix = [[self.flowNavigationController.viewControllers firstObject] isKindOfClass:[VWorkspaceViewController class]];
        if (isRemix)
        {
            [self notifyDelegateOfCancel];
        }
        else
        {
            [self.flowNavigationController popViewControllerAnimated:YES];
        }
    }
    else if ((oldState == VWorkspaceFlowControllerStateEdit) && (newState == VWorkspaceFlowControllerStatePublish))
    {
        NSAssert((self.renderedMeidaURL != nil), @"We need a rendered media url to begin publishing!");
        
        if ([self.delegate respondsToSelector:@selector(shouldShowPublishForWorkspaceFlowController:)])
        {
            BOOL shouldShowPublish = [self.delegate shouldShowPublishForWorkspaceFlowController:self];
            if (!shouldShowPublish)
            {
                [self notifyDelegateOfFinishWithPreviewImage:self.previewImage
                                            capturedMediaURL:self.renderedMeidaURL];
                return;
            }
        }
        
        VPublishParameters *publishParameters = [[VPublishParameters alloc] init];
        publishParameters.mediaToUploadURL = self.renderedMeidaURL;
        publishParameters.previewImage = self.previewImage;
        if ([[self.flowNavigationController topViewController] isKindOfClass:[VWorkspaceViewController class]])
        {
            VWorkspaceViewController *workspace = (VWorkspaceViewController *)[self.flowNavigationController topViewController];
            if ([workspace.toolController isKindOfClass:[VVideoToolController class]])
            {
                VVideoToolController *videoToolController = (VVideoToolController *)workspace.toolController;
                publishParameters.isGIF = videoToolController.isGIF;
                publishParameters.isVideo = YES;
                publishParameters.didTrim = videoToolController.didTrim;
            }
            else if ([workspace.toolController isKindOfClass:[VImageToolController class]])
            {
                VImageToolController *imageToolController = (VImageToolController *)workspace.toolController;
                publishParameters.embeddedText = imageToolController.embeddedText;
                publishParameters.textToolType = imageToolController.textToolType;
                publishParameters.filterName = imageToolController.filterName;
                publishParameters.didCrop = imageToolController.didCrop;
                publishParameters.isVideo = NO;
            }
        }
        VSequence *sequenceToRemix = [self.dependencyManager templateValueOfType:[VSequence class]
                                                                          forKey:VWorkspaceFlowControllerSequenceToRemixKey];
        if (sequenceToRemix)
        {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            formatter.numberStyle = NSNumberFormatterDecimalStyle;
            publishParameters.parentSequenceID = [formatter numberFromString:sequenceToRemix.remoteId];
            publishParameters.parentNodeID = [sequenceToRemix firstNode].remoteId;
        }
        VPublishViewController *publishViewController = [VPublishViewController newWithDependencyManager:self.dependencyManager];
        publishViewController.publishParameters = publishParameters;
        __weak typeof(VPublishViewController) *weakPublishViewController = publishViewController;
        publishViewController.completion = ^void(BOOL published)
        {
            if (publishParameters.shouldSaveToCameraRoll)
            {
                if ([welf.capturedMediaURL v_hasImageExtension])
                {
                    [welf writeImageToAssetsLibrary:publishParameters.previewImage];
                }
                else
                {
                    [welf writeVideoToAssetsLibrary:publishParameters.mediaToUploadURL];
                }
            }
            if (published)
            {
                __strong typeof (welf) strongSelf = welf;
                [strongSelf notifyDelegateOfFinishWithPreviewImage:strongSelf.previewImage
                                                  capturedMediaURL:strongSelf.renderedMeidaURL];
            }
            else
            {
                welf.renderedMeidaURL = nil;
                [welf transitionFromState:welf.state
                                  toState:VWorkspaceFlowControllerStateEdit];
            }
            weakPublishViewController.completion = nil;
        };
        [self.flowNavigationController pushViewController:publishViewController
                                                 animated:YES];
    }
    else if ((oldState == VWorkspaceFlowControllerStatePublish) && (newState == VWorkspaceFlowControllerStateEdit))
    {
        [self.flowNavigationController popViewControllerAnimated:YES];
        welf.previewImage = nil;
    }
    else
    {
        NSAssert(false, @"Not a valid transition");
    }
    self.state = newState;
}

#pragma mark - VNavigationDestination

- (BOOL)shouldNavigateWithAlternateDestination:(UIViewController *__autoreleasing *)alternateViewController
{
    VWorkspaceFlowController *newFlowController = [[VWorkspaceFlowController alloc] initWithDependencyManager:self.dependencyManager];
    [[VRootViewController rootViewController] presentViewController:newFlowController.flowRootViewController animated:YES completion:nil];
    return NO;
}

#pragma mark - Property Accessors

- (UIViewController *)flowRootViewController
{
    return self.flowNavigationController;
}

- (void)setVideoEnabled:(BOOL)videoEnabled
{
    if (_videoEnabled == videoEnabled)
    {
        return;
    }
    _videoEnabled = videoEnabled;
    
    if (_state == VWorkspaceFlowControllerStateCapture)
    {
        [self.flowNavigationController popViewControllerAnimated:NO];
        [self setupCapture];
    }
}

#pragma mark - Private Methods

- (void)setupCapture
{
    VWorkspaceFlowControllerInitialCaptureState initialCaptureState = VWorkspaceFlowControllerInitialCaptureStateImage;
    NSNumber *initialCaptureStateValue = [self.dependencyManager numberForKey:VWorkspaceFlowControllerInitialCaptureStateKey];
    initialCaptureState = (initialCaptureStateValue != nil) ? [initialCaptureStateValue integerValue] : initialCaptureState;
    
    switch (initialCaptureState)
    {
        case VWorkspaceFlowControllerInitialCaptureStateImage:
            if (self.isVideoEnabled)
            {
                self.cameraViewController = [VCameraViewController cameraViewControllerStartingWithStillCapture];
            }
            else
            {
                self.cameraViewController = [VCameraViewController cameraViewControllerLimitedToPhotos];
            }
            self.cameraViewController.shouldSkipPreview = YES;
            self.cameraViewController.completionBlock = [self mediaCaptureCompletion];
            [self.flowNavigationController pushViewController:self.cameraViewController animated:NO];
            break;
        case VWorkspaceFlowControllerInitialCaptureStateVideo:
            self.cameraViewController = [VCameraViewController cameraViewControllerStartingWithVideoCapture];
            self.cameraViewController.shouldSkipPreview = YES;
            self.cameraViewController.completionBlock = [self mediaCaptureCompletion];
            [self.flowNavigationController pushViewController:self.cameraViewController animated:NO];
            break;
    }
}

- (VMediaCaptureCompletion)mediaCaptureCompletion
{
    __weak typeof(self) welf = self;
    return ^void(BOOL finished, UIImage *previewImage, NSURL *capturedMediaURL)
    {
        __strong typeof(welf) strongSelf = welf;
        if (finished)
        {
            strongSelf.capturedMediaURL = capturedMediaURL;
            strongSelf.previewImage = previewImage;
            [strongSelf transitionFromState:strongSelf.state
                                    toState:VWorkspaceFlowControllerStateEdit];
        }
        else
        {
            [strongSelf notifyDelegateOfCancel];
        }
    };
}

- (void)extractCapturedMediaURLwithSequenceToRemix:(VSequence *)sequence
{
    if (sequence.isImage)
    {
        self.capturedMediaURL = [[[sequence firstNode] imageAsset] dataURL];
    }
    else if (sequence.isVideo)
    {
        self.capturedMediaURL = [[[sequence firstNode] mp4Asset] dataURL] ;
    }
}

- (void)toEditState
{
    VWorkspaceViewController *workspaceViewController;
    if ([self.capturedMediaURL v_hasImageExtension])
    {
        workspaceViewController = (VWorkspaceViewController *)[self.dependencyManager viewControllerForKey:VDependencyManagerImageWorkspaceKey];
        workspaceViewController.mediaURL = self.capturedMediaURL;
    }
    else if ([self.capturedMediaURL v_hasVideoExtension])
    {
        workspaceViewController = (VWorkspaceViewController *)[self.dependencyManager viewControllerForKey:VDependencyManagerVideoWorkspaceKey];
        workspaceViewController.mediaURL = self.capturedMediaURL;
        VVideoToolController *videoToolController = (VVideoToolController *)workspaceViewController.toolController;
        videoToolController.videoToolControllerDelegate = self;
        videoToolController.mediaURL = self.capturedMediaURL;
    }
    
    workspaceViewController.disabledToolbarWhileKeyboardIsVisible = YES;
    
    UIImage *preloadedImage = [self.dependencyManager imageForKey:VWorkspaceFlowControllerPreloadedImageKey];
    if (preloadedImage != nil)
    {
        workspaceViewController.previewImage = preloadedImage;
    }
    
    id remixItem = [self.dependencyManager templateValueOfType:[VSequence class] forKey:VWorkspaceFlowControllerSequenceToRemixKey];
    BOOL isRemix = (remixItem != nil);
    workspaceViewController.shouldConfirmCancels = !isRemix;
    workspaceViewController.delegate = self;
    
    BOOL selectedFromAssetsLibraryOrSearch = self.cameraViewController.didSelectFromWebSearch || self.cameraViewController.didSelectAssetFromLibrary;
    BOOL shouldShowPublish = YES;
    if ([self.delegate respondsToSelector:@selector(shouldShowPublishForWorkspaceFlowController:)])
    {
        shouldShowPublish = [self.delegate shouldShowPublishForWorkspaceFlowController:self];
    }
    workspaceViewController.continueText = shouldShowPublish ? NSLocalizedString(@"Publish", @"") : NSLocalizedString(@"Next", @"");

    [self.flowNavigationController pushViewController:workspaceViewController
                                             animated:!selectedFromAssetsLibraryOrSearch];

}

#pragma mark - Notify Delegate Methods

- (void)notifyDelegateOfCancel
{
    if (self.delegate != nil)
    {
        [self.delegate workspaceFlowControllerDidCancel:self];
    }
    else
    {
        [self.flowRootViewController dismissViewControllerAnimated:YES
                                                        completion:^
        {
            [self.flowNavigationController popToRootViewControllerAnimated:NO];
        }];
    }
    objc_setAssociatedObject(self.flowNavigationController, &kAssociatedObjectKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)notifyDelegateOfFinishWithPreviewImage:(UIImage *)previewImage
                              capturedMediaURL:(NSURL *)capturedMediaURL
{
    if (self.delegate != nil)
    {
        [self.delegate workspaceFlowController:self
                      finishedWithPreviewImage:previewImage
                              capturedMediaURL:capturedMediaURL];
    }
    else
    {
        [self.flowRootViewController dismissViewControllerAnimated:YES
                                                        completion:^
         {
             [self.flowNavigationController popToRootViewControllerAnimated:NO];
         }];
    }
    objc_setAssociatedObject(self.flowNavigationController, &kAssociatedObjectKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - UINavigationControllerDelegate

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC
{
    if ([fromVC isKindOfClass:[VCameraViewController class]] && [toVC isKindOfClass:[VWorkspaceViewController class]])
    {
        VCameraViewController *cameraViewController = (VCameraViewController *)fromVC;
        if (cameraViewController.didSelectAssetFromLibrary || cameraViewController.didSelectFromWebSearch)
        {
            return nil;
        }
        VVCameraShutterOverAnimator *animator = [[VVCameraShutterOverAnimator alloc] init];
        animator.presenting = (operation == UINavigationControllerOperationPush);
        return animator;
    }
    
    if ([toVC isKindOfClass:[VCameraViewController class]])
    {
        VCameraViewController *cameraViewController = (VCameraViewController *)toVC;
        [cameraViewController setToolbarHidden:NO];
        self.state = VWorkspaceFlowControllerStateCapture;
        return nil;
    }
    
    
    if ([fromVC isKindOfClass:[VWorkspaceViewController class]] && [toVC isKindOfClass:[VWorkspaceViewController class]])
    {
        return [[VWorkspaceToWorkspaceAnimator alloc] init];
    }
    
    if (![fromVC isKindOfClass:[VPublishViewController class]] && ![toVC isKindOfClass:[VPublishViewController class]])
    {
        return nil;
    }
    
    self.transitionAnimator.presenting = (operation == UINavigationControllerOperationPush) ? YES : NO;
    return self.transitionAnimator;
}

#pragma mark - Save To Camera Roll

- (void)writeVideoToAssetsLibrary:(NSURL *)videoURL
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:videoURL])
    {
        [library writeVideoAtPathToSavedPhotosAlbum:videoURL
                                    completionBlock:nil];
    }
}

- (void)writeImageToAssetsLibrary:(UIImage *)image
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library writeImageToSavedPhotosAlbum:image.CGImage
                              orientation:(NSInteger)image.imageOrientation
                          completionBlock:nil];
}

#pragma mark - VVideoToolControllerDelegate

- (void)videoToolController:(VVideoToolController *)videoToolController
 selectedSnapshotForEditing:(UIImage *)previewImage
        renderedSnapshotURL:(NSURL *)renderedMediaURL
{
    VWorkspaceViewController *imageWorkspaceViewController = (VWorkspaceViewController *)[self.dependencyManager templateValueOfType:[VWorkspaceViewController class]
                                                                                                                              forKey:VDependencyManagerImageWorkspaceKey
                                                                                                               withAddedDependencies:@{VImageToolControllerInitialImageEditStateKey:@(VImageToolControllerInitialImageEditStateText)}];
    imageWorkspaceViewController.mediaURL = renderedMediaURL;
    imageWorkspaceViewController.previewImage = previewImage;
    
    VImageToolController *imageToolController = (VImageToolController *)imageWorkspaceViewController.toolController;
    imageToolController.defaultImageTool = VImageToolControllerInitialImageEditStateText;
    
    imageWorkspaceViewController.continueText = NSLocalizedString(@"Publish", nil);
    imageWorkspaceViewController.delegate = self;
    [self.flowNavigationController pushViewController:imageWorkspaceViewController animated:YES];
}

#pragma mark - VWorkspaceDelegate

- (void)workspaceDidPublish:(VWorkspaceViewController *)workspaceViewController
{
    MBProgressHUD *hudForView = [MBProgressHUD showHUDAddedTo:workspaceViewController.view animated:YES];
    hudForView.labelText = NSLocalizedString(@"Rendering...", @"");
    
#warning Make sure to implement this in text workspace
    [[VTrackingManager sharedInstance] trackEvent:VTrackingEventUserDidFinishWorkspaceEdits];
    
    [workspaceViewController.toolController exportWithSourceAsset:workspaceViewController.mediaURL
                                withCompletion:^(BOOL finished, NSURL *renderedMediaURL, UIImage *previewImage, NSError *error)
     {
         [hudForView hide:YES];
         if (error != nil)
         {
             UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Render failure", @"")
                                                                  message:error.localizedDescription
                                                        cancelButtonTitle:NSLocalizedString(@"ok", @"")
                                                           onCancelButton:nil
                                               otherButtonTitlesAndBlocks:nil, nil];
             [errorAlert show];
         }
         else
         {
             self.renderedMeidaURL = renderedMediaURL;
             self.previewImage = previewImage;
             [self transitionFromState:self.state toState:VWorkspaceFlowControllerStatePublish];
         }
     }];
}

- (void)workspaceDidClose:(VWorkspaceViewController *)workspaceViewController
{
    if ( workspaceViewController.shouldConfirmCancels )
    {
        UIActionSheet *confirmExitActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"This will discard any content from the camera", @"")
                                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                                                      onCancelButton:nil
                                                              destructiveButtonTitle:NSLocalizedString(@"Discard", nil)
                                                                 onDestructiveButton:^
                                                 {
                                                     [self.flowNavigationController popViewControllerAnimated:YES];
                                                 }
                                                          otherButtonTitlesAndBlocks:nil, nil];
        [confirmExitActionSheet showInView:workspaceViewController.view];
    }
    else
    {
        [self.flowNavigationController popViewControllerAnimated:YES];
    }
}

@end
