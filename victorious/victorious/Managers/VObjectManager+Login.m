//
//  VObjectManager+Login.m
//  victoriOS
//
//  Created by David Keegan on 12/10/13.
//  Copyright (c) 2013 Victorious, Inc. All rights reserved.
//

#import "VObjectManager+Private.h"
#import "VObjectManager+Login.h"
#import "VObjectManager+Sequence.h"
#import "VObjectManager+DirectMessaging.h"
#import "VUser+RestKit.h"

#import "VVoteType.h"

#import "VThemeManager.h"

@implementation VObjectManager (Login)

NSString *kLoggedInChangedNotification = @"LoggedInChangedNotification";

#pragma mark - Init
- (RKManagedObjectRequestOperation *)appInitWithSuccessBlock:(VSuccessBlock)success
                                                failBlock:(VFailBlock)failed
{
    VSuccessBlock fullSuccess = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        NSDictionary* newTheme = fullResponse[@"payload"][@"appearance"];
        if (newTheme && [newTheme isKindOfClass:[NSDictionary class]])
            [[VThemeManager sharedThemeManager] setTheme:newTheme];
        
        if (success)
            success(operation, fullResponse, resultObjects);
    };
    
    return [self GET:@"/api/init"
              object:nil
          parameters:nil
        successBlock:fullSuccess
           failBlock:failed];
}

#pragma mark - Facebook

- (BOOL)isAuthorized
{
    BOOL authorized = (nil != self.mainUser);
    return authorized;
}

- (BOOL)isOwner
{
    return [self.mainUser.accessLevel isEqualToString:@"api_owner"] ;
}

- (RKManagedObjectRequestOperation *)loginToFacebookWithToken:(NSString*)accessToken
                                                 SuccessBlock:(VSuccessBlock)success
                                                    failBlock:(VFailBlock)failed
{
    
    NSDictionary *parameters = @{@"facebook_access_token": accessToken ?: @""};
    
    VSuccessBlock fullSuccess = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        [self loggedInWithUser:[resultObjects firstObject]];
        if (success)
            success(operation, fullResponse, resultObjects);
    };
    
    return [self POST:@"/api/login/facebook"
               object:nil
           parameters:parameters
         successBlock:fullSuccess
            failBlock:failed];
}

- (RKManagedObjectRequestOperation *)createFacebookWithToken:(NSString*)accessToken
                                                SuccessBlock:(VSuccessBlock)success
                                                   failBlock:(VFailBlock)failed
{
    NSDictionary *parameters = @{@"facebook_access_token": accessToken ?: [NSNull null]};
    
    VSuccessBlock fullSuccess = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        [self loggedInWithUser:[resultObjects firstObject]];
        if (success)
            success(operation, fullResponse, resultObjects);
    };
    
    return [self POST:@"/api/account/create/via_facebook"
               object:nil
           parameters:parameters
         successBlock:fullSuccess
            failBlock:failed];
}
#pragma mark - Twitter

- (RKManagedObjectRequestOperation *)loginToTwitterWithToken:(NSString*)accessToken
                                                accessSecret:(NSString*)accessSecret
                                                   twitterId:(NSString*)twitterId
                                                SuccessBlock:(VSuccessBlock)success
                                                   failBlock:(VFailBlock)failed
{
    
    NSDictionary *parameters = @{@"access_token":   accessToken ?: @"",
                                 @"access_secret":  accessSecret ?: @"",
                                 @"twitter_id":     twitterId ?: @""};
    
    VSuccessBlock fullSuccess = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        [self loggedInWithUser:[resultObjects firstObject]];
        if (success)
            success(operation, fullResponse, resultObjects);
    };
    
    return [self POST:@"/api/login/twitter"
               object:nil
           parameters:parameters
         successBlock:fullSuccess
            failBlock:failed];
}

- (RKManagedObjectRequestOperation *)createTwitterWithToken:(NSString*)accessToken
                                               accessSecret:(NSString*)accessSecret
                                                  twitterId:(NSString*)twitterId
                                               SuccessBlock:(VSuccessBlock)success
                                                  failBlock:(VFailBlock)failed
{
    NSDictionary *parameters = @{@"access_token":   accessToken ?: @"",
                                 @"access_secret":  accessSecret ?: @"",
                                 @"twitter_id":     twitterId ?: @""};
    
    VSuccessBlock fullSuccess = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        [self loggedInWithUser:[resultObjects firstObject]];
        if (success)
            success(operation, fullResponse, resultObjects);
    };
    
    return [self POST:@"/api/account/create/via_twitter"
               object:nil
           parameters:parameters
         successBlock:fullSuccess
            failBlock:failed];
}

#pragma mark - Victorious
- (RKManagedObjectRequestOperation *)loginToVictoriousWithEmail:(NSString *)email
                                                       password:(NSString *)password
                                                   successBlock:(VSuccessBlock)success
                                                      failBlock:(VFailBlock)fail
{
    NSDictionary *parameters = @{@"email": email ?: @"", @"password": password ?: @""};
    
    VSuccessBlock fullSuccess = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        [self loggedInWithUser:[resultObjects firstObject]];
        if (success)
            success(operation, fullResponse, resultObjects);
    };
    
    return [self POST:@"/api/login"
               object:nil
           parameters:parameters
         successBlock:fullSuccess
            failBlock:fail];
}

- (RKManagedObjectRequestOperation *)createVictoriousWithEmail:(NSString *)email
                                                      password:(NSString *)password
                                                      username:(NSString *)username
                                                  successBlock:(VSuccessBlock)success
                                                     failBlock:(VFailBlock)fail
{
    NSDictionary *parameters = @{@"email": email ?: @"",
                                 @"password": password ?: @"",
                                 @"name": username ?: @""};
    
    VSuccessBlock fullSuccess = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        [self loggedInWithUser:[resultObjects firstObject]];
        if (success)
            success(operation, fullResponse, resultObjects);
    };
    
    return [self POST:@"/api/account/create"
               object:nil
           parameters:parameters
         successBlock:fullSuccess
            failBlock:fail];
}

- (RKManagedObjectRequestOperation *)updateVictoriousWithEmail:(NSString *)email
                                                      password:(NSString *)password
                                                      username:(NSString *)username
                                                  successBlock:(VSuccessBlock)success
                                                     failBlock:(VFailBlock)fail
{
    NSDictionary *parameters = @{@"email": email ?: @"",
                                 @"password": password ?: @"",
                                 @"name": username ?: @""};

    VSuccessBlock fullSuccess = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        [self loggedInWithUser:[resultObjects firstObject]];
        if (success)
            success(operation, fullResponse, resultObjects);
    };
    
    return [self POST:@"/api/account/update"
               object:nil
           parameters:parameters
         successBlock:fullSuccess
            failBlock:fail];
}

#pragma mark - LoggedIn
- (void)loggedInWithUser:(VUser*)user
{
    self.mainUser = user;
    [self loadNextPageOfConversations:nil failBlock:nil];
    [self pollResultsForUser:user successBlock:nil failBlock:nil];
    [self unreadCountForConversationsWithSuccessBlock:nil failBlock:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:kLoggedInChangedNotification object:nil];
}

#pragma mark - Logout

- (RKManagedObjectRequestOperation *)logout
{
    if (![self isAuthorized]) //foolish mortal you need to log in to log out...
        return nil;
    
    VSuccessBlock success = ^(NSOperation* operation, id fullResponse, NSArray* rkObjects)
    {
        //Warning: Sometimes empty payloads will appear as Array objects. Use the following line at your own risk.
        //NSDictionary* payload = fullResponse[@"payload"];
        self.mainUser = nil;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kLoggedInChangedNotification object:nil];
    };

    return [self GET:@"/api/logout"
              object:nil
           parameters:nil
         successBlock:success
            failBlock:nil];
}

@end
