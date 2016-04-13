//
//  VCreatePollViewController.m
//  victorious
//
//  Created by David Keegan on 1/8/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "NSString+VParseHelp.h"
#import "UIImage+ImageCreation.h"
#import "VContentInputAccessoryView.h"
#import "VCreatePollViewController.h"
#import "UIStoryboard+VMainStoryboard.h"
#import "victorious-Swift.h"
#import "VDependencyManager.h"
#import "VMediaAttachmentPresenter.h"
#import "VImageCreationFlowController.h"

static const NSInteger kMinLength = 2;

static NSString * const kImageIconKey = @"imageIcon";
static NSString * const kVideoIconKey = @"videoIcon";
static NSString * const kOrIconKey = @"orIcon";

static char KVOContext;

@interface VCreatePollViewController() <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *middleOrIconImageView;

@property (weak, nonatomic) IBOutlet UIButton *leftRemoveButton;
@property (weak, nonatomic) IBOutlet UIButton *rightRemoveButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaButtonLeftSpacingConstraint;
@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UIButton *videoButton;

@property (weak, nonatomic) IBOutlet UILabel *questionPrompt;
@property (weak, nonatomic) IBOutlet UILabel *leftAnswerPrompt;
@property (weak, nonatomic) IBOutlet UILabel *rightAnswerPrompt;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftAnswerTextViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightAnswerTextViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *answersSuperview;

@property (weak, nonatomic) IBOutlet UIView *addMediaView;

@property (strong, nonatomic) VMediaAttachmentPresenter *attachmentPresenter;

@property (nonatomic, assign) BOOL didPublish;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *constraintsThatNeedHalfPointConstant;

@property (nonatomic) BOOL textViewsCleared;
@property (nonatomic, strong) VDependencyManager *dependencyManager;

@end

@implementation VCreatePollViewController

+ (instancetype)newWithDependencyManager:(VDependencyManager *)dependencyManager
{
    NSBundle *bundleForClass = [NSBundle bundleForClass:self];
    UIStoryboard *storyboardForClass = [UIStoryboard storyboardWithName:NSStringFromClass(self) bundle:bundleForClass];
    VCreatePollViewController *createView = (VCreatePollViewController *)[storyboardForClass instantiateViewControllerWithIdentifier: NSStringFromClass([VCreatePollViewController class])];
    createView.dependencyManager = dependencyManager;
    return createView;
}

- (void)dealloc
{
    [self.leftAnswerTextView  removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) context:&KVOContext];
    [self.rightAnswerTextView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) context:&KVOContext];
    
    if ( !self.didPublish )
    {
        NSDictionary *params = @{ VTrackingKeyContentType : VTrackingValuePoll };
        [[VTrackingManager sharedInstance] trackEvent:VTrackingEventUserDidCancelPublish parameters:params];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.constraintsThatNeedHalfPointConstant enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        [obj setConstant:0.5f];
    }];

    UIImage *imageIcon = [self.dependencyManager imageForKey:kImageIconKey];
    UIImage *videoIcon = [self.dependencyManager imageForKey:kVideoIconKey];
    UIImage *orIcon = [self.dependencyManager imageForKey:kOrIconKey];
    // If we have icons use them, if not stick with defaults.
    if (imageIcon != nil)
    {
        [self.imageButton setImage:imageIcon forState:UIControlStateNormal];
    }
    if (videoIcon != nil)
    {
        [self.videoButton setImage:videoIcon forState:UIControlStateNormal];
    }
    if (orIcon != nil)
    {
        [self.middleOrIconImageView setImage:orIcon];
    }
    
    [self.imageButton setBackgroundColor:[self.dependencyManager colorForKey:VDependencyManagerLinkColorKey]];
    [self.videoButton setBackgroundColor:[self.dependencyManager colorForKey:VDependencyManagerLinkColorKey]];
    
    UIImage *newImage = [self.leftRemoveButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.rightRemoveButton setImage:newImage forState:UIControlStateNormal];
    
    newImage = [self.leftRemoveButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.leftRemoveButton setImage:newImage forState:UIControlStateNormal];
    
    self.questionTextView.textColor = [self.dependencyManager colorForKey:VDependencyManagerMainTextColorKey];
    self.questionTextView.tintColor = [self.dependencyManager colorForKey:VDependencyManagerMainTextColorKey];
    self.questionTextView.font = [self.dependencyManager fontForKey:VDependencyManagerHeading2FontKey];
    self.questionTextView.inputAccessoryView = [self inputAccessoryViewForTextView:self.questionTextView];

    self.questionPrompt.text      = NSLocalizedString(@"Ask a question...", @"");
    self.questionPrompt.font      = [self.dependencyManager fontForKey:VDependencyManagerHeading2FontKey];
    
    self.leftAnswerTextView.textColor = [self.dependencyManager colorForKey:VDependencyManagerMainTextColorKey];
    self.leftAnswerTextView.tintColor = [self.dependencyManager colorForKey:VDependencyManagerMainTextColorKey];
    self.leftAnswerTextView.font      = [self.dependencyManager fontForKey:VDependencyManagerHeading4FontKey];
    [self.leftAnswerTextView addObserver:self
                              forKeyPath:NSStringFromSelector(@selector(contentSize))
                                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                                 context:&KVOContext];
    self.leftAnswerTextView.text = self.leftAnswerPrompt.text; // temporarily
    self.leftAnswerTextView.inputAccessoryView = [self inputAccessoryViewForTextView:self.leftAnswerTextView];
    ((VContentInputAccessoryView *)self.leftAnswerTextView.inputAccessoryView).maxCharacterLength = VConstantsPollAnswerLength;
    
    self.rightAnswerTextView.textColor = [self.dependencyManager colorForKey:VDependencyManagerMainTextColorKey];
    self.rightAnswerTextView.tintColor = [self.dependencyManager colorForKey:VDependencyManagerMainTextColorKey];
    self.rightAnswerTextView.font      = [self.dependencyManager fontForKey:VDependencyManagerHeading4FontKey];
    [self.rightAnswerTextView addObserver:self
                               forKeyPath:NSStringFromSelector(@selector(contentSize))
                                  options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                                  context:&KVOContext];
    self.rightAnswerTextView.text = self.rightAnswerPrompt.text; // temporarily
    self.rightAnswerTextView.inputAccessoryView = [self inputAccessoryViewForTextView:self.rightAnswerTextView];
    ((VContentInputAccessoryView *)self.rightAnswerTextView.inputAccessoryView).maxCharacterLength = VConstantsPollAnswerLength;
    
    [self.answersSuperview addConstraint:[NSLayoutConstraint constraintWithItem:self.leftAnswerTextView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.answersSuperview
                                                                      attribute:NSLayoutAttributeTop
                                                                     multiplier:1.0f
                                                                       constant:30.0f]];
    [self.answersSuperview addConstraint:[NSLayoutConstraint constraintWithItem:self.rightAnswerTextView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.answersSuperview
                                                                      attribute:NSLayoutAttributeTop
                                                                     multiplier:1.0f
                                                                       constant:30.0f]];
    
    self.leftAnswerPrompt.text      = NSLocalizedString(@"Vote this", @"");
    self.leftAnswerPrompt.font      = [self.dependencyManager fontForKey:VDependencyManagerHeading4FontKey];

    self.rightAnswerPrompt.text      = NSLocalizedString(@"Vote that", @"");
    self.rightAnswerPrompt.font      = [self.dependencyManager fontForKey:VDependencyManagerHeading4FontKey];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor blackColor]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    NSString *nextText = NSLocalizedString(@"Publish", @"");
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:nextText
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(postButtonAction:)];
    [self.navigationItem setRightBarButtonItem:nextButton];

    [self updateViewState];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!self.textViewsCleared)
    {
        self.leftAnswerTextView.text = @"";
        self.rightAnswerTextView.text = @"";
        self.textViewsCleared = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[VTrackingManager sharedInstance] setValue:VTrackingValueCreatePoll forSessionParameterWithKey:VTrackingKeyContext];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ( self.isBeingDismissed )
    {
        [[VTrackingManager sharedInstance] clearValueForSessionParameterWithKey:VTrackingKeyContext];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)postButtonStateIsValid ///<Surfaces alert if content cannot be posted.  Returns YES if it can be posted and NO if it cannot.
{
    //These should have already been trimmed by the textViewDidEndEditing: call.  But lets verify that they are trimmed.
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    self.questionTextView.text = [self.questionTextView.text stringByTrimmingCharactersInSet:whitespaceSet];
    self.leftAnswerTextView.text = [self.leftAnswerTextView.text stringByTrimmingCharactersInSet:whitespaceSet];
    self.rightAnswerTextView.text = [self.rightAnswerTextView.text stringByTrimmingCharactersInSet:whitespaceSet];
    
    NSString *errorMessage = @"";
    if (!self.firstMediaURL || !self.secondMediaURL)
    {
        errorMessage = [errorMessage stringByAppendingString:NSLocalizedString(@"MissingMedia", nil)];
        errorMessage = [errorMessage stringByAppendingString:@"\n"];
    }
    if ([self.questionTextView.text lengthWithUnicode] < kMinLength)
    {
        errorMessage = [errorMessage stringByAppendingString:NSLocalizedString(@"QuestionTextToShort", nil)];
        errorMessage = [errorMessage stringByAppendingString:@"\n"];
    }
    if ([self.leftAnswerTextView.text lengthWithUnicode] < kMinLength || [self.rightAnswerTextView.text lengthWithUnicode] < kMinLength)
    {
        errorMessage = [errorMessage stringByAppendingString:NSLocalizedString(@"AnswerTextToShort", nil)];
    }
    
    if (errorMessage.length > 0)
    {
        NSDictionary *params = @{ VTrackingKeyErrorMessage : errorMessage ?: @"" };
        [[VTrackingManager sharedInstance] trackEvent:VTrackingEventPollDidFailValidation parameters:params];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Missing Content", nil)
                                                                                 message:errorMessage
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return NO;
    }

    return YES;
}

- (void)updateViewState
{
    if (self.firstMediaURL)
    {
        self.leftPreviewImageView.alpha = 1.0f;
        self.leftRemoveButton.alpha = 1.0f;
    }
    else
    {
        self.leftPreviewImageView.alpha = 0.0f;
        self.leftRemoveButton.alpha = 0.0f;
    }
    
    if (self.secondMediaURL)
    {
        self.rightPreviewImageView.alpha = 1.0f;
        self.rightRemoveButton.alpha = 1.0f;
    }
    else
    {
        self.rightPreviewImageView.alpha = 0.0f;
        self.rightRemoveButton.alpha = 0.0f;
    }

    if (self.firstMediaURL)
    {
        self.mediaButtonLeftSpacingConstraint.constant = CGRectGetWidth(self.view.bounds) / 2;
    }
    else
    {
        self.mediaButtonLeftSpacingConstraint.constant = 0.0f;
    }

    if (self.firstMediaURL && self.secondMediaURL)
    {
        self.addMediaView.alpha = 0.0f;
    }
    else
    {
        self.addMediaView.alpha = 1.0f;
    }
    
    [self.view layoutIfNeeded];
}

#pragma mark - Actions

- (IBAction)imageAction:(id)sender
{
    NSString *defaultSearchTerm = nil;
    if (self.firstMediaURL == nil)
    {
        defaultSearchTerm = self.leftAnswerTextView.text;
    }
    else if (self.secondMediaURL == nil)
    {
        defaultSearchTerm = self.rightAnswerTextView.text;
    }
    
    [self showAttachmentWithAttachmentOptions:VMediaAttachmentOptionsImage defaultSearchTerm:defaultSearchTerm];
}

- (IBAction)videoAction:(id)sender
{
    [self showAttachmentWithAttachmentOptions:VMediaAttachmentOptionsVideo defaultSearchTerm:nil];
}

- (void)showAttachmentWithAttachmentOptions:(VMediaAttachmentOptions)attachmentOptions
                          defaultSearchTerm:(NSString *)defaultSearchTerm
{
    if (defaultSearchTerm != nil && attachmentOptions == VMediaAttachmentOptionsImage)
    {
        self.attachmentPresenter = [[VMediaAttachmentPresenter alloc] initWithDependencyManager:self.dependencyManager
                                                                              addedDependencies:@{VImageCreationFlowControllerDefaultSearchTermKey: defaultSearchTerm}];
    }
    else
    {
        self.attachmentPresenter = [[VMediaAttachmentPresenter alloc] initWithDependencyManager:self.dependencyManager];
    }

    __weak typeof(self) welf = self;
    self.attachmentPresenter.attachmentTypes = attachmentOptions;
    self.attachmentPresenter.resultHandler = ^void(BOOL success, VPublishParameters *publishParameters)
    {
        [welf imagePickerFinishedWithURL:publishParameters.mediaToUploadURL
                            previewImage:publishParameters.previewImage];
        [welf dismissViewControllerAnimated:YES
                                 completion:nil];
    };
    [self.attachmentPresenter presentOnViewController:self];
}

- (IBAction)clearLeftMedia:(id)sender
{
    UIView *temporaryLeftPreviewView = [self.leftPreviewImageView snapshotViewAfterScreenUpdates:NO];
    temporaryLeftPreviewView.frame = self.leftPreviewImageView.frame;
    [self.answersSuperview addSubview:temporaryLeftPreviewView];
    
    self.leftPreviewImageView.hidden = YES;

    if (self.firstMediaURL)
    {
        [[NSFileManager defaultManager] removeItemAtURL:self.firstMediaURL error:nil];
    }
    
    self.firstMediaURL = nil;
    self.leftPreviewImageView.image = nil;

    if (self.secondMediaURL)
    {
        self.mediaButtonLeftSpacingConstraint.constant = 0;
        [self.answersSuperview layoutIfNeeded];
    }
    [UIView animateWithDuration:0.2f
                     animations:^(void)
    {
        temporaryLeftPreviewView.transform = CGAffineTransformMakeScale(0.6f, 0.6f);
        temporaryLeftPreviewView.alpha = 0;
        [self updateViewState];
    }
                     completion:^(BOOL finished)
    {
        [temporaryLeftPreviewView removeFromSuperview];
        self.leftPreviewImageView.hidden = NO;
    }];
}

- (IBAction)clearRightMedia:(id)sender
{
    UIView *temporaryRightPreviewView = [self.rightPreviewImageView snapshotViewAfterScreenUpdates:NO];
    temporaryRightPreviewView.frame = self.rightPreviewImageView.frame;
    [self.answersSuperview addSubview:temporaryRightPreviewView];
    
    self.rightPreviewImageView.hidden = YES;

    if (self.secondMediaURL)
    {
        [[NSFileManager defaultManager] removeItemAtURL:self.secondMediaURL error:nil];
    }
    self.secondMediaURL = nil;
    self.rightPreviewImageView.image = nil;

    [UIView animateWithDuration:0.2f
                     animations:^(void)
    {
        temporaryRightPreviewView.transform = CGAffineTransformMakeScale(0.6f, 0.6f);
        temporaryRightPreviewView.alpha = 0;
        [self updateViewState];
    }
                     completion:^(BOOL finished)
    {
        [temporaryRightPreviewView removeFromSuperview];
        self.rightPreviewImageView.hidden = NO;
    }];
}

- (IBAction)postButtonAction:(id)sender
{
    if (![self postButtonStateIsValid])
    {
        return;
    }
    
    [self createPoll];
    
    NSDictionary *params = @{ VTrackingKeyContentType : VTrackingValuePoll };
    [[VTrackingManager sharedInstance] trackEvent:VTrackingEventUserDidPublishContent parameters:params];
    
    self.didPublish = YES;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    if (self.completionHandler)
    {
        self.completionHandler(VCreatePollViewControllerResultDone);
        self.completionHandler = nil;
    }
}

- (VContentInputAccessoryView *)inputAccessoryViewForTextView:(UITextView *)textView
{
    VContentInputAccessoryView *contentInputAccessory = [[VContentInputAccessoryView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
    contentInputAccessory.textInputView = textView;
    contentInputAccessory.tintColor = [UIColor colorWithRed:0.85f green:0.86f blue:0.87f alpha:1.0f];
    return contentInputAccessory;
}

- (IBAction)cancel:(id)sender
{
    if (self.completionHandler)
    {
        self.completionHandler(VCreatePollViewControllerResultCancelled);
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return NO;
    }
    
    NSUInteger characterLimit = ((VContentInputAccessoryView *)textView.inputAccessoryView).maxCharacterLength;
    if ((text.length + textView.text.length >  characterLimit) && (characterLimit > 0) )
    {
        return NO;
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ( textView == self.questionTextView )
    {
        self.questionPrompt.hidden = YES;
    }
    else if ( textView == self.leftAnswerTextView )
    {
        self.leftAnswerPrompt.hidden = YES;
    }
    else if ( textView == self.rightAnswerTextView )
    {
        self.rightAnswerPrompt.hidden = YES;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    textView.text = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (textView == self.questionTextView)
    {
        self.questionPrompt.hidden = textView.text.length > 0;
    }
    else if (textView == self.leftAnswerTextView)
    {
        self.leftAnswerPrompt.hidden = textView.text.length > 0;
    }
    else if (textView == self.rightAnswerTextView)
    {
        self.rightAnswerPrompt.hidden = textView.text.length > 0;
    }
}

#pragma mark -

- (void)imagePickerFinishedWithURL:(NSURL *)mediaURL
                      previewImage:(UIImage *)previewImage
{
    if (!self.firstMediaURL)
    {
        self.firstMediaURL = mediaURL;
        self.leftPreviewImageView.image = previewImage;
    }
    else
    {
        self.secondMediaURL = mediaURL;
        self.rightPreviewImageView.image = previewImage;
    }
    
    [self updateViewState];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != &KVOContext)
    {
        return;
    }
    
    if (object == self.leftAnswerTextView && [keyPath isEqualToString:NSStringFromSelector(@selector(contentSize))])
    {
        NSValue *newContentSize = change[NSKeyValueChangeNewKey];
        if (newContentSize && (id)newContentSize != [NSNull null])
        {
            NSValue *oldContentSize = change[NSKeyValueChangeOldKey];
            if (oldContentSize && (id)oldContentSize != [NSNull null] &&
                [oldContentSize CGSizeValue].height == [newContentSize CGSizeValue].height)
            {
                return;
            }
            
            void (^animations)(void) = ^(void)
            {
                self.leftAnswerTextViewHeightConstraint.constant = [newContentSize CGSizeValue].height;
                [self.answersSuperview layoutIfNeeded];
            };
            if (self.textViewsCleared)
            {
                [UIView animateWithDuration:0.2
                                      delay:0
                                    options:UIViewAnimationOptionCurveLinear
                                 animations:animations
                                 completion:nil];
            }
            else
            {
                animations();
            }
        }
    }
    else if (object == self.rightAnswerTextView && [keyPath isEqualToString:NSStringFromSelector(@selector(contentSize))])
    {
        NSValue *newContentSize = change[NSKeyValueChangeNewKey];
        if (newContentSize && (id)newContentSize != [NSNull null])
        {
            NSValue *oldContentSize = change[NSKeyValueChangeOldKey];
            if (oldContentSize && (id)oldContentSize != [NSNull null] &&
                [oldContentSize CGSizeValue].height == [newContentSize CGSizeValue].height)
            {
                return;
            }
            
            void (^animations)(void) = ^(void)
            {
                self.rightAnswerTextViewHeightConstraint.constant = [newContentSize CGSizeValue].height;
                [self.answersSuperview layoutIfNeeded];
            };
            if (self.textViewsCleared)
            {
                [UIView animateWithDuration:0.2
                                      delay:0
                                    options:UIViewAnimationOptionCurveLinear
                                 animations:animations
                                 completion:nil];
            }
            else
            {
                animations();
            }
        }
    }
}

@end
