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

#warning should remove me evenutally
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


@import AssetsLibrary;

NSString * const VWorkspaceFlowControllerInitialCaptureStateKey = @"initialCaptureStateKey";
NSString * const VWorkspaceFlowControllerSequenceToRemixKey = @"sequenceToRemixKey";
NSString * const VWorkspaceFlowControllerPreloadedImageKey = @"preloadedImageKey";

typedef NS_ENUM(NSInteger, VWorkspaceFlowControllerState)
{
    VWorkspaceFlowControllerStateCapture,
    VWorkspaceFlowControllerStateEdit,
    VWorkspaceFlowControllerStatePublish
};

@interface VWorkspaceFlowController () <UINavigationControllerDelegate>

@property (nonatomic, assign) VWorkspaceFlowControllerState state;

@property (nonatomic, strong) NSURL *capturedMediaURL;
@property (nonatomic, strong) NSURL *renderedMeidaURL;

@property (nonatomic, strong, readwrite) UIImage *previewImage;

@property (nonatomic, strong) UINavigationController *flowNavigationController;

@property (nonatomic, weak) VCameraViewController *cameraViewController;

@property (nonatomic, strong) VPublishBlurOverAnimator *transitionAnimator;

@property (nonatomic, assign) VImageToolControllerInitialImageEditState initialImageEditState;
@property (nonatomic, assign) VVideoToolControllerInitialVideoEditState initialVideoEditState;

@property (nonatomic, readonly) VDependencyManager *dependencyManager;

@end

@implementation VWorkspaceFlowController

+ (instancetype)workspaceFlowController
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
        _transitionAnimator = [[VPublishBlurOverAnimator alloc] init];
        
        _initialImageEditState = VImageToolControllerInitialImageEditStateText;
        NSNumber *initalImageEditStateValue = [dependencyManager numberForKey:VImageToolControllerInitialImageEditStateKey];
        if (initalImageEditStateValue != nil)
        {
            _initialImageEditState = [initalImageEditStateValue integerValue];
        }
        
        _initialVideoEditState = VVideoToolControllerInitialVideoEditStateGIF;
        NSNumber *initialVideoEditStateValue = [dependencyManager numberForKey:VVideoToolControllerInitalVideoEditStateKey];
        if (initialVideoEditStateValue != nil)
        {
            _initialVideoEditState = [initialVideoEditStateValue integerValue];
        }
        
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
            [self.delegate workspaceFlowControllerDidCancel:self];
        }
        else
        {
            [self.flowNavigationController popViewControllerAnimated:YES];
        }
    }
    else if ((oldState == VWorkspaceFlowControllerStateEdit) && (newState == VWorkspaceFlowControllerStatePublish))
    {
        NSAssert((self.renderedMeidaURL != nil), @"We need a rendered media url to begin publishing!");
        
        if ([self.delegate respondsToSelector:@selector(shouldShowPublishForWOrkspaceFlowController:)])
        {
            BOOL shouldShowPublish = [self.delegate shouldShowPublishForWOrkspaceFlowController:self];
            if (!shouldShowPublish)
            {
                [self.delegate workspaceFlowController:self
                              finishedWithPreviewImage:self.previewImage
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
                publishParameters.didTrim = videoToolController.didTrim;
            }
            else if ([workspace.toolController isKindOfClass:[VImageToolController class]])
            {
                VImageToolController *imageToolController = (VImageToolController *)workspace.toolController;
                publishParameters.embeddedText = imageToolController.embeddedText;
                publishParameters.textToolType = imageToolController.textToolType;
                publishParameters.filterName = imageToolController.filterName;
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
                [strongSelf.delegate workspaceFlowController:strongSelf
                                    finishedWithPreviewImage:strongSelf.previewImage
                                            capturedMediaURL:strongSelf.renderedMeidaURL];            }
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

#pragma mark - VFlowController

- (UIViewController *)flowRootViewController
{
    return self.flowNavigationController;
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
            self.cameraViewController = [VCameraViewController cameraViewControllerStartingWithStillCapture];
            break;
        case VWorkspaceFlowControllerInitialCaptureStateVideo:
            self.cameraViewController = [VCameraViewController cameraViewControllerStartingWithVideoCapture];
            break;
    }
    self.cameraViewController.shouldSkipPreview = YES;
    self.cameraViewController.completionBlock = [self mediaCaptureCompletion];
    [self.flowNavigationController pushViewController:self.cameraViewController
                                         animated:NO];
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
            [strongSelf.delegate workspaceFlowControllerDidCancel:strongSelf];
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
    NSAssert(self.capturedMediaURL != nil, @"We need a captured media url to begin editing!");
    
    __weak typeof(self) welf = self;
    VWorkspaceViewController *workspaceViewController;
    if ([self.capturedMediaURL v_hasImageExtension])
    {
        workspaceViewController = (VWorkspaceViewController *)[self.dependencyManager viewControllerForKey:VDependencyManagerImageWorkspaceKey];
        workspaceViewController.mediaURL = self.capturedMediaURL;
        ((VImageToolController *)workspaceViewController.toolController).defaultImageTool = self.initialImageEditState;
    }
    else if ([self.capturedMediaURL v_hasVideoExtension])
    {
        workspaceViewController = (VWorkspaceViewController *)[self.dependencyManager viewControllerForKey:VDependencyManagerVideoWorkspaceKey];
        workspaceViewController.mediaURL = self.capturedMediaURL;
        ((VVideoToolController *)workspaceViewController.toolController).defaultVideoTool = self.initialVideoEditState;
    }
    else
    {
        NSAssert(false, @"Media type not supported!");
    }
    
    UIImage *preloadedImage = [self.dependencyManager templateValueOfType:[UIImage class] forKey:VWorkspaceFlowControllerPreloadedImageKey];
    if (preloadedImage != nil)
    {
        workspaceViewController.previewImage = preloadedImage;
    }
    
    id remixItem = [self.dependencyManager templateValueOfType:[VSequence class] forKey:VWorkspaceFlowControllerSequenceToRemixKey];
    BOOL isRemix = (remixItem != nil);
    workspaceViewController.shouldConfirmCancels = !isRemix;
    
    workspaceViewController.completionBlock = ^void(BOOL finished, UIImage *previewImage, NSURL *renderedMediaURL)
    {
        if (finished)
        {
            welf.renderedMeidaURL = renderedMediaURL;
            welf.previewImage = previewImage;
            [welf transitionFromState:welf.state
                              toState:VWorkspaceFlowControllerStatePublish];
        }
        else
        {
            welf.capturedMediaURL = nil;
            [welf transitionFromState:welf.state
                              toState:VWorkspaceFlowControllerStateCapture];
        }
    };
    BOOL selectedFromAssetsLibraryOrSearch = self.cameraViewController.didSelectFromWebSearch || self.cameraViewController.didSelectAssetFromLibrary;
    BOOL shouldShowPublish = YES;
    if ([self.delegate respondsToSelector:@selector(shouldShowPublishForWOrkspaceFlowController:)])
    {
        shouldShowPublish = [self.delegate shouldShowPublishForWOrkspaceFlowController:self];
    }
    workspaceViewController.continueText = shouldShowPublish ? NSLocalizedString(@"Publish", @"") : NSLocalizedString(@"Next", @"");

    [self.flowNavigationController pushViewController:workspaceViewController
                                             animated:!selectedFromAssetsLibraryOrSearch];

}

#pragma mark - UINavigationControllerDelegate

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC
{
    if ([fromVC isKindOfClass:[VCameraViewController class]] && [toVC isKindOfClass:[VWorkspaceViewController class]])
    {
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

@end
