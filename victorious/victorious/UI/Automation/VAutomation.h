//
//  VAutomation.h
//  victorious
//
//  Created by Patrick Lynch on 11/19/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

/**
 * View Identifiers.
 * UI Automation testing depends on these, so be careful modifying them.
 * Some parts of the app that are dynamically driven as part of the template system
 * wil not be listed here, but instead will have an non-localized 'identifier' property
 * configured at the JSON level that is designed for accessibility and automation purposes.
 *
 * There is an equivalent file for Swift code that defines identifiers as enums.
 * @see "AutomationId.swift"
 */

static NSString * const VAutomationIdentifierAddPost                    = @"Add Post";
static NSString * const VAutomationIdentifierMainMenu                   = @"Menu Open";
static NSString * const VAutomationIdentifierGenericBack                = @"Back";

static NSString * const VAutomationIdentifierKeyboardHashtagButton      = @"Keyboard Hashtag Button";

static NSString * const VAutomationIdentifierSettingsLogIn              = @"Settings Log In";
static NSString * const VAutomationIdentifierSettingsLogOut             = @"Settings Log Out";

static NSString * const VAutomationIdentifierLoginSelectEmail           = @"Login Select Email";
static NSString * const VAutomationIdentifierLoginSelectPassword        = @"Login Select Password";
static NSString * const VAutomationIdentifierLoginUsernameField         = @"Login Username Field";
static NSString * const VAutomationIdentifierLoginPasswordField         = @"Login Password Field";
static NSString * const VAutomationIdentifierLoginSubmit                = @"Login Submit";
static NSString * const VAutomationIdentifierLoginCancel                = @"Login Cancel";
static NSString * const VAutomationIdentifierLoginForgotPassword        = @"Login Forgot Password";
static NSString * const VAutomationIdentifierLoginSignUp                = @"Login Sign Up";
static NSString * const VAutomationIdentifierLoginFacebook              = @"Login Facebook";
static NSString * const VAutomationIdentifierLoginTwitter               = @"Login Twitter";

static NSString * const VAutomationIdentifierSignupUsernameField        = @"Signup Username Field";
static NSString * const VAutomationIdentifierSignupPasswordField        = @"Signup Password Field";
static NSString * const VAutomationIdentifierSignupPasswordConfirmField = @"Signup Password Confirm Field";
static NSString * const VAutomationIdentifierSignupSubmit               = @"Signup Submit";
static NSString * const VAutomationIdentifierSignupCancel               = @"Signup Cancel";

static NSString * const VAutomationIdentifierProfileUsernameField       = @"Profile Username Field";
static NSString * const VAutomationIdentifierProfileLocationField       = @"Profile Location Field";
static NSString * const VAutomationIdentifierProfileDone                = @"Profile Done";
static NSString * const VAutomationIdentifierProfileAgeAgreeSwitch      = @"Profile Age Switch";
static NSString * const VAutomationIdentifierProfilSelectImage          = @"Profile Select Image";
static NSString * const VAutomationIdentifierProfileLogInButton         = @"Log In Button";

static NSString * const VAutomationIdentifierWelcomeDismiss             = @"Welcome Dismiss";

static NSString * const VAutomationIdentifierGrantLibraryAccess         = @"Library Grant Access";
static NSString * const VAutomationIdentifierPublishCatpionPlaceholder  = @"Publish Caption Placeholder";
static NSString * const VAutomationIdentifierPublishCatpionText         = @"Publish Caption Text";

static NSString * const VAutomationIdentifierContentViewBallotButtonA   = @"Ballot Button A";
static NSString * const VAutomationIdentifierContentViewBallotButtonB   = @"Ballot Button B";
static NSString * const VAutomationIdentifierContentViewCommentBar      = @"Content View Comment Bar";
static NSString * const VAutomationIdentifierContentViewCommentCell     = @"Content View Comment Cell Text View";

static NSString * const VAutomationIdentifierTextPostMainField          = @"Text Post Main Field";

static NSString * const VAutomationIdentifierCommentBarTextView         = @"Comment Bar Text View";
static NSString * const VAutomationIdentifierCommentBarImageButton      = @"Comment Bar Image Button";
static NSString * const VAutomationIdentifierCommentBarVideoButton      = @"Comment Bar Video Button";
static NSString * const VAutomationIdentifierCommentBarGIFButton        = @"Comment Bar GIF Button";
static NSString * const VAutomationIdentifierCommentBarSendButton       = @"Comment Bar Send Button";
static NSString * const VAutomationIdentifierCommentBarClearButton      = @"Comment Bar Clear Attachment Button";

static NSString * const VAutomationIdentifierMediaGalleryCollection     = @"Media Gallery Collection";
