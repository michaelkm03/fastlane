//
//  VStreamsSubViewController.m
//  victorious
//
//  Created by David Keegan on 1/11/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VCommentsContainerViewController.h"
#import "VCommentsTableViewController.h"
#import "VKeyboardBarViewController.h"
#import "VSequence+Fetcher.h"
#import "VUser.h"
#import "VConstants.h"
#import "VObjectManager+Comment.h"
#import "UIImageView+Blurring.h"
#import "UIImage+ImageCreation.h"
#import "VStreamTableViewController.h"
#import "VContentViewController.h"

#import "VCommentToContentAnimator.h"

#import "VThemeManager.h"

@interface VCommentsContainerViewController()   <VCommentsTableViewControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton* backButton;
@property (weak, nonatomic) IBOutlet UIImageView* backgroundImage;
@property (weak, nonatomic) IBOutlet UILabel* titleLabel;

@end

@implementation VCommentsContainerViewController

@synthesize conversationTableViewController = _conversationTableViewController;

+ (instancetype)commentsContainerView
{
    UIViewController*   currentViewController = [[UIApplication sharedApplication] delegate].window.rootViewController;
    VCommentsContainerViewController* commentsContainerViewController = (VCommentsContainerViewController*)[currentViewController.storyboard instantiateViewControllerWithIdentifier: kCommentsContainerStoryboardID];

    return commentsContainerViewController;
}

- (void)setSequence:(VSequence *)sequence
{
    _sequence = sequence;
    
    UIImage* placeholderImage = [UIImage resizeableImageWithColor:[[VThemeManager sharedThemeManager] themedColorForKey:kVBackgroundColor]];
    [self.backgroundImage setLightBlurredImageWithURL:[[self.sequence initialImageURLs] firstObject]
                                     placeholderImage:placeholderImage];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Load the image on first load
    UIImage* placeholderImage = [UIImage resizeableImageWithColor:[[VThemeManager sharedThemeManager] themedColorForKey:kVBackgroundColor]];
    [self.backgroundImage setLightBlurredImageWithURL:[[self.sequence initialImageURLs] firstObject]
                                     placeholderImage:placeholderImage];
    
    
    [self.backButton setImage:[self.backButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.backButton.tintColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVContentTextColor];
    
    self.titleLabel.textColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVContentTextColor];
    self.titleLabel.font = [[VThemeManager sharedThemeManager] themedFontForKey:kVHeading1Font];
    
    //Need to manually add this again so it appears over everything else.
    [self.view addSubview:self.backButton];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.navigationController.delegate = self;
    
    if (animated)
    {
        __block CGFloat originalKeyboardY = self.keyboardBarViewController.view.frame.origin.y;
        __block CGFloat originalConvertationX = self.conversationTableViewController.view.frame.origin.x;
        
        CGRect viewFrame = self.conversationTableViewController.view.frame;
        self.conversationTableViewController.view.frame = CGRectMake(CGRectGetWidth(self.view.frame),
                                                                     CGRectGetMinY(viewFrame),
                                                                     CGRectGetWidth(viewFrame),
                                                                     CGRectGetHeight(viewFrame));

        self.keyboardBarViewController.view.alpha = 0;
        self.backButton.alpha = 0;
        self.titleLabel.alpha = 0;
        [UIView animateWithDuration:.3f
                         animations:^
         {
             CGRect viewFrame = self.conversationTableViewController.view.frame;
             self.conversationTableViewController.view.frame = CGRectMake(originalConvertationX,
                                                                          CGRectGetMinY(viewFrame),
                                                                          CGRectGetWidth(viewFrame),
                                                                          CGRectGetHeight(viewFrame));
         }
                         completion:^(BOOL finished)
         {
             [UIView animateWithDuration:.1f
                              animations:^
              {
                  self.keyboardBarViewController.view.alpha = 1;
                  self.backButton.alpha = 1;
                  self.titleLabel.alpha = 1;
              }];
         }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.navigationController.delegate == self)
    {
        self.navigationController.delegate = nil;
    }
}

- (UITableViewController *)conversationTableViewController
{
    if(_conversationTableViewController == nil)
    {
        VCommentsTableViewController *streamsCommentsController =
        [self.storyboard instantiateViewControllerWithIdentifier:@"comments"];
        streamsCommentsController.delegate = self;
        streamsCommentsController.sequence = self.sequence;
        _conversationTableViewController = streamsCommentsController;
    }

    return _conversationTableViewController;
}

#pragma mark - VCommentsTableViewControllerDelegate

- (void)streamsCommentsController:(VCommentsTableViewController *)viewController shouldReplyToUser:(VUser *)user
{
    self.keyboardBarViewController.textView.text = [NSString stringWithFormat:@"@%@ ", user.name];
    [self.keyboardBarViewController.textView becomeFirstResponder];
}

#pragma mark - VKeyboardBarDelegate

- (void)keyboardBar:(VKeyboardBarViewController *)keyboardBar didComposeWithText:(NSString *)text mediaURL:(NSURL *)mediaURL mediaExtension:(NSString *)mediaExtension
{
    __block UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.frame = CGRectMake(0, 0, 24, 24);
    indicator.hidesWhenStopped = YES;
    [self.view addSubview:indicator];
    indicator.center = self.view.center;
    [indicator startAnimating];
    
    VSuccessBlock success = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        NSLog(@"%@", resultObjects);
        [indicator stopAnimating];
        [(VCommentsTableViewController *)self.conversationTableViewController sortComments];
    };
    VFailBlock fail = ^(NSOperation* operation, NSError* error)
    {
        if (error.code == 5500)
        {
            NSLog(@"%@", error);
            [indicator stopAnimating];
            
            UIAlertView*    alert   =
            [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"TranscodingMediaTitle", @"")
                                       message:NSLocalizedString(@"TranscodingMediaBody", @"")
                                      delegate:nil
                             cancelButtonTitle:NSLocalizedString(@"OKButton", @"")
                             otherButtonTitles:nil];
            [alert show];
        }
        [indicator stopAnimating];
    };
    
    NSData *data = [NSData dataWithContentsOfURL:mediaURL];
    [[NSFileManager defaultManager] removeItemAtURL:mediaURL error:nil];
    
    [[VObjectManager sharedManager] addCommentWithText:text
                                                  Data:data
                                        mediaExtension:mediaExtension
                                              mediaUrl:nil
                                            toSequence:_sequence
                                             andParent:nil
                                          successBlock:success
                                             failBlock:fail];
}

- (IBAction)pressedBackButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (id<UIViewControllerAnimatedTransitioning>) navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController*)fromVC
                                                  toViewController:(UIViewController*)toVC
{
    if (operation == UINavigationControllerOperationPop
        && [toVC isKindOfClass:[VContentViewController class]])
    {
        VCommentToContentAnimator* animator = [[VCommentToContentAnimator alloc] init];
        //        animator.indexPathForSelectedCell = self.tableView.indexPathForSelectedRow;
        return animator;
    }
    else if (operation == UINavigationControllerOperationPop
             && [toVC isKindOfClass:[VContentViewController class]])
    {
//        VCommentToContentAnimator* animator = [[VCommentToContentAnimator alloc] init];
//        //        animator.indexPathForSelectedCell = self.tableView.indexPathForSelectedRow;
//        return animator;
    }
    return nil;
}

@end
