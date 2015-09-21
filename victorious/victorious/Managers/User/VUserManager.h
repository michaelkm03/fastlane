//
//  VUserManager.h
//  victorious
//
//  Created by Gary Philipp on 2/6/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

@class VUser;

typedef void (^VUserManagerLoginCompletionBlock)(VUser *user, BOOL isNewUser);
typedef void (^VUserManagerLoginErrorBlock)(NSError *error, BOOL thirdPartyAPIFailure);

@interface VUserManager : NSObject

/**
 if YES, native login will be used even if the powers that be try to disable
 it. If NO, native login will follow the whims of the Facebook overlords.
 */
@property (nonatomic) BOOL forceNativeFacebookLogin;

/**
 Log in using Facebook credentials
 */
- (void)loginViaFacebookOnCompletion:(VUserManagerLoginCompletionBlock)completion
                             onError:(VUserManagerLoginErrorBlock)errorBlock;

/**
 Log in using Twitter credentials
 */
- (void)loginViaTwitterOnCompletion:(VUserManagerLoginCompletionBlock)completion
                            onError:(VUserManagerLoginErrorBlock)errorBlock;

/**
 Log in with a specific Twitter credential
 */
- (void)loginViaTwitterWithTwitterID:(NSString *)twitterID
                        onCompletion:(VUserManagerLoginCompletionBlock)completion
                             onError:(VUserManagerLoginErrorBlock)errorBlock;

/**
 Create a new account with the specified e-mail and password. 
 If an account already exists on the server with the specified e-mail address
 an error will occur, unless the specified password matches the password on
 that account. In that case, the existing account will be logged in.
 */
- (void)createEmailAccount:(NSString *)email
                  password:(NSString *)password
                  userName:(NSString *)userName
              onCompletion:(VUserManagerLoginCompletionBlock)completion
                   onError:(VUserManagerLoginErrorBlock)errorBlock;

/**
 Log in using an e-mail address and password
 */
- (void)loginViaEmail:(NSString *)email
             password:(NSString *)password
         onCompletion:(VUserManagerLoginCompletionBlock)completion
              onError:(VUserManagerLoginErrorBlock)errorBlock;

/**
 Re-login to whatever service the user last logged in with
 */
- (void)loginViaSavedCredentialsOnCompletion:(VUserManagerLoginCompletionBlock)completion onError:(VUserManagerLoginErrorBlock)errorBlock;

/**
 Performs any cleanup necessary after user has logged out through the server (i.e. VObjectManager).
 */
- (void)userDidLogout;

/**
 Saves the user's password in the keychain for automatic login in the future
 */
- (BOOL)savePassword:(NSString *)password forEmail:(NSString *)email;

@end
