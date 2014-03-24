//
//  VContentViewController.m
//  victorious
//
//  Created by Will Long on 2/25/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VContentViewController.h"

#import "VConstants.h"

#import "VEmotiveBallisticsBarViewController.h"
#import "VPollAnswerBarViewController.h"

#import "VCommentsContainerViewController.h"
#import "VContentTransitioningDelegate.h"

#import "VResultView.h"

#import "VSequence+Fetcher.h"
#import "VNode+Fetcher.h"
#import "VAsset+Fetcher.h"
#import "VAnswer.h"
#import "VInteractionManager.h"
#import "VPollResult.h"

#import "UIImageView+Blurring.h"
#import "UIWebView+VYoutubeLoading.h"
#import "UIView+VFrameManipulation.h"
#import "NSString+VParseHelp.h"
#import "UIImage+SolidColorImage.h"

#import "VThemeManager.h"

#import "VRemixTrimViewController.h"

CGFloat kContentMediaViewOffset = 154;

@import MediaPlayer;

@interface VContentViewController ()  <UIWebViewDelegate, VInteractionManagerDelegate, VPollAnswerBarDelegate>

@property (weak, nonatomic) IBOutlet UIImageView* backgroundImage;
@property (weak, nonatomic) IBOutlet UILabel* descriptionLabel;
@property (weak, nonatomic) IBOutlet UIView* barContainerView;

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray* buttonCollection;
@property (weak, nonatomic) IBOutlet UIButton* remixButton;

@property (weak, nonatomic) IBOutlet UIView* mpPlayerContainmentView;

@property (weak, nonatomic) IBOutlet UIImageView* previewImage;

@property (weak, nonatomic) IBOutlet UIView* pollPreviewView;
@property (weak, nonatomic) IBOutlet UIImageView* firstSmallPreviewImage;
@property (weak, nonatomic) IBOutlet UIImageView* secondSmallPreviewImage;
@property (weak, nonatomic) IBOutlet VResultView* firstResultView;
@property (weak, nonatomic) IBOutlet VResultView* secondResultView;
@property (weak, nonatomic) IBOutlet UIButton* firstPollButton;
@property (weak, nonatomic) IBOutlet UIButton* secondPollButton;

@property (weak, nonatomic) IBOutlet UIView* orContainerView;
@property (strong, nonatomic) UIDynamicAnimator* orAnimator;

@property (strong, nonatomic) MPMoviePlayerController* mpController;
@property (strong, nonatomic) VNode* currentNode;
@property (strong, nonatomic) VAsset* currentAsset;
@property (strong, nonatomic) VInteractionManager* interactionManager;

@property (strong, nonatomic) id<UIViewControllerTransitioningDelegate> transitionDelegate;

@end

@implementation VContentViewController

+ (VContentViewController *)sharedInstance
{
    static  VContentViewController*   sharedInstance;
    static  dispatch_once_t         onceToken;
    dispatch_once(&onceToken,
    ^{
        UIViewController*   currentViewController = [[UIApplication sharedApplication] delegate].window.rootViewController;
        sharedInstance = (VContentViewController*)[currentViewController.storyboard instantiateViewControllerWithIdentifier: kContentViewStoryboardID];
    });
    
    return sharedInstance;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.transitionDelegate = [[VContentTransitioningDelegate alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mpLoadStateChanged)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(animateVideoClosed)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    
    self.mpController = [[MPMoviePlayerController alloc] initWithContentURL:nil];
    self.mpController.scalingMode = MPMovieScalingModeAspectFill;
    self.mpController.view.frame = self.previewImage.frame;
    self.mpController.shouldAutoplay = NO;
    [self.mpPlayerContainmentView addSubview:self.mpController.view];
    
    self.firstResultView.isVertical = YES;
    self.firstResultView.hidden = YES;
    
    self.secondResultView.isVertical = YES;
    self.secondResultView.hidden = YES;
    
    for (UIButton* button in self.buttonCollection)
    {
        [button setImage:[button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        button.tintColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVContentAccentColor];
    }
    self.descriptionLabel.textColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVContentAccentColor];
    self.descriptionLabel.font = [[VThemeManager sharedThemeManager] themedFontForKey:kVContentTitleFont];
    
    [self.remixButton setImage:[self.remixButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.remixButton.tintColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVAccentColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    self.sequence = self.sequence;
    
    self.orImageView.hidden = ![self.currentNode isPoll];
    self.orImageView.alpha = 0;
    
    self.firstPollButton.alpha = 0;
    self.secondPollButton.alpha = 0;
    
    [self.topActionsView setYOrigin:self.mediaView.frame.origin.y];
    self.topActionsView.alpha = 0;
    [UIView animateWithDuration:.2f
                     animations:^
     {
         [self.topActionsView setYOrigin:0];
         self.topActionsView.alpha = 1;
         self.orImageView.alpha = 1;
         self.firstPollButton.alpha = 1;
         self.secondPollButton.alpha = 1;
     }
                     completion:^(BOOL finished)
     {
         [self updateActionBar];
     }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    self.orAnimator = nil;
}

-(VInteractionManager*)interactionManager
{
    if(!_interactionManager)
    {
        _interactionManager = [[VInteractionManager alloc] initWithNode:self.currentNode delegate:self];
    }
    return _interactionManager;
}

- (void)setSequence:(VSequence *)sequence
{
    _sequence = sequence;

    UIImage* placeholderImage = [UIImage resizeableImageWithColor:[[VThemeManager sharedThemeManager] themedColorForKey:kVBackgroundColor]];
    [self.backgroundImage setLightBlurredImageWithURL:[[self.sequence initialImageURLs] firstObject]
                                     placeholderImage:placeholderImage];
    self.descriptionLabel.text = _sequence.name;
    self.currentNode = [sequence firstNode];
}

- (void)setCurrentNode:(VNode *)currentNode
{
    //If you run out of nodes... go to the beginning.
    if (!currentNode)
        _currentNode = [self.sequence firstNode];
    
    //If this node is not for the sequence... Something is wrong, just use the first node and print a warning
    else if (currentNode.sequence != self.sequence)
    {
        VLog(@"Warning: node %@ does not belong in sequence %@", currentNode, self.sequence);
        _currentNode = [self.sequence firstNode];
    }
    else
        _currentNode = currentNode;
    
    _currentAsset = nil; //we changed nodes, so we're not on an asset
    if ([self.currentNode isQuiz])
        [self loadQuiz];
    
    else if ([self.currentNode isPoll])
        [self loadPoll];
    
    else
        [self loadNextAsset];
    
    self.interactionManager.node = currentNode;
}

- (void)updateActionBar
{
    if (!self.isViewLoaded)
    {
        return;
    }
    
    UIViewController<VAnimation>* newBarViewController;
    
    //Find the appropriate target based on what view is hidden
    
    if([self.sequence isPoll] && ![self.actionBarVC isKindOfClass:[VPollAnswerBarViewController class]])
    {
        VPollAnswerBarViewController* pollAnswerBar = [VPollAnswerBarViewController sharedInstance];
        pollAnswerBar.target = self.pollPreviewView;
        pollAnswerBar.sequence = self.sequence;
        pollAnswerBar.delegate = self;
        newBarViewController = pollAnswerBar;
    }
    else if (![self.sequence isPoll] && ![self.actionBarVC isKindOfClass:[VEmotiveBallisticsBarViewController class]])
    {
        VEmotiveBallisticsBarViewController* emotiveBallistics = [VEmotiveBallisticsBarViewController sharedInstance];
        emotiveBallistics.sequence = self.sequence;
        emotiveBallistics.target = self.previewImage;
        newBarViewController = emotiveBallistics;
    }
    else if ([self.actionBarVC isKindOfClass:[VEmotiveBallisticsBarViewController class]])
    {
        ((VEmotiveBallisticsBarViewController*)self.actionBarVC).target = self.previewImage;//Change the target if we need to
    }
    
    if (self.actionBarVC && newBarViewController)
    {
        [self.actionBarVC animateOutWithDuration:.2f
                                      completion:^(BOOL finished)
                                      {
                                          [self.actionBarVC removeFromParentViewController];
                                          [self.actionBarVC.view removeFromSuperview];
                                          [self addChildViewController:newBarViewController];
                                          [newBarViewController didMoveToParentViewController:self];
                                          [self.barContainerView addSubview:newBarViewController.view];
                                          self.actionBarVC = newBarViewController;
                                          
                                          [self.actionBarVC animateInWithDuration:.2f completion:^(BOOL finished) {
                                              [self pollAnimation];
                                          }];
                                      }];
    }
    else if (newBarViewController)
    {
        [self.actionBarVC removeFromParentViewController];
        [self.actionBarVC.view removeFromSuperview];
        [self addChildViewController:newBarViewController];
        [newBarViewController didMoveToParentViewController:self];
        [self.barContainerView addSubview:newBarViewController.view];
        self.actionBarVC = newBarViewController;
        
        [self.actionBarVC animateInWithDuration:.2f completion:^(BOOL finished) {
            [self pollAnimation];
        }];
    }
}

- (void)pollAnimation
{
    [UIView animateWithDuration:.2f
                     animations:^{
                         
                         [self.firstSmallPreviewImage setXOrigin:self.firstSmallPreviewImage.frame.origin.x - 1];
                         [self.secondSmallPreviewImage setXOrigin:self.secondSmallPreviewImage.frame.origin.x + 1];
                         
                         self.orImageView.hidden = ![self.currentNode isPoll];
                         self.orImageView.center = CGPointMake(self.orImageView.center.x, self.pollPreviewView.center.y);
                         self.orAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.orContainerView];
                         
                         UIGravityBehavior* gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.orImageView]];
                         gravityBehavior.magnitude = 4;
                         [self.orAnimator addBehavior:gravityBehavior];
                         
                         UIDynamicItemBehavior *elasticityBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.orImageView]];
                         elasticityBehavior.elasticity = 0.2f;
                         [self.orAnimator addBehavior:elasticityBehavior];
                         
                         UICollisionBehavior* collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.orImageView]];
                         collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
                         [self.orAnimator addBehavior:collisionBehavior];
                     }];
}

#pragma mark - Sequence Logic
- (void)loadNextAsset
{
    if (!self.currentAsset)
        self.currentAsset = [self.currentNode firstAsset];
    //    else
    //        self.currentAsset = [self.currentNode nextAssetFromAsset:self.currentAsset];
    
    if ([self.currentAsset isVideo])
        [self loadVideo];
    
    else //Default case: we assume its an image and hope it works out
        [self loadImage];
}

#pragma mark - Poll
- (void)loadPoll
{
    NSArray* answers = [[self.sequence firstNode] firstAnswers];
    [self.firstSmallPreviewImage setImageWithURL:[((VAnswer*)[answers firstObject]).mediaUrl convertToPreviewImageURL]];
    [self.secondSmallPreviewImage setImageWithURL:[((VAnswer*)[answers lastObject]).mediaUrl convertToPreviewImageURL]];
    
    if ([[((VAnswer*)[answers firstObject]).mediaUrl pathExtension] isEqualToString:VConstantMediaExtensionM3U8])
    {
        self.firstPollButton.hidden = NO;
    }
    else
    {
        self.firstPollButton.hidden = YES;
    }
    if ([[((VAnswer*)[answers lastObject]).mediaUrl pathExtension] isEqualToString:VConstantMediaExtensionM3U8])
    {
        self.secondPollButton.hidden = NO;
    }
    else
    {
        self.secondPollButton.hidden = YES;
    }
    
    self.pollPreviewView.hidden = NO;
    self.previewImage.hidden = YES;
    self.mpPlayerContainmentView.hidden = YES;
    self.remixButton.hidden = YES;
    
    [self updateActionBar];
}

- (IBAction)playPoll:(id)sender
{
    NSArray* answers = [[self.sequence firstNode] firstAnswers];
    if( ((UIButton*)sender).tag == self.firstPollButton.tag)
    {
        [self.mpController setContentURL:[NSURL URLWithString:((VAnswer*)[answers firstObject]).mediaUrl]];
    }
    else if ( ((UIButton*)sender).tag == self.secondPollButton.tag)
    {
        [self.mpController setContentURL:[NSURL URLWithString:((VAnswer*)[answers lastObject]).mediaUrl]];
    }
    [self.mpController prepareToPlay];
}

#pragma mark - Quiz
- (void)loadQuiz
{
    //self.actionBar = [VActionBarViewController quizBar];
}

#pragma mark - Image
- (void)loadImage
{
    NSURL* imageUrl;
    if ([self.currentAsset.type isEqualToString:VConstantsMediaTypeImage])
    {
        imageUrl = [NSURL URLWithString:self.currentAsset.data];
    }
    else
    {
        imageUrl = [NSURL URLWithString:self.sequence.previewImage];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imageUrl];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    UIImage* placeholderImage = [UIImage resizeableImageWithColor:[[VThemeManager sharedThemeManager] themedColorForKey:kVBackgroundColor]];

    [self.previewImage setImageWithURLRequest:request
                             placeholderImage:placeholderImage
                                      success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
                                      {
                                          CGFloat yRatio = 1;
                                          CGFloat xRatio = 1;
                                          self.previewImage.image = image;
                                          if (self.previewImage.image.size.height < self.previewImage.image.size.width)
                                          {
                                              yRatio = self.previewImage.image.size.height / self.previewImage.image.size.width;
                                          }
                                          else if (self.previewImage.image.size.height > self.previewImage.image.size.width)
                                          {
                                              xRatio = self.previewImage.image.size.width / self.previewImage.image.size.height;
                                          }
                                          CGFloat videoHeight = self.mediaView.frame.size.width * yRatio;
                                          CGFloat videoWidth = self.mediaView.frame.size.width * xRatio;
                                          self.previewImage.frame = CGRectMake(0, 0, videoWidth, videoHeight);
                                          
                                          self.previewImage.hidden = NO;
                                      }
                                      failure:nil];
    
    self.pollPreviewView.hidden = YES;
    self.mpPlayerContainmentView.hidden = YES;
    self.remixButton.hidden = YES;
    
    [self updateActionBar];
}

#pragma mark - Video
- (void)loadVideo
{
    [self loadImage];

    self.remixButton.hidden = NO;

    [self.mpController setContentURL:[NSURL URLWithString:self.currentAsset.data]];
    self.mpPlayerContainmentView.hidden = YES;
    [self.mpController prepareToPlay];
    
    [self updateActionBar];
}

- (void)mpLoadStateChanged
{
    if (self.mpController.loadState == MPMovieLoadStatePlayable && self.mpController.playbackState != MPMoviePlaybackStatePlaying)
    {
        self.mpController.view.frame = self.previewImage.frame;
        
        [self.mpPlayerContainmentView addSubview:self.mpController.view];
        
        [self animateVideoOpen];
    }
}

- (void)animateVideoOpen
{
    [self.mpPlayerContainmentView setSize:CGSizeMake(0, 0)];
    self.mpPlayerContainmentView.hidden = NO;

    CGFloat duration = [self.sequence isPoll] ? .5f : 0;//We only animate in poll videos

    [UIView animateWithDuration:duration animations:
     ^{
         [self.mpPlayerContainmentView setSize:CGSizeMake(self.mpController.view.frame.size.width, self.mpController.view.frame.size.height)];
     }
                     completion:^(BOOL finished)
    {
                         [self.mpController play];
                     }];
}

- (void)animateVideoClosed
{
    CGFloat duration = [self.sequence isPoll] ? .5f : 0;//We only animate in poll videos

    [UIView animateWithDuration:duration animations:
     ^{
         [self.mpPlayerContainmentView setSize:CGSizeMake(0,0)];
     }];
}

#pragma mark - Button Actions
- (IBAction)pressedMore:(id)sender
{
    //Specced but still no idea what its supposed to do
}

- (IBAction)pressedRemix:(id)sender
{   
    UIViewController* remixVC = [VRemixTrimViewController remixViewControllerWithURL:[self.currentAsset.data mp4UrlFromM3U8]];
    [self presentViewController:remixVC animated:YES completion:
    ^{
        [self.mpController stop];
    }];
}

#pragma mark - VInteractionManagerDelegate
- (void)firedInteraction:(VInteraction*)interaction
{
    VLog(@"Interaction fired:%@", interaction);
}

#pragma mark - VPollAnswerBarDelegate
- (void)answeredPollWithAnswerId:(NSNumber *)answerId
{
    self.firstResultView.hidden = NO;
    self.secondResultView.hidden = NO;
    [self.firstResultView setProgress:0 animated:NO];
    [self.secondResultView setProgress:0 animated:NO];
    
    NSInteger totalVotes = 0;
    for(VPollResult* result in self.sequence.pollResults)
    {
        totalVotes+= result.count.integerValue;
    }
    totalVotes = totalVotes ? totalVotes : 1; //dividing by 0 is bad.
    
    for(VPollResult* result in self.sequence.pollResults)
    {
        VResultView* resultView = [self resultViewForAnswerId:result.answerId];
        
        CGFloat progress = result.count.doubleValue / totalVotes;
        
        if (result.answerId == answerId)
        {
            resultView.color = [[VThemeManager sharedThemeManager] themedColorForKey:kVMainColor];
        }
        else
        {
            resultView.color = [[VThemeManager sharedThemeManager] themedColorForKey:kVAccentColor];
        }
        
        [resultView setProgress:progress animated:YES];
    }
}

- (VResultView*)resultViewForAnswerId:(NSNumber*)answerId
{
    NSArray* answers = [[self.sequence firstNode] firstAnswers];
    if ([answerId isEqualToNumber:((VAnswer*)[answers firstObject]).remoteId])
        return self.firstResultView;
    
    else if ([answerId isEqualToNumber:((VAnswer*)[answers lastObject]).remoteId])
        return self.secondResultView;
    
    else return nil;
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    ((UIViewController*)segue.destinationViewController).transitioningDelegate = self.transitionDelegate;
    ((UIViewController*)segue.destinationViewController).modalPresentationStyle= UIModalPresentationCustom;
    [self.mpController stop];
    self.mpController = nil;
    
    if ([segue.identifier isEqualToString:kContentCommentSegueStoryboardID])
    {
        VCommentsContainerViewController* commentVC = segue.destinationViewController;
        commentVC.sequence = self.sequence;
    }
}

- (IBAction)unwindToContentView:(UIStoryboardSegue*)sender
{
    
}

@end
