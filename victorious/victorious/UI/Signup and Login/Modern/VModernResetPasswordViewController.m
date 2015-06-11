//
//  VModernResetPasswordViewController.m
//  victorious
//
//  Created by Michael Sena on 5/26/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VModernResetPasswordViewController.h"

// Views + Helpers
#import "VLoginFlowControllerResponder.h"
#import "VPasswordValidator.h"
#import "VInlineValidationTextField.h"

// Dependencies
#import "VDependencyManager.h"
#import "VDependencyManager+VKeyboardStyle.h"
#import "VDependencyManager+VBackgroundContainer.h"

static NSString * const kPromptKey = @"prompt";
static NSString * const kKeyboardStyleKey = @"keyboardStyle";

@interface VModernResetPasswordViewController () <UITextFieldDelegate, VBackgroundContainer>

@property (nonatomic, strong) VDependencyManager *dependencyManager;

@property (nonatomic, strong) VPasswordValidator *passwordValidator;

@property (nonatomic, weak) IBOutlet UILabel *promptLabel;
@property (nonatomic, weak) IBOutlet VInlineValidationTextField *passwordTextField;
@property (nonatomic, weak) IBOutlet VInlineValidationTextField *confirmPasswordTextField;
@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *separators;

@end

@implementation VModernResetPasswordViewController

+ (instancetype)newWithDependencyManager:(VDependencyManager *)dependencyManager
{
    NSBundle *bundleForClass = [NSBundle bundleForClass:self];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self)
                                                         bundle:bundleForClass];
    VModernResetPasswordViewController *resetPasswordViewController = [storyboard instantiateInitialViewController];
    resetPasswordViewController.dependencyManager = dependencyManager;
    resetPasswordViewController.passwordValidator = [[VPasswordValidator alloc] init];
    return resetPasswordViewController;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    for (UIView *separator in self.separators)
    {
        separator.backgroundColor = [self.dependencyManager colorForKey:VDependencyManagerSecondaryAccentColorKey];
    }
    
    NSString *prompt = [self.dependencyManager stringForKey:kPromptKey] ?: @"";
    NSDictionary *promptAttributes = @{
                                       NSFontAttributeName: [self.dependencyManager fontForKey:VDependencyManagerHeading1FontKey],
                                       NSForegroundColorAttributeName: [self.dependencyManager colorForKey:VDependencyManagerContentTextColorKey]
                                       };
    self.promptLabel.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(prompt, nil)
                                                                      attributes:promptAttributes];
    
    NSDictionary *textFieldAttributes = @{
                                          NSFontAttributeName: [self.dependencyManager fontForKey:VDependencyManagerLabel1FontKey],
                                          NSForegroundColorAttributeName: [self.dependencyManager colorForKey:VDependencyManagerContentTextColorKey]
                                          };
    NSDictionary *placeholderTextFieldAttributes = @{
                                                     NSFontAttributeName: [self.dependencyManager fontForKey:VDependencyManagerLabel1FontKey],
                                                     NSForegroundColorAttributeName: [self.dependencyManager colorForKey:VDependencyManagerPlaceholderTextColorKey],
                                                     };
    self.passwordTextField.textColor = textFieldAttributes[NSForegroundColorAttributeName];
    self.passwordTextField.font = textFieldAttributes[NSFontAttributeName];
    self.passwordTextField.tintColor = [self.dependencyManager colorForKey:VDependencyManagerLinkColorKey];
    self.passwordTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter a new Password", nil)
                                                                                   attributes:placeholderTextFieldAttributes];
    self.passwordTextField.keyboardAppearance = [self.dependencyManager keyboardStyleForKey:kKeyboardStyleKey];
    
    self.confirmPasswordTextField.textColor = textFieldAttributes[NSForegroundColorAttributeName];
    self.confirmPasswordTextField.font = textFieldAttributes[NSFontAttributeName];
    self.confirmPasswordTextField.tintColor = [self.dependencyManager colorForKey:VDependencyManagerLinkColorKey];
    self.confirmPasswordTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Confirm your new password", nil)
                                                                                   attributes:textFieldAttributes];
    self.confirmPasswordTextField.keyboardAppearance = [self.dependencyManager keyboardStyleForKey:kKeyboardStyleKey];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:self.passwordTextField];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:self.confirmPasswordTextField];
    
    [self.dependencyManager addBackgroundToBackgroundHost:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.passwordTextField becomeFirstResponder];
}

#pragma mark - VBackgroundContainer

- (UIView *)backgroundContainerView
{
    return self.view;
}

#pragma mark - Notifications

- (void)textFieldDidChange:(NSNotification *)notification
{
    VInlineValidationTextField *textField = notification.object;
    [self validateWithTextField:textField];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(VInlineValidationTextField *)textField
{
    if ( textField.text.length > 0 )
    {
        [self validateWithTextField:textField];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.passwordTextField)
    {
        [self.confirmPasswordTextField becomeFirstResponder];
    }
    else if (textField == self.confirmPasswordTextField)
    {
        [self changePassword];
    }
    
    return NO;
}

#pragma mark - Validation

- (void)changePassword
{
    if ([self shouldChangePassword])
    {
        id<VLoginFlowControllerResponder> flowControllerResponder = [self targetForAction:@selector(updateWithNewPassword:)
                                                                               withSender:self];
        if (flowControllerResponder == nil)
        {
            NSAssert(false, @"We need a flow controller for changing password");
        }

        [flowControllerResponder updateWithNewPassword:self.passwordTextField.text];
    }
}

- (void)validateWithTextField:(VInlineValidationTextField *)textField
{
    NSError *validationError;
    
    if (textField == self.passwordTextField)
    {
        [self.passwordValidator setConfirmationObject:nil
                                          withKeyPath:nil];
        BOOL validPassword = [self.passwordValidator validateString:textField.text
                                                           andError:&validationError];
        if (!validPassword)
        {
            [textField showInvalidText:validationError.localizedDescription
                              animated:NO
                                 shake:NO
                                forced:NO];
        }
        else
        {
            [textField hideInvalidText];
        }
    }
    if (textField == self.confirmPasswordTextField)
    {
        [self.passwordValidator setConfirmationObject:self.confirmPasswordTextField
                                          withKeyPath:NSStringFromSelector(@selector(text))];
        BOOL validConfimration = [self.passwordValidator validateString:self.passwordTextField.text
                                                               andError:&validationError];
        if (!validConfimration)
        {
            [textField showInvalidText:validationError.localizedDescription
                              animated:NO
                                 shake:NO
                                forced:NO];
        }
        else
        {
            [textField hideInvalidText];
            [self.passwordTextField hideInvalidText];
        }
    }
}

- (BOOL)shouldChangePassword
{
    NSError *validationError;
    BOOL shouldChangePassword = YES;
    UIResponder *nextResponder = nil;
    
    [self.passwordValidator setConfirmationObject:nil withKeyPath:nil];
    if (![self.passwordValidator validateString:self.passwordTextField.text andError:&validationError])
    {
        [self.passwordTextField showInvalidText:validationError.localizedDescription
                                       animated:YES
                                          shake:YES
                                         forced:YES];
        shouldChangePassword = NO;
        
        NSDictionary *params = @{ VTrackingKeyErrorMessage : validationError.localizedDescription ?: @"" };
        [[VTrackingManager sharedInstance] trackEvent:VTrackingEventLoginWithEmailValidationDidFail parameters:params];
        nextResponder = self.passwordTextField;
    }
    
    [self.passwordValidator setConfirmationObject:self.confirmPasswordTextField withKeyPath:NSStringFromSelector(@selector(text))];
    if ( ![self.passwordValidator validateString:self.passwordTextField.text andError:&validationError])
    {
        [self.confirmPasswordTextField showInvalidText:validationError.localizedDescription
                                              animated:YES
                                                 shake:YES
                                                forced:YES];
        shouldChangePassword = NO;
        
        NSDictionary *params = @{ VTrackingKeyErrorMessage : validationError.localizedDescription ?: @"" };
        [[VTrackingManager sharedInstance] trackEvent:VTrackingEventLoginWithEmailValidationDidFail parameters:params];
        
        if (nextResponder == nil)
        {
            nextResponder = self.confirmPasswordTextField;
        }
    }
    
    [nextResponder becomeFirstResponder];
    return shouldChangePassword;
}

@end