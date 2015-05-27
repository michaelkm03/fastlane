//
//  VLoginFlowControllerResponder.h
//  victorious
//
//  Created by Michael Sena on 5/21/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VLoginFlowControllerResponder <NSObject>

/**
 * The login flow should cancel and dismiss.
 */
- (void)cancelLoginAndRegistration;

/**
 *  The user wants to proceed to login.
 */
- (void)selectedLogin;

/**
 *  The user wants to proceed to registration.
 */
- (void)selectedRegister;

/**
 *  The user wants to authorize with their twitter account.
 */
- (void)selectedTwitterAuthorization;

/**
 *  The user wants to authorize with their facebook account.
 */
- (void)selectedFacebookAuthorization;

/**
 *  The user has entered an email and password and wants to login.
 */
- (void)loginWithEmail:(NSString *)email
              password:(NSString *)password
            completion:(void(^)(BOOL success, NSError *error))completion;

/**
 *  The user has entered an email and password and wants to register.
 */
- (void)registerWithEmail:(NSString *)email
                 password:(NSString *)password
               completion:(void(^)(BOOL success, NSError *error))completion;

/**
 *  The user has entered an appropriate username.
 */
- (void)setUsername:(NSString *)username;

/**
 *  The user forgot their password.
 *
 *  @param initialEmail An email that they may have begun to enter in a login flow.
 */
- (void)forgotPasswordWithInitialEmail:(NSString *)initialEmail;

/**
 *  The user has entered their reset token.
 */
- (void)setResetToken:(NSString *)resetToken;

/**
 *  The user has entered a new password.
 */
- (void)updateWithNewPassword:(NSString *)newPassword;

@end
