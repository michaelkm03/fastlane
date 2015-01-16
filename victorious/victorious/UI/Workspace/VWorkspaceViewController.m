//
//  VWorkspaceViewController.m
//  victorious
//
//  Created by Michael Sena on 12/2/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VWorkspaceViewController.h"

// Dependency Management
#import "VDependencyManager+VWorkspaceTool.h"

// Views
#import "VCanvasView.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "UIImageView+Blurring.h"

// Keyboard
#import "VKeyboardManager.h"

// Protocols
#import "VWorkspaceTool.h"

// Rendering Utilities
#import "CIImage+VImage.h"

// Constants
#import "VConstants.h"

#warning just for testing
#import "VObjectManager+ContentCreation.h"

// Video
#import "VVideoWorkspaceTool.h"
#import "VVideoPlayerView.h"

@import AVFoundation;

static const CGFloat kJPEGCompressionQuality    = 0.8f;

@interface VWorkspaceViewController ()

@property (nonatomic, strong, readwrite) NSURL *renderedMediaURL;

@property (nonatomic, strong) VDependencyManager *dependencyManager;
@property (nonatomic, strong) NSArray *tools;

@property (nonatomic, weak) IBOutlet UIToolbar *topToolbar;
@property (nonatomic, weak) IBOutlet UIToolbar *bottomToolbar;
@property (nonatomic, weak) IBOutlet VCanvasView *canvasView;
@property (nonatomic, weak) IBOutlet UIImageView *blurredBackgroundImageVIew;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *verticalSpaceCanvasToTopOfContainerConstraint;
@property (nonatomic, strong) NSMutableArray *inspectorConstraints;

@property (nonatomic, strong) id <VWorkspaceTool> selectedTool;
@property (nonatomic, strong) UIViewController *canvasToolViewController;
@property (nonatomic, strong) UIViewController *inspectorToolViewController;

@property (nonatomic, strong) VVideoPlayerView *playerView;

@property (nonatomic, strong) VKeyboardManager *keyboardManager;

@end

@implementation VWorkspaceViewController

#pragma mark - VHasManagedDependencies

- (instancetype)initWithDependencyManager:(VDependencyManager *)dependencyManager
{
    UIStoryboard *workspaceStoryboard = [UIStoryboard storyboardWithName:@"Workspace" bundle:nil];
    VWorkspaceViewController *workspaceViewController = [workspaceStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
    workspaceViewController.dependencyManager = dependencyManager;
    workspaceViewController.tools = [dependencyManager workspaceTools];
    
    return workspaceViewController;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.blurredBackgroundImageVIew setBlurredImageWithClearImage:self.previewImage
                                                  placeholderImage:nil
                                                         tintColor:[[UIColor blackColor] colorWithAlphaComponent:0.5f]];
    
    NSMutableArray *toolBarItems = [[NSMutableArray alloc] init];
    [toolBarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    
    [self.tools enumerateObjectsUsingBlock:^(id <VWorkspaceTool> tool, NSUInteger idx, BOOL *stop)
    {
        UIBarButtonItem *itemForTool;
        if (![tool respondsToSelector:@selector(icon)])
        {
            itemForTool = [[UIBarButtonItem alloc] initWithTitle:tool.title
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(selectedBarButtonItem:)];
        }
        else if ([tool icon] != nil)
        {
            itemForTool = [[UIBarButtonItem alloc] initWithImage:[tool icon]
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(selectedBarButtonItem:)];
        }
        else
        {
            itemForTool = [[UIBarButtonItem alloc] initWithTitle:tool.title
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(selectedBarButtonItem:)];
        }
        
        itemForTool.tintColor = [UIColor whiteColor];
        [toolBarItems addObject:itemForTool];
        itemForTool.tag = idx;
        
        if (tool != self.tools.lastObject)
        {
            UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                        target:nil
                                                                                        action:nil];
            fixedSpace.width = 20.0f;
            [toolBarItems addObject:fixedSpace];
        }
    }];
    
    [toolBarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    self.bottomToolbar.items = toolBarItems;
    
    NSData *imageFile = [NSData dataWithContentsOfURL:self.mediaURL];
    self.canvasView.sourceImage = [UIImage imageWithData:imageFile];
    
    AVAsset *asset = [AVAsset assetWithURL:self.mediaURL];
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count > 0)
    {
        self.playerView = [[VVideoPlayerView alloc] initWithFrame:self.canvasView.bounds];
        [self.canvasView addSubview:self.playerView];
        [self.canvasView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[playerView]|"
                                                                                options:kNilOptions
                                                                                metrics:nil
                                                                                  views:@{@"playerView":self.playerView}]];
        [self.canvasView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[playerView]|"
                                                                                options:kNilOptions
                                                                                metrics:nil
                                                                                  views:@{@"playerView":self.playerView}]];
    }
    
    __weak typeof(self) welf = self;
    self.keyboardManager = [[VKeyboardManager alloc] initWithKeyboardWillShowBlock:^(CGRect keyboardFrameBegin, CGRect keyboardFrameEnd, NSTimeInterval animationDuration, UIViewAnimationCurve animationCurve)
    {
        CGRect keyboardEndFrame = [welf.view convertRect:keyboardFrameEnd
                                                fromView:nil];
        CGRect overlap = CGRectIntersection(welf.canvasView.frame, keyboardEndFrame);
        
        // We don't want the inspector to move here
        CGRect inspectorFrame = welf.inspectorToolViewController.view.frame;
        [welf.inspectorConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop)
         {
             [welf.view removeConstraint:constraint];
         }];
        
        void (^animations)() = ^()
        {
            welf.verticalSpaceCanvasToTopOfContainerConstraint.constant = -CGRectGetHeight(overlap) + CGRectGetHeight(welf.topToolbar.frame);
            welf.inspectorToolViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
            welf.inspectorToolViewController.view.frame = inspectorFrame;
            [welf.topToolbar.items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger idx, BOOL *stop)
            {
                [item setEnabled:NO];
            }];
            [welf.view layoutIfNeeded];
        };
        
        [UIView animateWithDuration:animationDuration
                              delay:0.0
                            options:(animationCurve << 16)
                         animations:animations
                         completion:nil];
    }
                                                                     willHideBlock:^(CGRect keyboardFrameBegin, CGRect keyboardFrameEnd, NSTimeInterval animationDuration, UIViewAnimationCurve animationCurve)
    {
        // Undo removing inspector constraints we did in willShowBlock
        welf.inspectorToolViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
        [welf.inspectorConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop)
         {
             [welf.view addConstraint:constraint];
         }];
        
        void (^animations)() = ^()
        {
            welf.verticalSpaceCanvasToTopOfContainerConstraint.constant = CGRectGetHeight(welf.topToolbar.frame);
            [welf.view layoutIfNeeded];
            [welf.topToolbar.items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger idx, BOOL *stop)
            {
                [item setEnabled:YES];
            }];
        };
        
        [UIView animateWithDuration:animationDuration
                              delay:0.0
                            options:(animationCurve << 16)
                         animations:animations
                         completion:nil];
    }
                                                              willChangeFrameBlock:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.keyboardManager.stopCallingHandlerBlocks = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.keyboardManager.stopCallingHandlerBlocks = YES;
}

#pragma mark - Target/Action

- (IBAction)close:(id)sender
{
    self.completionBlock(NO, nil, nil);
}

- (IBAction)publish:(id)sender
{
    MBProgressHUD *hudForView = [MBProgressHUD showHUDAddedTo:self.view
                                                     animated:YES];
    hudForView.labelText = @"Rendering...";
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
    {
        UIImage *renderedImagePreview;
        if (self.playerView)
        {
            NSURL *tempDirectory = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
            NSURL *tempFile = [[tempDirectory URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]] URLByAppendingPathExtension:VConstantMediaExtensionMP4];
            [(id <VVideoWorkspaceTool>)self.selectedTool exportToURL:tempFile
                                                      withCompletion:^(BOOL finished, UIImage *previewImage)
             {
                 self.renderedMediaURL = tempFile;
                 
                 [[VObjectManager sharedManager] uploadMediaWithName:[[NSUUID UUID] UUIDString]
                                                         description:nil
                                                        previewImage:nil
                                                         captionType:VCaptionTypeQuote
                                                           expiresAt:nil
                                                    parentSequenceId:nil
                                                        parentNodeId:nil
                                                               speed:1.0f
                                                            loopType:VLoopRepeat
                                                            mediaURL:self.renderedMediaURL
                                                       facebookShare:NO
                                                        twitterShare:NO
                                                          completion:^(NSURLResponse *response, NSData *responseData, NSDictionary *jsonResponse, NSError *error)
                  {
                      dispatch_async(dispatch_get_main_queue(), ^
                                     {
                                         [MBProgressHUD hideHUDForView:self.view
                                                              animated:YES];
                                         if (self.completionBlock)
                                         {
                                             self.completionBlock(YES, nil, self.renderedMediaURL);
                                         }
                                     });
                  }];
                 
             }];
        }
        else
        {
            NSDate *tick = [NSDate date];
            UIImage *renderedImage = [self renderedImageForCurrentState];
            renderedImagePreview = renderedImage;
            NSDate *tock = [NSDate date];
            VLog(@"Render time: %@", @([tock timeIntervalSinceDate:tick]));
            
            NSData *filteredImageData = UIImageJPEGRepresentation(renderedImage, kJPEGCompressionQuality);
            NSURL *tempDirectory = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
            NSURL *tempFile = [[tempDirectory URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]] URLByAppendingPathExtension:VConstantMediaExtensionJPG];
            if ([filteredImageData writeToURL:tempFile atomically:NO])
            {
                self.renderedMediaURL = tempFile;
            }
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               [MBProgressHUD hideHUDForView:self.view
                                                    animated:YES];
                               self.completionBlock(YES, renderedImagePreview, self.renderedMediaURL);
                           });
        }
    });
}

- (void)selectedBarButtonItem:(UIBarButtonItem *)sender
{
    [self setSelectedBarButtonItem:sender];
    
    self.selectedTool = (id <VWorkspaceTool>)[self toolForTag:sender.tag];
}

#pragma mark - Property Accessors

- (void)setSelectedTool:(id<VWorkspaceTool>)selectedTool
{
    // Re-selected current tool should we dismiss?
    if (selectedTool == _selectedTool)
    {
        return;
    }
 
    if ([selectedTool respondsToSelector:@selector(setCanvasView:)])
    {
        [selectedTool setCanvasView:self.canvasView];
    }
    
    if ([_selectedTool respondsToSelector:@selector(shouldLeaveToolOnCanvas)])
    {
        if (_selectedTool.shouldLeaveToolOnCanvas)
        {
            _canvasToolViewController.view.userInteractionEnabled = NO;
            _canvasToolViewController = nil;
        }
    }
    
    if ([selectedTool respondsToSelector:@selector(canvasToolViewController)])
    {
        // In case this viewController's view was disabled but left on the canvas
        [selectedTool canvasToolViewController].view.userInteractionEnabled = YES;
        [self setCanvasToolViewController:[selectedTool canvasToolViewController]
                                  forTool:selectedTool];
    }
    else
    {
        [self setCanvasToolViewController:nil
                                  forTool:selectedTool];
    }
    
    if ([selectedTool respondsToSelector:@selector(inspectorToolViewController)])
    {
        [self setInspectorToolViewController:[selectedTool inspectorToolViewController]
                                     forTool:selectedTool];
    }
    else
    {
        [self setInspectorToolViewController:nil
                                     forTool:selectedTool];
    }
    
    if ([selectedTool conformsToProtocol:@protocol(VVideoWorkspaceTool)])
    {
        id <VVideoWorkspaceTool> videoTool = (id <VVideoWorkspaceTool>)selectedTool;
        if ([videoTool respondsToSelector:@selector(setMediaURL:)])
        {
            [videoTool setMediaURL:self.mediaURL];
        }
        
        if ([videoTool respondsToSelector:@selector(setPlayerView:)])
        {
            [videoTool setPlayerView:self.playerView];
        }
    }
    
    if ([_selectedTool respondsToSelector:@selector(setSelected:)])
    {
        [_selectedTool setSelected:NO];
    }
    
    if ([selectedTool respondsToSelector:@selector(setSelected:)])
    {
        [selectedTool setSelected:YES];
    }
 
   _selectedTool = selectedTool;
}

#pragma mark - Private Methods

- (UIImage *)renderedImageForCurrentState
{
    CIContext *renderingContext = [CIContext contextWithOptions:@{}];
    
    __block CIImage *filteredImage = [CIImage v_imageWithUImage:self.canvasView.sourceImage];
    
    NSArray *filterOrderTools = [self.tools sortedArrayUsingComparator:^NSComparisonResult(id <VWorkspaceTool> tool1, id <VWorkspaceTool> tool2)
    {
        if (tool1.renderIndex < tool2.renderIndex)
        {
            return NSOrderedAscending;
        }
        if (tool1.renderIndex > tool2.renderIndex)
        {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];

    [filterOrderTools enumerateObjectsUsingBlock:^(id <VWorkspaceTool> tool, NSUInteger idx, BOOL *stop)
    {
        filteredImage = [tool imageByApplyingToolToInputImage:filteredImage];
    }];
    
    CGImageRef renderedImage = [renderingContext createCGImage:filteredImage
                                                      fromRect:[filteredImage extent]];
    UIImage *image = [UIImage imageWithCGImage:renderedImage];
    CGImageRelease(renderedImage);
    return image;
}

- (void)setSelectedBarButtonItem:(UIBarButtonItem *)itemToSelect
{
    [self.bottomToolbar.items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger idx, BOOL *stop) {
        item.tintColor = [UIColor whiteColor];
    }];
    itemToSelect.tintColor = [self.dependencyManager colorForKey:VDependencyManagerAccentColorKey];
}

- (id <VWorkspaceTool>)toolForTag:(NSInteger)tag
{
    if ((self.tools.count == 0) && ((NSInteger)self.tools.count < tag))
    {
        return nil;
    }
    return self.tools[tag];
}

- (void)removeToolViewController:(UIViewController *)toolViewController
{
    [toolViewController willMoveToParentViewController:nil];
    [toolViewController.view removeFromSuperview];
    [toolViewController removeFromParentViewController];
}

- (void)addToolViewController:(UIViewController *)viewController
{
    [self addChildViewController:viewController];
    [self.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (void)setCanvasToolViewController:(UIViewController *)canvasToolViewController
                            forTool:(id<VWorkspaceTool>)tool
{
    [self removeToolViewController:self.canvasToolViewController];
    self.canvasToolViewController = canvasToolViewController;
    
    if (canvasToolViewController == nil)
    {
        return;
    }
    [self addToolViewController:canvasToolViewController];
    [self positionToolViewControllerOnCanvas:self.canvasToolViewController];
}

- (void)setInspectorToolViewController:(UIViewController *)inspectorToolViewController
                               forTool:(id<VWorkspaceTool>)tool
{
    [self removeToolViewController:self.inspectorToolViewController];
    self.inspectorToolViewController = inspectorToolViewController;
    
    if (inspectorToolViewController == nil)
    {
        return;
    }
    [self addToolViewController:inspectorToolViewController];
    [self positionToolViewControllerOnInspector:inspectorToolViewController];
}

- (void)positionToolViewControllerOnCanvas:(UIViewController *)toolViewController
{
    toolViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:@[
                                [NSLayoutConstraint constraintWithItem:toolViewController.view
                                                             attribute:NSLayoutAttributeTop
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.canvasView
                                                             attribute:NSLayoutAttributeTop
                                                            multiplier:1.0f
                                                              constant:0.0f],
                                [NSLayoutConstraint constraintWithItem:toolViewController.view
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.canvasView
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1.0f
                                                              constant:0.0f],
                                [NSLayoutConstraint constraintWithItem:toolViewController.view
                                                             attribute:NSLayoutAttributeRight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.canvasView
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1.0f
                                                              constant:0.0f],
                                [NSLayoutConstraint constraintWithItem:toolViewController.view
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.canvasView
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1.0f
                                                              constant:0.0f],
                                ]];
}

- (void)positionToolViewControllerOnInspector:(UIViewController *)toolViewController
{
    toolViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.inspectorConstraints = [[NSMutableArray alloc] init];
    [self.inspectorConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|[picker]|"
                                                                                           options:kNilOptions
                                                                                           metrics:nil
                                                                                             views:@{@"picker":toolViewController.view}]];
    
    NSDictionary *verticalMetrics = @{@"toolbarHeight":@(CGRectGetHeight(self.bottomToolbar.bounds))};
    [self.inspectorConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[canvas][picker]-toolbarHeight-|"
                                                                                           options:kNilOptions
                                                                                           metrics:verticalMetrics
                                                                                             views:@{@"picker":toolViewController.view,
                                                                                                     @"canvas":self.canvasView}]];
    [self.view addConstraints:self.inspectorConstraints];
}

@end
