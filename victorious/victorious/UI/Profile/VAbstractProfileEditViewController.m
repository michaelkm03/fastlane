//
//  VProfileEditViewController.m
//  victorious
//
//  Created by Gary Philipp on 1/30/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VAbstractProfileEditViewController.h"
#import "VCameraViewController.h"
#import "VUser.h"
#import "UIImageView+Blurring.h"
#import "UIImage+ImageEffects.h"
#import "VThemeManager.h"

@interface VAbstractProfileEditViewController ()

@property (nonatomic, weak) IBOutlet UITableViewCell *captionCell;
@property (nonatomic, assign) NSInteger numberOfLines;

@end

@implementation VAbstractProfileEditViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.usernameTextField.delegate = self;
    self.locationTextField.delegate = self;
    self.taglineTextView.delegate = self;
    
    self.profileImageView.layer.masksToBounds = YES;
    self.profileImageView.layer.cornerRadius = CGRectGetHeight(self.profileImageView.bounds)/2;
    self.profileImageView.clipsToBounds = YES;
    
    self.cameraButton.layer.masksToBounds = YES;
    self.cameraButton.layer.cornerRadius = CGRectGetHeight(self.cameraButton.bounds)/2;
    self.cameraButton.clipsToBounds = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [self restoreInsets];
    
    self.usernameTextField.tintColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVLinkColor];
    self.locationTextField.tintColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVLinkColor];
    self.taglineTextView.tintColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVLinkColor];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath compare:[NSIndexPath indexPathForRow:3 inSection:0]] == NSOrderedSame)
    {
        return [self.taglineTextView sizeThatFits:CGSizeMake(CGRectGetWidth(self.taglineTextView.bounds), FLT_MAX)].height + 15;
    }
    return [super tableView:tableView
    heightForRowAtIndexPath:indexPath];
}

#pragma mark - Property Accessors

- (void)setProfile:(VUser *)profile
{
    NSAssert([NSThread isMainThread], @"");
    _profile = profile;
 
    self.usernameTextField.text = profile.name;
    self.taglineTextView.text = profile.tagline;
    self.locationTextField.text = profile.location;
    
    self.tagLinePlaceholderLabel.hidden = (profile.tagline.length > 0);
    
    //  Set background image
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.tableView.backgroundView.frame];
    [backgroundImageView setBlurredImageWithURL:[NSURL URLWithString:profile.pictureUrl]
                               placeholderImage:[UIImage imageNamed:@"profileGenericUser"]
                                      tintColor:[UIColor colorWithWhite:1.0 alpha:0.3]];
    
    self.tableView.backgroundView = backgroundImageView;

    
    NSURL  *imageURL    =   [NSURL URLWithString:profile.pictureUrl];
    [self.profileImageView setImageWithURL:imageURL placeholderImage:nil];
}

#pragma mark - Actions

- (IBAction)takePicture:(id)sender
{
    UINavigationController *navigationController = [[UINavigationController alloc] init];
    VCameraViewController *cameraViewController = [VCameraViewController cameraViewControllerLimitedToPhotos];
    cameraViewController.completionBlock = ^(BOOL finished, UIImage *previewImage, NSURL *capturedMediaURL)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
        if (finished && capturedMediaURL)
        {
            self.profileImageView.image = previewImage;
            self.updatedProfileImage = capturedMediaURL;
        }
    };
    [navigationController pushViewController:cameraViewController animated:NO];
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    self.tagLinePlaceholderLabel.hidden = ([textView.text length] > 0);

    if (self.numberOfLines == (self.taglineTextView.contentSize.height / self.taglineTextView.font.lineHeight))
    {
        return;
    }
    
    self.numberOfLines = self.taglineTextView.contentSize.height / self.taglineTextView.font.lineHeight;
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.tagLinePlaceholderLabel.hidden = ([textView.text length] > 0);
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound)
    {
        [textView resignFirstResponder];
    }

    return YES;
}

#pragma mark - Notification Handlers

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSNumber *durationValue = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration = durationValue.doubleValue;
    
    NSNumber *curveValue = notification.userInfo[UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIEdgeInsets modifiedInsets = self.tableView.contentInset;
    modifiedInsets.bottom = CGRectGetHeight(endFrame);
    
    [UIView animateWithDuration:animationDuration
                          delay:0.0
                        options:(animationCurve << 16) | UIViewAnimationOptionBeginFromCurrentState
                     animations:^
     {
         self.tableView.contentInset = modifiedInsets;
         self.tableView.scrollIndicatorInsets = modifiedInsets;
     }
                     completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSNumber *durationValue = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration = durationValue.doubleValue;
    
    NSNumber *curveValue = notification.userInfo[UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    
    [UIView animateWithDuration:animationDuration
                          delay:0.0
                        options:(animationCurve << 16) | UIViewAnimationOptionBeginFromCurrentState
                     animations:^
     {
         [self restoreInsets];
     }
                     completion:nil];
}

#pragma mark - Private Methods

- (void)restoreInsets
{
    UIEdgeInsets insets = UIEdgeInsetsMake(CGRectGetHeight(self.navigationController.navigationBar.bounds) +
                                           CGRectGetHeight([UIApplication sharedApplication].statusBarFrame), 0, 0, 0);
    self.tableView.contentInset = insets;
    self.tableView.scrollIndicatorInsets = insets;
}

@end
