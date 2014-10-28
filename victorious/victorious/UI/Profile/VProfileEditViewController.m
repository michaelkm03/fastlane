//
//  VProfileEditViewController.m
//  victorious
//
//  Created by Kevin Choi on 1/5/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VAnalyticsRecorder.h"
#import "VProfileEditViewController.h"
#import "VSettingManager.h"
#import "VUser.h"
#import "MBProgressHUD.h"

#import "VObjectManager+Login.h"
#import "VThemeManager.h"

#import "VUserProfileViewController.h"
#import "UIViewController+VNavMenu.h"

@interface VProfileEditViewController ()

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

@end

@implementation VProfileEditViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.nameLabel setTextColor:[[VThemeManager sharedThemeManager] themedColorForKey:kVContentTextColor]];
    self.nameLabel.text = self.profile.name;
    
    [self.usernameTextField becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.profile)
    {
        VUserProfileViewController *userProfile = self.navigationController.viewControllers.firstObject;
        self.profile = userProfile.profile;
    }
    
    [self.parentViewController.navHeaderView setRightButtonTitle:NSLocalizedString(@"Save", nil)
                                                      withAction:@selector(done:) onTarget:self];
    
    UIEdgeInsets insets = self.tableView.contentInset;
    insets.top = CGRectGetHeight(self.parentViewController.navHeaderView.frame);
    self.tableView.contentInset = insets;
    
//    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[VAnalyticsRecorder sharedAnalyticsRecorder] startAppView:@"Profile Edit"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[VAnalyticsRecorder sharedAnalyticsRecorder] finishAppView];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

#pragma mark - Actions

- (IBAction)done:(UIBarButtonItem *)sender
{
    [[self view] endEditing:YES];
    
    if (![self validateInputs])
    {
        return;
    }
    sender.enabled = NO;
    
    [[VAnalyticsRecorder sharedAnalyticsRecorder] sendEventWithCategory:kVAnalyticsEventCategoryInteraction action:@"Save Profile" label:nil value:nil];

    MBProgressHUD  *progressHUD =   [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progressHUD.labelText = NSLocalizedString(@"JustAMoment", @"");
    progressHUD.detailsLabelText = NSLocalizedString(@"ProfileSave", @"");

    [[VObjectManager sharedManager] updateVictoriousWithEmail:nil
                                                     password:nil
                                                         name:self.usernameTextField.text
                                              profileImageURL:self.updatedProfileImage
                                                     location:self.locationTextField.text
                                                      tagline:self.taglineTextView.text
                                                 successBlock:^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
    {
        [progressHUD hide:YES];
        [self.navigationController popViewControllerAnimated:YES];
    }
                                                    failBlock:^(NSOperation *operation, NSError *error)
    {
        [progressHUD hide:YES];
        sender.enabled = YES;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"ProfileSaveFail", @"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OKButton", @"")
                                              otherButtonTitles:nil];
        [alert show];
    }];
}

/**
 Validates input fields and displays an alert
 to the user if their input is not valid.
 
 @return YES if all inputs were valid, NO
         otherwise
 */
- (BOOL)validateInputs
{
    if (self.usernameTextField.text.length && self.locationTextField.text.length)
    {
        return YES;
    }
    
    // Identify Which Form Field is Missing
    NSMutableString *errorMsg = [[NSMutableString alloc] initWithString:NSLocalizedString(@"ProfileRequired", @"")];
    
    if (!self.usernameTextField.text.length)
    {
        [errorMsg appendFormat:@"\n%@", NSLocalizedString(@"ProfileRequiredName", @"")];
    }
    
    if (!self.locationTextField.text.length)
    {
        [errorMsg appendFormat:@"\n%@", NSLocalizedString(@"ProfileRequiredLoc", @"")];
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ProfileIncomplete", @"")
                                                    message:errorMsg
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"OKButton", @""), nil];
    [alert show];
    
    return NO;
}

- (IBAction)goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
