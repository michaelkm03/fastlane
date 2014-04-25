//
//  VCreatePollViewController.m
//  victorious
//
//  Created by David Keegan on 1/8/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

@import AVFoundation;

#import "VCameraViewController.h"
#import "VCreatePollViewController.h"
#import "VThemeManager.h"
#import "VConstants.h"
#import "NSString+VParseHelp.h"

static const CGFloat VCreateViewControllerPadding = 8;
static const CGFloat VCreateViewControllerLargePadding = 20;

@interface VCreatePollViewController() <UITextFieldDelegate, UITextViewDelegate>

@property (strong, nonatomic) NSURL *mediaURL;
@property (strong, nonatomic) NSURL *secondMediaURL;

@property (strong, nonatomic) NSString *mediaType;
@property (strong, nonatomic) NSString *secondMediaType;

@property (weak, nonatomic) NSLayoutConstraint *contentTopConstraint;

@end

@implementation VCreatePollViewController

+ (instancetype)newCreatePollViewControllerWithDelegate:(id<VCreateSequenceDelegate>)delegate
{
    UIViewController*   currentViewController = [[UIApplication sharedApplication] delegate].window.rootViewController;
    VCreatePollViewController* createView = (VCreatePollViewController*)[currentViewController.storyboard instantiateViewControllerWithIdentifier: NSStringFromClass([VCreatePollViewController class])];
    createView.delegate = delegate;
    return createView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.title = NSLocalizedString(@"New Poll", @"New poll title");
    
    UIImage* newImage = [self.mediaButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.mediaButton setImage:newImage forState:UIControlStateNormal];
    self.mediaButton.tintColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVMainTextColor];
    self.mediaButton.backgroundColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVLinkColor];
    self.mediaButton.layer.cornerRadius = self.mediaButton.frame.size.height/2;

    newImage = [self.searchImageButton.imageView.image
                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.searchImageButton setImage:newImage forState:UIControlStateNormal];
    self.searchImageButton.tintColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVMainTextColor];
    self.searchImageButton.backgroundColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVLinkColor];
    self.searchImageButton.layer.cornerRadius = self.searchImageButton.frame.size.height/2;
    
    newImage = [self.removeMediaButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.rightRemoveButton setImage:newImage forState:UIControlStateNormal];
    self.rightRemoveButton.tintColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVLinkColor];
    
    newImage = [self.removeMediaButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.removeMediaButton setImage:newImage forState:UIControlStateNormal];
    self.removeMediaButton.tintColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVLinkColor];
    self.removeMediaButton.hidden = NO;
    
    self.addMediaView.translatesAutoresizingMaskIntoConstraints = YES;
    self.rightPreviewImageView.translatesAutoresizingMaskIntoConstraints = YES;

    self.questionTextField.textColor =  [[VThemeManager sharedThemeManager] themedColorForKey:kVContentTextColor];
    self.questionTextField.placeholder = NSLocalizedString(@"Ask a Question...", @"Poll question placeholder");

    self.leftAnswerTextField.textColor =  [[VThemeManager sharedThemeManager] themedColorForKey:kVContentTextColor];
    self.leftAnswerTextField.placeholder = NSLocalizedString(@"VOTE THIS...", @"Poll left question placeholder");
    
    self.rightAnswerTextField.textColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVContentTextColor];
    self.rightAnswerTextField.placeholder = NSLocalizedString(@"VOTE THAT...", @"Poll left question placeholder");
    
    self.textView.font = [[VThemeManager sharedThemeManager] themedFontForKey:kVHeading4Font];
    self.textView.textColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVMainTextColor];
    self.textView.layer.borderColor = [[[VThemeManager sharedThemeManager] themedColorForKey:kVAccentColor] CGColor];
    self.textView.layer.borderWidth = 1;
    
    self.postButton.tintColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVMainTextColor];
    self.postButton.backgroundColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVLinkColor];
    [self.postButton setTitle:NSLocalizedString(@"POST IT", @"Post button") forState:UIControlStateNormal];
    self.postButton.titleLabel.font = [[VThemeManager sharedThemeManager] themedFontForKey:kVHeading4Font];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(keyboardFrameChanged:)
     name:UIKeyboardWillChangeFrameNotification object:nil];
    
    [self validatePostButtonState];
    [self updateViewState];
}

- (void)validatePostButtonState
{
    [self.postButton setEnabled:YES];
    
    if(!self.mediaURL || !self.secondMediaURL)
        [self.postButton setEnabled:NO];
    
    else if([self.questionTextField.text isEmpty])
        [self.postButton setEnabled:NO];

    else if([self.questionTextField.text length] > VConstantsForumTitleLength)
        [self.postButton setEnabled:NO];
    
    else if([self.leftAnswerTextField.text isEmpty])
        [self.postButton setEnabled:NO];

    else if([self.leftAnswerTextField.text length] > VConstantsForumTitleLength)
        [self.postButton setEnabled:NO];
    
    else if([self.rightAnswerTextField.text isEmpty])
        [self.postButton setEnabled:NO];

    else if([self.rightAnswerTextField.text length] > VConstantsForumTitleLength)
        [self.postButton setEnabled:NO];
}

- (void)updateViewState
{
    if(!self.secondMediaURL)
    {
        self.rightPreviewImageView.hidden = YES;
        self.rightRemoveButton.hidden = YES;
    }
    else
    {
        self.rightPreviewImageView.hidden = NO;
        self.rightRemoveButton.hidden = NO;
    }
}

#pragma mark - Actions

- (IBAction)mediaButtonAction:(id)sender
{
    VCameraViewController *cameraViewController = [VCameraViewController cameraViewController];
    cameraViewController.completionBlock = ^(BOOL finished, UIImage *previewImage, NSURL *capturedMediaURL, NSString *mediaExtension)
    {
        if (finished)
        {
            [self imagePickerFinishedWithURL:capturedMediaURL
                                   extension:mediaExtension
                                previewImage:previewImage];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    UINavigationController *navigationController = [[UINavigationController alloc] init];
    [navigationController pushViewController:cameraViewController animated:NO];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (IBAction)clearMedia:(id)sender
{
    self.addMediaView.userInteractionEnabled = NO;
    self.postButton.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:.5f
                     animations:^
     {
         CGRect addMediaFrame = self.addMediaView.frame;
         self.addMediaView.frame = CGRectMake(CGRectGetMinX(addMediaFrame) - CGRectGetWidth(addMediaFrame), CGRectGetMinY(addMediaFrame), CGRectGetWidth(addMediaFrame), CGRectGetHeight(addMediaFrame));
         
         CGRect rightPreviewFrame = self.rightPreviewImageView.frame;
         self.rightPreviewImageView.frame = CGRectMake(CGRectGetMinX(rightPreviewFrame) - CGRectGetWidth(addMediaFrame), CGRectGetMinY(rightPreviewFrame), CGRectGetWidth(rightPreviewFrame), CGRectGetHeight(rightPreviewFrame));
     }
                     completion:^(BOOL finished)
     {
         self.addMediaView.userInteractionEnabled = YES;
         self.postButton.userInteractionEnabled = YES;
         
         if (!self.secondMediaURL)
         {
             [[NSFileManager defaultManager] removeItemAtURL:self.mediaURL error:nil];
         }
         
         self.mediaURL = self.secondMediaURL;
         self.mediaType = self.secondMediaType;
         self.previewImageView.image = self.rightPreviewImageView.image;
         
         if (self.secondMediaURL)
         {
             [[NSFileManager defaultManager] removeItemAtURL:self.secondMediaURL error:nil];
         }
         self.secondMediaURL = nil;
         self.secondMediaType = nil;
         self.rightPreviewImageView.image = nil;
         
         [self updateViewState];
         
         CGRect frame = self.rightPreviewImageView.frame;
         self.rightPreviewImageView.frame = CGRectMake(CGRectGetMinX(frame) + CGRectGetWidth(self.addMediaView.frame), CGRectGetMinY(frame), CGRectGetWidth(frame), CGRectGetHeight(frame));
         
         [self validatePostButtonState];
     }];
}

- (IBAction)clearRightMedia:(id)sender
{
    self.addMediaView.userInteractionEnabled = NO;
    self.postButton.userInteractionEnabled = NO;

    [UIView animateWithDuration:.5f
                     animations:^
     {
         CGRect frame = self.addMediaView.frame;
         self.addMediaView.frame = CGRectMake(CGRectGetMinX(frame) - CGRectGetWidth(frame), CGRectGetMinY(frame), CGRectGetWidth(frame), CGRectGetHeight(frame));
     }
                     completion:^(BOOL finished)
     {
         self.addMediaView.userInteractionEnabled = YES;
         self.postButton.userInteractionEnabled = YES;
         
         if (self.secondMediaURL)
         {
             [[NSFileManager defaultManager] removeItemAtURL:self.secondMediaURL error:nil];
         }
         self.secondMediaURL = nil;
         self.secondMediaType = nil;
         self.rightPreviewImageView.image = nil;
         [self updateViewState];
         [self validatePostButtonState];
     }];
}

- (IBAction)postButtonAction:(id)sender
{
    [self.delegate createPollWithQuestion:self.questionTextField.text
                              answer1Text:self.leftAnswerTextField.text
                              answer2Text:self.rightAnswerTextField.text
                               media1URL:self.mediaURL
                          media1Extension:self.mediaType
                               media2URL:self.secondMediaURL
                          media2Extension:self.secondMediaType];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)closeButtonAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)searchImageAction:(id)sender
{
    //TODO:put search logic here
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self validatePostButtonState];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.questionTextField)
        [self.leftAnswerTextField becomeFirstResponder];

    if (textField == self.leftAnswerTextField)
        [self.rightAnswerTextField becomeFirstResponder];

    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Notifications

- (void)keyboardFrameChanged:(NSNotification *)notification
{
    CGRect keyboardEndFrame;
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    NSDictionary *userInfo = [notification userInfo];
    
    [userInfo[UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [userInfo[UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [userInfo[UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    [UIView animateWithDuration:animationDuration delay:0 options:(animationCurve << 16) animations:^
     {
         self.contentTopConstraint.constant = VCreateViewControllerLargePadding-MAX(0, CGRectGetMaxY(self.textView.frame)-CGRectGetMinY(keyboardEndFrame)+VCreateViewControllerPadding);
         [self.view layoutIfNeeded];
     }
                     completion:nil];
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView
{
    NSInteger characterCount = VConstantsMessageLength-[textView.text length];
    if(characterCount < 0)
    {
        self.characterCountLabel.textColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVMainTextColor];
    }
    else
    {
        self.characterCountLabel.textColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVMainTextColor];
    }
    self.characterCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)characterCount];
    [self validatePostButtonState];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

#pragma mark -

- (void)imagePickerFinishedWithURL:(NSURL *)mediaURL
                          extension:(NSString*)extension
                       previewImage:(UIImage*)previewImage
{
    if(!self.mediaURL)
    {
        self.mediaURL = mediaURL;
        self.mediaType = extension;
        self.previewImageView.image = previewImage;
    }
    else
    {
        self.secondMediaURL = mediaURL;
        self.secondMediaType = extension;
        self.rightPreviewImageView.image = previewImage;
    }
    
    self.addMediaView.userInteractionEnabled = NO;
    self.postButton.userInteractionEnabled = NO;
    
    [self updateViewState];
    
    [UIView animateWithDuration:.5f
                     animations:^
     {
         CGRect frame = self.addMediaView.frame;
         self.addMediaView.frame = CGRectMake(CGRectGetMinX(frame) + CGRectGetWidth(frame), CGRectGetMinY(frame), CGRectGetWidth(frame), CGRectGetHeight(frame));
     }
                     completion:^(BOOL finished)
     {
         self.addMediaView.userInteractionEnabled = YES;
         self.postButton.userInteractionEnabled = YES;
         
         [self validatePostButtonState];
     }];
}

@end