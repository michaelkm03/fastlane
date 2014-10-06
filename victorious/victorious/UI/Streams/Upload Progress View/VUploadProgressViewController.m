//
//  VUploadProgressViewController.m
//  victorious
//
//  Created by Josh Hinman on 10/4/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "UIActionSheet+VBlocks.h"
#import "VUploadManager.h"
#import "VUploadProgressView.h"
#import "VUploadProgressViewController.h"
#import "VUploadTaskInformation.h"

const CGFloat VUploadProgressViewControllerIdealHeight = 44.0f;
static const NSTimeInterval kFinishedTaskDisplayTime = 5.0; ///< Amount of time to keep finished tasks in view
static const NSTimeInterval kAnimationDuration = 0.2;

@interface VUploadProgressViewController () <VUploadProgressViewDelegate>

@property (nonatomic, readwrite) VUploadManager *uploadManager;
@property (nonatomic, readwrite) NSInteger numberOfUploads;
@property (nonatomic, strong) NSMutableArray /* VUploadProgressView */ *uploadProgressViews;

@end

@implementation VUploadProgressViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        _uploadProgressViews = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (instancetype)viewControllerForUploadManager:(VUploadManager *)uploadManager
{
    VUploadProgressViewController *viewController = [[self alloc] initWithNibName:nil bundle:nil];
    viewController.uploadManager = uploadManager;
    return viewController;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View Lifecycle

- (void)loadView
{
    self.view = [[UIView alloc] init];
    self.view.clipsToBounds = YES;
    [self.uploadManager getQueuedUploadTasksWithCompletion:^(NSArray *tasks)
    {
        dispatch_async(dispatch_get_main_queue(), ^(void)
        {
            for (VUploadTaskInformation *task in tasks)
            {
                VUploadProgressViewState state = [self.uploadManager isTaskInProgress:task] ? VUploadProgressViewStateInProgress : VUploadProgressViewStateFailed;
                [self addUpload:task withState:state animated:YES];
            }
            self.numberOfUploads = (NSInteger)tasks.count;
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(uploadTaskBegan:)
                                                         name:VUploadManagerTaskBeganNotification
                                                       object:self.uploadManager];
        });
    }];
}

#pragma mark - Properties

- (void)setNumberOfUploads:(NSInteger)numberOfUploads
{
    if (numberOfUploads == _numberOfUploads)
    {
        return;
    }
    _numberOfUploads = numberOfUploads;
    
    if ([self.delegate respondsToSelector:@selector(uploadProgressViewController:isNowDisplayingThisManyUploads:)])
    {
        [self.delegate uploadProgressViewController:self isNowDisplayingThisManyUploads:numberOfUploads];
    }
}

#pragma mark - Add/Remove Subviews

- (void)addUpload:(VUploadTaskInformation *)uploadTask withState:(VUploadProgressViewState)state animated:(BOOL)animated
{
    VUploadProgressView *progressView = [VUploadProgressView uploadProgressViewFromNib];
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    progressView.uploadTask = uploadTask;
    progressView.delegate = self;
    progressView.state = state;
    [self.view addSubview:progressView];
    
    [self.uploadProgressViews addObject:progressView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[progressView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(progressView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[progressView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(progressView)]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadTaskFailed:) name:VUploadManagerTaskFailedNotification object:uploadTask];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadTaskFinished:) name:VUploadManagerTaskFinishedNotification object:uploadTask];
    
    self.numberOfUploads = (NSInteger)self.uploadProgressViews.count;
    
    if (animated)
    {
        [self.view layoutIfNeeded];
        CGRect currentFrame = progressView.frame;
        progressView.frame = CGRectMake(CGRectGetMinX(currentFrame), -CGRectGetHeight(currentFrame), CGRectGetWidth(currentFrame), CGRectGetHeight(currentFrame));
        [UIView animateWithDuration:kAnimationDuration
                         animations:^(void)
        {
            [self.view layoutIfNeeded];
        }];
    }
}

- (void)removeUpload:(VUploadProgressView *)uploadProgressView animated:(BOOL)animated
{
    void (^animations)() = ^(void)
    {
        CGRect currentFrame = uploadProgressView.frame;
        uploadProgressView.frame = CGRectMake(CGRectGetMinX(currentFrame), -CGRectGetHeight(currentFrame), CGRectGetWidth(currentFrame), CGRectGetHeight(currentFrame));
    };
    
    void (^completion)(BOOL) = ^(BOOL finished)
    {
        [uploadProgressView removeFromSuperview];
        [self.uploadProgressViews removeObject:uploadProgressView];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:VUploadManagerTaskFailedNotification object:uploadProgressView.uploadTask];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:VUploadManagerTaskFinishedNotification object:uploadProgressView.uploadTask];
        
        self.numberOfUploads = (NSInteger)self.uploadProgressViews.count;
    };
    
    if (animated)
    {
        [UIView animateWithDuration:kAnimationDuration animations:animations completion:completion];
    }
    else
    {
        completion(YES);
    }
}

#pragma mark - VUploadProgressViewDelegate methods

- (void)accessoryButtonTappedInUploadProgressView:(VUploadProgressView *)uploadProgressView
{
    switch (uploadProgressView.state)
    {
        case VUploadProgressViewStateInProgress:
        {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"UploadCancelAreYouSure", @"")
                                                            cancelButtonTitle:NSLocalizedString(@"NoKeepUploading", @"")
                                                               onCancelButton:nil
                                                       destructiveButtonTitle:NSLocalizedString(@"YesCancelUpload", @"")
                                                          onDestructiveButton:^(void)
            {
                uploadProgressView.state = VUploadProgressViewStateCancelling;
                [self.uploadManager cancelUploadTask:uploadProgressView.uploadTask];
            }
                                                   otherButtonTitlesAndBlocks:nil];
            [actionSheet showInView:self.parentViewController.view];
        }
            break;

        case VUploadProgressViewStateFailed:
        {
            // TODO: retry upload
        }
            break;
            
        case VUploadProgressViewStateFinalizing:
        case VUploadProgressViewStateFinished:
            [self removeUpload:uploadProgressView animated:YES];
            break;
            
        default:
            break;
    }
}

#pragma mark - NSNotification handlers

- (void)uploadTaskBegan:(NSNotification *)notification
{
    [self addUpload:notification.userInfo[VUploadManagerUploadTaskUserInfoKey] withState:VUploadProgressViewStateInProgress animated:YES];
}

- (void)uploadTaskFailed:(NSNotification *)notification
{
    for (VUploadProgressView *uploadProgressView in self.uploadProgressViews)
    {
        if ([uploadProgressView.uploadTask isEqual:notification.object])
        {
            NSError *error = notification.userInfo[VUploadManagerErrorUserInfoKey];
            if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled)
            {
                [self removeUpload:uploadProgressView animated:YES];
            }
            else
            {
                uploadProgressView.state = VUploadProgressViewStateFailed;
            }
            break;
        }
    }
}

- (void)uploadTaskFinished:(NSNotification *)notification
{
    for (VUploadProgressView *uploadProgressView in self.uploadProgressViews)
    {
        if ([uploadProgressView.uploadTask isEqual:notification.object])
        {
            uploadProgressView.state = VUploadProgressViewStateFinished;
            if (self.numberOfUploads == 1)
            {
                typeof(self) __weak weakSelf = self;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kFinishedTaskDisplayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void)
                {
                    typeof(weakSelf) strongSelf = weakSelf;
                    if (strongSelf && [strongSelf.uploadProgressViews containsObject:uploadProgressView])
                    {
                        [self removeUpload:uploadProgressView animated:YES];
                    }
                });
            }
            break;
        }
    }
}

@end