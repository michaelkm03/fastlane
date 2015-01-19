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
#import "NSURL+MediaType.h"

// ToolControllers
#import "VImageToolController.h"
#import "VVideoToolController.h"

// Video
#import "VVideoWorkspaceTool.h"

@import AVFoundation;

@interface VWorkspaceViewController () <VToolControllerDelegate>

@property (nonatomic, strong, readwrite) NSURL *renderedMediaURL;

@property (nonatomic, strong) VDependencyManager *dependencyManager;
//@property (nonatomic, strong) NSArray *tools;

@property (nonatomic, weak) IBOutlet UIToolbar *topToolbar;
@property (nonatomic, weak) IBOutlet UIToolbar *bottomToolbar;
@property (nonatomic, weak) IBOutlet VCanvasView *canvasView;
@property (nonatomic, weak) IBOutlet UIImageView *blurredBackgroundImageVIew;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *verticalSpaceCanvasToTopOfContainerConstraint;
@property (nonatomic, strong) NSMutableArray *inspectorConstraints;

@property (nonatomic, strong) UIViewController *canvasToolViewController;
@property (nonatomic, strong) UIViewController *inspectorToolViewController;

@property (nonatomic, strong) VKeyboardManager *keyboardManager;

@property (nonatomic, strong, readwrite) VToolController *toolController;

@end

@implementation VWorkspaceViewController

#pragma mark - VHasManagedDependencies

- (instancetype)initWithDependencyManager:(VDependencyManager *)dependencyManager
{
    UIStoryboard *workspaceStoryboard = [UIStoryboard storyboardWithName:@"Workspace" bundle:nil];
    VWorkspaceViewController *workspaceViewController = [workspaceStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
    workspaceViewController.dependencyManager = dependencyManager;
    
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
    
    self.toolController.canvasView = self.canvasView;
    
    [self.blurredBackgroundImageVIew setBlurredImageWithClearImage:self.previewImage
                                                  placeholderImage:nil
                                                         tintColor:[[UIColor blackColor] colorWithAlphaComponent:0.5f]];
    
    NSMutableArray *toolBarItems = [[NSMutableArray alloc] init];
    [toolBarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                          target:nil
                                                                          action:nil]];
    
    [self.toolController.tools enumerateObjectsUsingBlock:^(id <VWorkspaceTool> tool, NSUInteger idx, BOOL *stop)
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
        
        if (tool != self.toolController.tools.lastObject)
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
    
    
    __weak typeof(self) welf = self;
    self.keyboardManager = [[VKeyboardManager alloc] initWithKeyboardWillShowBlock:^(CGRect keyboardFrameBegin, CGRect keyboardFrameEnd, NSTimeInterval animationDuration, UIViewAnimationCurve animationCurve)
    {

        [welf keyboardWillShowWithFrameBegin:keyboardFrameBegin
                                    frameEnd:keyboardFrameEnd
                           animationDuration:animationDuration
                              animationCurve:animationCurve];
    }
                                                                     willHideBlock:^(CGRect keyboardFrameBegin, CGRect keyboardFrameEnd, NSTimeInterval animationDuration, UIViewAnimationCurve animationCurve)
    {
        [welf keyboardWillHideWithFrameBegin:keyboardFrameBegin
                                    frameEnd:keyboardFrameEnd
                           animationDuration:animationDuration
                              animationCurve:animationCurve];
    }
                                                              willChangeFrameBlock:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.toolController setupDefaultTool];
    [self setSelectedBarButtonItemForTool:self.toolController.selectedTool];
    
    self.keyboardManager.stopCallingHandlerBlocks = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.keyboardManager.stopCallingHandlerBlocks = YES;
}

- (void)setMediaURL:(NSURL *)mediaURL
{
    _mediaURL = mediaURL;
    
    if ([mediaURL v_hasImageExtension])
    {
        self.toolController = [[VImageToolController alloc] initWithTools:[self.dependencyManager workspaceTools]];
    }
    else if ([mediaURL v_hasVideoExtension])
    {
        self.toolController = [[VVideoToolController alloc] initWithTools:[self.dependencyManager workspaceTools]];
        [(VVideoToolController *)self.toolController setMediaURL:mediaURL];
    }

    self.toolController.delegate = self;
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
    
    __weak typeof(self) welf = self;
    [self.toolController exportWithSourceAsset:self.mediaURL
                                withCompletion:^(BOOL finished, NSURL *renderedMediaURL, UIImage *previewImage)
     {
         welf.renderedMediaURL = renderedMediaURL;
         [hudForView hide:YES];
         if (welf.completionBlock)
         {
             welf.completionBlock(YES, previewImage, welf.renderedMediaURL);
         }
     }];
}

- (void)selectedBarButtonItem:(UIBarButtonItem *)sender
{
    self.toolController.selectedTool = (id <VWorkspaceTool>)[self toolForTag:sender.tag];
    [self setSelectedBarButtonItemForTool:[self toolForTag:sender.tag]];
}

#pragma mark - VWorkspaceToolControllerDelegate

- (void)setCanvasViewController:(UIViewController *)canvasViewController
{
    [self removeToolViewController:self.canvasToolViewController];
    self.canvasToolViewController = canvasViewController;
    
    if (canvasViewController == nil)
    {
        return;
    }
    [self addToolViewController:canvasViewController];
    [self positionToolViewControllerOnCanvas:self.canvasToolViewController];
}

- (void)setInspectorViewController:(UIViewController *)inspectorViewController
{
    [self removeToolViewController:self.inspectorToolViewController];
    self.inspectorToolViewController = inspectorViewController;
    
    if (inspectorViewController == nil)
    {
        return;
    }
    [self addToolViewController:inspectorViewController];
    [self positionToolViewControllerOnInspector:inspectorViewController];
}

#pragma mark - Private Methods

- (void)keyboardWillShowWithFrameBegin:(CGRect)beginFrame
                              frameEnd:(CGRect)endFrame
                     animationDuration:(NSTimeInterval)animationDuration
                        animationCurve:(UIViewAnimationCurve)animationCurve
{
    CGRect keyboardEndFrame = [self.view convertRect:endFrame
                                            fromView:nil];
    CGRect overlap = CGRectIntersection(self.canvasView.frame, keyboardEndFrame);
    
    // We don't want the inspector to move here
    CGRect inspectorFrame = self.inspectorToolViewController.view.frame;
    [self.inspectorConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop)
     {
         [self.view removeConstraint:constraint];
     }];
    
    void (^animations)() = ^()
    {
        self.verticalSpaceCanvasToTopOfContainerConstraint.constant = -CGRectGetHeight(overlap) + CGRectGetHeight(self.topToolbar.frame);
        self.inspectorToolViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
        self.inspectorToolViewController.view.frame = inspectorFrame;
        [self.topToolbar.items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger idx, BOOL *stop)
         {
             [item setEnabled:NO];
         }];
        [self.view layoutIfNeeded];
    };
    
    [UIView animateWithDuration:animationDuration
                          delay:0.0
                        options:(animationCurve << 16)
                     animations:animations
                     completion:nil];
}

- (void)keyboardWillHideWithFrameBegin:(CGRect)beginFrame
                              frameEnd:(CGRect)endFrame
                     animationDuration:(NSTimeInterval)animationDuration
                        animationCurve:(UIViewAnimationCurve)animationCurve
{
    // Undo removing inspector constraints we did in willShowBlock
    self.inspectorToolViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inspectorConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop)
     {
         [self.view addConstraint:constraint];
     }];
    
    void (^animations)() = ^()
    {
        self.verticalSpaceCanvasToTopOfContainerConstraint.constant = CGRectGetHeight(self.topToolbar.frame);
        [self.view layoutIfNeeded];
        [self.topToolbar.items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger idx, BOOL *stop)
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

- (void)setSelectedBarButtonItemForTool:(id <VWorkspaceTool>)tool
{
    __block UIBarButtonItem *itemToSelect;
    [self.bottomToolbar.items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger idx, BOOL *stop)
    {
        item.tintColor = [UIColor whiteColor];
        if (tool == [self toolForTag:item.tag])
        {
            itemToSelect = item;
        }
    }];
    itemToSelect.tintColor = [self.dependencyManager colorForKey:VDependencyManagerAccentColorKey];
}

- (id <VWorkspaceTool>)toolForTag:(NSInteger)tag
{
    if ((self.toolController.tools.count == 0) && ((NSInteger)self.toolController.tools.count < tag))
    {
        return nil;
    }
    return self.toolController.tools[tag];
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
