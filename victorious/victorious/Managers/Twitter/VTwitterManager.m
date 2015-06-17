//
//  VTwitterManager.m
//  victorious
//
//  Created by Will Long on 8/20/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VTwitterManager.h"

#import "TWAPIManager.h"

#import "VTwitterAccountsHelper.h"

@import Accounts;

NSString * const VTwitterManagerErrorDomain = @"twitterManagerError";
static CGFloat const kTwitterManagerErrorCode = 1;

@interface VTwitterManager()

@property (nonatomic, strong) NSString *oauthToken;
@property (nonatomic, strong) NSString *secret;
@property (nonatomic, strong) NSString *twitterId;
@property (nonatomic, strong) VTwitterAccountsHelper *accountsHelper;

@end

@implementation VTwitterManager

- (instancetype)init
{
    self = [super init];
    if ( self != nil )
    {
        _accountsHelper = [[VTwitterAccountsHelper alloc] init];
    }
    return self;
}

+ (VTwitterManager *)sharedManager
{
    static VTwitterManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(void)
                  {
                      sharedManager = [[VTwitterManager alloc] init];
                  });
    return sharedManager;
}

- (BOOL)authorizedToShare
{
    return self.secret && self.oauthToken && self.twitterId;
}

- (void)refreshTwitterTokenWithIdentifier:(NSString *)identifier
                       fromViewController:(UIViewController *)viewController
                           completionBlock:(VTWitterCompletionBlock)completionBlock
{
    ACAccountStore *account = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [account requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error)
     {
         if (!granted)
         {
             dispatch_async(dispatch_get_main_queue(), ^(void)
                            {
                                completionBlock(NO, error);
                            });
         }
         else
         {
             NSArray *twitterAccounts = [account accountsWithAccountType:accountType];
             if ( twitterAccounts.count == 0 )
             {
                 dispatch_async(dispatch_get_main_queue(), ^(void)
                                {
                                    NSString *errorMessage = NSLocalizedString(@"NoTwitterMessage", @"");
                                    NSError *noTwitterError = [NSError errorWithDomain:VTwitterManagerErrorDomain code:kTwitterManagerErrorCode userInfo:@{ NSLocalizedDescriptionKey : errorMessage }];
                                    if ( completionBlock != nil )
                                    {
                                        completionBlock(NO, noTwitterError);
                                    }
                                });
             }
             else
             {
                 [_accountsHelper selectTwitterAccountWithViewControler:viewController
                                                             completion:^(ACAccount *twitterAccount)
                  {
                      if ( twitterAccount == nil )
                      {
                          self.oauthToken = nil;
                          self.secret = nil;
                          self.twitterId = nil;
                          
                          if ( completionBlock != nil )
                          {
                              completionBlock(NO, error);
                          }
                          
                          return;
                      }
                      
                      TWAPIManager *twitterApiManager = [[TWAPIManager alloc] init];
                      [twitterApiManager performReverseAuthForAccount:twitterAccount
                                                          withHandler:^(NSData *responseData, NSError *error)
                       {
                           if ( error != nil )
                           {
                               self.oauthToken = nil;
                               self.secret = nil;
                               self.twitterId = nil;
                               
                               if ( completionBlock != nil )
                               {
                                   completionBlock(NO, error);
                               }
                               
                               return;
                           }
                           
                           NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                           NSDictionary *parsedData = RKDictionaryFromURLEncodedStringWithEncoding(responseStr, NSUTF8StringEncoding);
                           
                           self.oauthToken = [parsedData objectForKey:@"oauth_token"];
                           self.secret = [parsedData objectForKey:@"oauth_token_secret"];
                           self.twitterId = [parsedData objectForKey:@"user_id"];
                           
                           if ( completionBlock != nil )
                           {
                               completionBlock(YES, error);
                           }
                       }];
                  }];
             }
         }
     }];
}

@end
