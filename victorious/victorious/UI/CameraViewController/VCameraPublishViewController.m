//
//  VCameraPublishViewController.m
//  victorious
//
//  Created by Gary Philipp on 2/27/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

@import AVFoundation;

#import "VCameraPublishViewController.h"
#import "VContentInputAccessoryView.h"
#import "VSetExpirationViewController.h"
#import "UIImage+ImageEffects.h"
#import "VObjectManager+ContentCreation.h"
#import "VConstants.h"
#import "NSString+VParseHelp.h"
#import "VThemeManager.h"

@interface VCameraPublishViewController () <UITextViewDelegate, VSetExpirationDelegate>
@property (nonatomic, weak) IBOutlet    UIImageView*    previewImageView;

@property (nonatomic, weak) IBOutlet    UIButton*       durationButton;
@property (nonatomic, weak) IBOutlet    UILabel*        expiresOnLabel;

@property (nonatomic, weak) IBOutlet    UISwitch*       twitterButton;
@property (nonatomic, weak) IBOutlet    UISwitch*       facebookButton;

@property (nonatomic, weak) IBOutlet    UILabel*        textViewPlaceholderLabel;

@end

@implementation VCameraPublishViewController

+ (VCameraPublishViewController *)cameraPublishViewController
{
    return [[UIStoryboard storyboardWithName:@"Camera" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(self)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *previewImageView = self.previewImageView;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[previewImageView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previewImageView)]];
    
    VContentInputAccessoryView *contentInputAccessory = [[VContentInputAccessoryView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
    contentInputAccessory.textInputView = self.textView;
    self.textView.inputAccessoryView = contentInputAccessory;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.previewImage)
    {
        self.previewImageView.image = [self.previewImage applyDarkEffect];
    }

    self.view.backgroundColor = [[VThemeManager sharedThemeManager] themedColorForKey:kVBackgroundColor];
    
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
    self.navigationController.navigationBar.translucent = YES;

    UIImage*    cancelButtonImage = [[UIImage imageNamed:@"cameraButtonClose"]  imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem*    cancelButton = [[UIBarButtonItem alloc] initWithImage:cancelButtonImage style:UIBarButtonItemStyleBordered target:self action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    [self.textView becomeFirstResponder];
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

#pragma mark - Actions

- (IBAction)goBack:(id)sender
{
    if (self.completion)
    {
        self.completion(NO);
    }
}

- (IBAction)cancel:(id)sender
{
    if (self.completion)
    {
        self.completion(YES);
    }
}

- (IBAction)hashButtonClicked:(id)sender
{
    self.textView.text = [self.textView.text stringByAppendingString:@"#"];
    if ([self respondsToSelector:@selector(textViewDidChange:)])
    {
        [self textViewDidChange:self.textView];
    }
}

- (IBAction)publish:(id)sender
{
    VLog (@"Publishing");
    
    if ([self.textView.text isEmpty])
    {
        UIAlertView*    alert   = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PublishDescriptionRequired", @"")
                                                             message:NSLocalizedString(@"PublishDescription", @"")
                                                            delegate:nil
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:NSLocalizedString(@"OKButton", @""), nil];
        [alert show];
        return;
    }
    
    VShareOptions shareOptions = self.useFacebook ? kVShareToFacebook : kVShareNone;
    shareOptions = self.useTwitter ? shareOptions | kVShareToTwitter : shareOptions;
    
    CGFloat playbackSpeed;
    if (self.playBackSpeed == kVPlaybackNormalSpeed)
        playbackSpeed = 1.0;
    else if (self.playBackSpeed == kVPlaybackDoubleSpeed)
        playbackSpeed = 2.0;
    else
        playbackSpeed = 0.5;
    
    [[VObjectManager sharedManager] uploadMediaWithName:self.textView.text
                                            description:self.textView.text
                                              expiresAt:self.expirationDateString
                                           parentNodeId:@(self.parentID)
                                                  speed:playbackSpeed
                                               loopType:self.playbackLooping
                                           shareOptions:shareOptions
                                               mediaURL:self.mediaURL
                                           successBlock:^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        VLog(@"Succeeded with objects: %@", resultObjects);
        
        UIAlertView*    alert   = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PublishSucceeded", @"")
                                                             message:NSLocalizedString(@"PublishSucceededDetail", @"")
                                                            delegate:nil
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:NSLocalizedString(@"OKButton", @""), nil];
        [alert show];
    }
                                              failBlock:^(NSOperation* operation, NSError* error)
    {
        VLog(@"Failed with error: %@", error);
        
        if (kVStillTranscodingError == error.code)
        {
            UIAlertView*    alert   = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"TranscodingMediaTitle", @"")
                                                                 message:NSLocalizedString(@"TranscodingMediaBody", @"")
                                                                delegate:nil
                                                       cancelButtonTitle:nil
                                                       otherButtonTitles:NSLocalizedString(@"OKButton", @""), nil];
            [alert show];
        }
        else
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UploadFailedTitle", @"")
                                                            message:NSLocalizedString(@"UploadErrorBody", @"")
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:NSLocalizedString(@"OKButton", @""), nil];
            [alert show];
        }
    }
                                      shouldRemoveMedia:YES];
    
    if (self.completion)
    {
        self.completion(YES);
    }
}

- (IBAction)twitterClicked:(id)sender
{
    self.useTwitter = self.twitterButton.on;
}

- (IBAction)facebookClicked:(id)sender
{
    self.useFacebook = self.facebookButton.on;
}

#pragma mark - Delegates

- (void)setExpirationViewController:(VSetExpirationViewController *)viewController didSelectDate:(NSDate *)expirationDate
{
    self.expirationDateString = [self stringForRFC2822Date:expirationDate];
    self.expiresOnLabel.text = [NSString stringWithFormat:NSLocalizedString(@"ExpiresOn", @""), [NSDateFormatter localizedStringFromDate:expirationDate
                                                                                                                               dateStyle:NSDateFormatterLongStyle
                                                                                                                               timeStyle:NSDateFormatterShortStyle]];
}

#pragma mark - Support

- (NSString *)stringForRFC2822Date:(NSDate *)date
{
    static NSDateFormatter *sRFC2822DateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sRFC2822DateFormatter = [[NSDateFormatter alloc] init];
        sRFC2822DateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z"; //RFC2822-Format
        
        [sRFC2822DateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    });
    
    return [sRFC2822DateFormatter stringFromDate:date];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    self.textViewPlaceholderLabel.hidden = ([textView.text length] > 0);
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return NO;
    }

    BOOL    isDeleteKey = ([text isEqualToString:@""]);
    if ((textView.text.length >= VConstantsMessageLength) && (!isDeleteKey))
        return NO;
    
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.textViewPlaceholderLabel.hidden = ([textView.text length] > 0);
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"setExpiration"])
    {
        VSetExpirationViewController*   viewController = (VSetExpirationViewController *)segue.destinationViewController;
        viewController.delegate = self;
        viewController.previewImage = self.previewImageView.image;
    }
}

@end
