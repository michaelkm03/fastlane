//
//  VObjectManager+Users.m
//  victorious
//
//  Created by Will Long on 1/9/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "NSArray+VMap.h"
#import "NSString+VCrypto.h"
#import "NSCharacterSet+VURLParts.h"

#import "VObjectManager+Users.h"
#import "VObjectManager+Private.h"

#import "VHashtag+RestKit.h"
#import "VConversation+RestKit.h"
#import "VUser.h"

#import "TWAPIManager.h"

#import "VConstants.h"
#import "VJSONHelper.h"

@import Accounts;

@interface VObjectManager (UserProperties)

@property (nonatomic, strong) VSuccessBlock fullSuccess;
@property (nonatomic, strong) VFailBlock fullFail;

@end

NSString * const VMainUserDidChangeFollowingUserKeyUser = @"VMainUserDidChangeFollowingUserKeyUser";

NSString * const VObjectManagerSearchContextMessage = @"message";
NSString * const VObjectManagerSearchContextUserTag = @"tag_user";
NSString * const VObjectManagerSearchContextDiscover = @"discover";

static NSString * const kVAPIParamSearch = @"search";
static NSString * const kVAPIParamContext = @"context";

@implementation VObjectManager (Users)

- (RKManagedObjectRequestOperation *)fetchUser:(NSNumber *)userId
                              withSuccessBlock:(VSuccessBlock)success
                                     failBlock:(VFailBlock)fail
{
    return [self fetchUser:userId forceReload:NO withSuccessBlock:success failBlock:fail];
}

- (RKManagedObjectRequestOperation *)fetchUser:(NSNumber *)userId
                                   forceReload:(BOOL)forceReload
                              withSuccessBlock:(VSuccessBlock)success
                                     failBlock:(VFailBlock)fail
{
    __block VUser *user = nil;
    NSManagedObjectContext *context = [[self managedObjectStore] mainQueueManagedObjectContext];
    [context performBlockAndWait:^(void)
     {
         user = (VUser *)[self objectForID:userId
                                     idKey:kRemoteIdKey
                                entityName:[VUser entityName]
                      managedObjectContext:context];
     }];
    if ( user != nil && !forceReload )
    {
        if ( success != nil )
        {
            dispatch_async(dispatch_get_main_queue(), ^(void)
                           {
                               success( nil, nil, @[user] );
                           });
        }
        return nil;
    }
    
    NSString *path = userId ? [@"/api/userinfo/fetch/" stringByAppendingString: userId.stringValue] : @"/api/userinfo/fetch";
    
    return [self GET:path
              object:nil
          parameters:nil
        successBlock:success
           failBlock:fail];
}

- (RKManagedObjectRequestOperation *)fetchUsers:(NSArray *)userIds
                               withSuccessBlock:(VSuccessBlock)success
                                      failBlock:(VFailBlock)fail
{
    NSMutableArray *loadedUsers = [[NSMutableArray alloc] init];
    NSMutableArray *unloadedUserIDs = [[NSMutableArray alloc] init];
    
    //this removes duplicates
    for (NSNumber *userID in [[NSSet setWithArray:userIds] allObjects])
    {
        __block VUser *user = nil;
        NSManagedObjectContext *context = [[self managedObjectStore] mainQueueManagedObjectContext];
        [context performBlockAndWait:^(void)
         {
             user = (VUser *)[self objectForID:userID
                                         idKey:kRemoteIdKey
                                    entityName:[VUser entityName]
                          managedObjectContext:context];
         }];
        if (user)
        {
            [loadedUsers addObject:user];
        }
        else
        {
            [unloadedUserIDs addObject:userID.stringValue];
        }
    }
    
    if (![unloadedUserIDs count])
    {
        dispatch_async(dispatch_get_main_queue(), ^(void)
                       {
                           success(nil, nil, loadedUsers);
                       });
        return nil;
    }
    
    VSuccessBlock fullSuccess = ^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
    {
        for (VUser *user in resultObjects)
        {
            [loadedUsers addObject:user];
        }
        
        if (success)
        {
            success(operation, fullResponse, loadedUsers);
        }
    };
    
    NSString *path = [@"/api/userinfo/fetch/" stringByAppendingString:unloadedUserIDs[0]];
    for (NSUInteger i = 1; i < [unloadedUserIDs count]; i++)
    {
        path = [path stringByAppendingString:@","];
        path = [path stringByAppendingString:unloadedUserIDs[i]];
    }
    
    return [self GET:path
              object:nil
          parameters:nil
        successBlock:fullSuccess
           failBlock:fail];
}

- (RKManagedObjectRequestOperation *)attachAccountToFacebookWithToken:(NSString *)accessToken
                                                   forceAccountUpdate:(BOOL)forceAccountUpdate
                                                     withSuccessBlock:(VSuccessBlock)success
                                                            failBlock:(VFailBlock)fail
{
    
    NSDictionary *parameters = @{@"facebook_access_token":  accessToken ?: @"",
                                 @"force_update":           [NSNumber numberWithBool:forceAccountUpdate]};
    
    return [self POST:@"/api/socialconnect/facebook"
               object:nil
           parameters:parameters
         successBlock:success
            failBlock:fail];
}

- (void)attachAccountToTwitterWithForceAccountUpdate:(BOOL)forceAccountUpdate
                                        successBlock:(VSuccessBlock)success
                                           failBlock:(VFailBlock)fail
{
    //Just fail without the network call if we aren't logged in
    if (![VObjectManager sharedManager].mainUser)
    {
        if (fail)
        {
            fail(nil, nil);
        }
        return;
    }
    
    ACAccountStore *account = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    NSArray *accounts = [account accountsWithAccountType:accountType];
    ACAccount *twitterAccount = [accounts lastObject];
    
    if (!twitterAccount)
    {
        if (fail)
        {
            fail(nil, nil);
        }
        return;
    }
    
    TWAPIManager *twitterApiManager = [[TWAPIManager alloc] init];
    [twitterApiManager performReverseAuthForAccount:twitterAccount
                                        withHandler:^(NSData *responseData, NSError *error)
     {
         if (fail)
         {
             if (fail)
             {
                 fail(nil, error);
             }
             return;
         }
         
         NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
         NSDictionary *parsedData = RKDictionaryFromURLEncodedStringWithEncoding(responseStr, NSUTF8StringEncoding);
         
         NSString *oauthToken = [parsedData objectForKey:@"oauth_token"];
         NSString *tokenSecret = [parsedData objectForKey:@"oauth_token_secret"];
         NSString *twitterId = [parsedData objectForKey:@"user_id"];
         
         NSDictionary *parameters = @{@"access_token":   oauthToken ?: @"",
                                      @"access_secret":  tokenSecret ?: @"",
                                      @"twitter_id":     twitterId ?: @"",
                                      @"force_update":   [NSNumber numberWithBool:forceAccountUpdate]};
         
         [self POST:@"/api/socialconnect/twitter"
             object:nil
         parameters:parameters
       successBlock:success
          failBlock:fail];
     }];
}

#pragma mark - Following

- (RKManagedObjectRequestOperation *)followUser:(VUser *)user
                                   successBlock:(VSuccessBlock)success
                                      failBlock:(VFailBlock)fail
{
    NSDictionary *parameters = @{ @"target_user_id": user.remoteId };
    
    VSuccessBlock fullSuccess = ^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
    {
        [self.mainUser addFollowingObject:user];
        self.mainUser.numberOfFollowing = @(self.mainUser.following.count);
        user.numberOfFollowers = @(user.numberOfFollowers.integerValue + 1);
        
        [[VTrackingManager sharedInstance] trackEvent:VTrackingEventUserDidFollowUser];
        if (success)
        {
            success(operation, fullResponse, resultObjects);
        }
    };
    
    VFailBlock fullFail = ^(NSOperation *operation, NSError *error)
    {
        if (error.code == kVFollowsRelationshipAlreadyExistsError)
        {
            // Add user relationship to local persistent store
            VUser *mainUser = [[VObjectManager sharedManager] mainUser];
            [mainUser addFollowingObject:user];
        }
        fail(operation, error);
    };
    
    return [self POST:@"/api/follow/add"
               object:nil
           parameters:parameters
         successBlock:fullSuccess
            failBlock:fullFail];
}

- (RKManagedObjectRequestOperation *)unfollowUser:(VUser *)user
                                     successBlock:(VSuccessBlock)success
                                        failBlock:(VFailBlock)fail
{
    NSDictionary *parameters = @{ @"target_user_id": user.remoteId };
    
    VSuccessBlock fullSuccess = ^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
    {
        VUser *mainUser = [[VObjectManager sharedManager] mainUser];
        [mainUser removeFollowingObject:user];
        
        self.mainUser.numberOfFollowing = @(self.mainUser.following.count);
        user.numberOfFollowers = @(user.numberOfFollowers.integerValue - 1);
        
        [[VTrackingManager sharedInstance] trackEvent:VTrackingEventUserDidUnfollowUser];
        
        if (success)
        {
            success(operation, fullResponse, resultObjects);
        }
    };
    
    VFailBlock fullFail = ^(NSOperation *operation, NSError *error)
    {
        NSInteger errorCode = error.code;
        if (errorCode == kVFollowsRelationshipDoesNotExistError)
        {
            VUser *mainUser = [[VObjectManager sharedManager] mainUser];
            [mainUser removeFollowingObject:user];
        }
        fail(operation, error);
    };
    
    return [self POST:@"/api/follow/remove"
               object:nil
           parameters:parameters
         successBlock:fullSuccess
            failBlock:fullFail];
}

- (RKManagedObjectRequestOperation *)countOfFollowsForUser:(VUser *)user
                                              successBlock:(VSuccessBlock)success
                                                 failBlock:(VFailBlock)fail
{
    VSuccessBlock fullSuccess = ^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
    {
        VJSONHelper *helper = [[VJSONHelper alloc] init];
        
        user.numberOfFollowers = [helper numberFromJSONValue:fullResponse[kVPayloadKey][@"followers"]];
        user.numberOfFollowing = [helper numberFromJSONValue:fullResponse[kVPayloadKey][@"subscribed_to"]];
        
        if ( success != nil )
        {
            success( operation, fullResponse, resultObjects );
        }
    };
    
    return [self GET:[NSString stringWithFormat:@"/api/follow/counts/%d", [user.remoteId intValue]]
              object:nil
          parameters:nil
        successBlock:fullSuccess
           failBlock:fail];
}

- (RKManagedObjectRequestOperation *)isUser:(VUser *)follower
                                  following:(VUser *)user
                               successBlock:(VSuccessBlock)success
                                  failBlock:(VFailBlock)fail
{
    VSuccessBlock fullSuccess = ^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
    {
        NSArray    *results = @[fullResponse[kVPayloadKey][@"relationship_exists"]];
        
        if (success)
        {
            success(operation, fullResponse, results);
        }
    };
    
    return [self GET:[NSString stringWithFormat:@"/api/follow/is_follower/%d/%d", [follower.remoteId intValue], [user.remoteId intValue]]
              object:nil
          parameters:nil
        successBlock:fullSuccess
           failBlock:fail];
}

#pragma mark - Friends

- (RKManagedObjectRequestOperation *)listOfRecommendedFriendsWithSuccessBlock:(VSuccessBlock)success
                                                                    failBlock:(VFailBlock)fail
{
    VSuccessBlock fullSuccess = ^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
    {
        if (success)
        {
            success(operation, fullResponse, resultObjects);
        }
    };
    
    return [self GET:@"/api/friend/suggest"
              object:nil
          parameters:nil
        successBlock:fullSuccess
           failBlock:fail];
}

- (RKManagedObjectRequestOperation *)findFriendsByEmails:(NSArray *)emails
                                        withSuccessBlock:(VSuccessBlock)success
                                               failBlock:(VFailBlock)fail
{
    NSArray *hashedEmails = [emails v_map:^id (NSString *email)
    {
        return [email v_sha256];
    }];
    NSString *emailString = [hashedEmails componentsJoinedByString:@","];
    
    VSuccessBlock fullSuccess = ^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
    {
        if (success)
        {
            success(operation, fullResponse, resultObjects);
        }
    };
    
    return [self POST:@"/api/friend/find_by_email"
               object:nil
           parameters:@{ @"emails": emailString }
         successBlock:fullSuccess
            failBlock:fail];
}

- (RKManagedObjectRequestOperation *)findUsersBySearchString:(NSString *)search_string
                                                       limit:(NSInteger)pageLimit
                                                     context:(NSString *)context
                                            withSuccessBlock:(VSuccessBlock)success
                                                   failBlock:(VFailBlock)fail
{
    VSuccessBlock fullSuccess = ^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
    {
        if (success)
        {
            success(operation, fullResponse, resultObjects);
        }
    };
    NSString *escapedSearchString = [search_string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet v_pathPartCharacterSet]];
    NSString *userSearchURL = [NSString stringWithFormat:@"/api/userinfo/search/%@/%ld", escapedSearchString, (long)pageLimit];
    if (context != nil)
    {
        userSearchURL = [NSString stringWithFormat:@"%@/%@", userSearchURL, context];
    }
    return [self GET:userSearchURL
              object:nil
          parameters:nil
        successBlock:fullSuccess
           failBlock:fail];
}

- (RKManagedObjectRequestOperation *)findFriendsBySocial:(VSocialSelector)selector
                                                   token:(NSString *)token
                                                  secret:(NSString *)secret
                                        withSuccessBlock:(VSuccessBlock)success
                                               failBlock:(VFailBlock)fail
{
    NSString *path;
    NSString *eventNameFailure;
    NSString *eventNameSuccess;
    
    switch (selector)
    {
        case kVFacebookSocialSelector:
            path = [@"/api/friend/find/facebook" stringByAppendingPathComponent:token];
            eventNameSuccess = VTrackingEventUserDidImportFacebookContacts;
            eventNameFailure = VTrackingEventImportFacebookContactsDidFail;
            break;
            
        case kVTwitterSocialSelector:
            path = [[@"/api/friend/find/twitter" stringByAppendingPathComponent:token] stringByAppendingPathComponent:secret];
            eventNameSuccess = VTrackingEventUserDidImportTwitterContacts;
            eventNameFailure = VTrackingEventImportTwitterContactsDidFail;
            break;
            
        case kVInstagramSocialSelector:
            path = [@"/api/friend/find/instagram" stringByAppendingPathComponent:token];
            eventNameSuccess = VTrackingEventUserDidImportInstagramContacts;
            eventNameFailure = VTrackingEventImportInstagramContactsDidFail;
            break;
            
        default:
            break;
    }
    
    VSuccessBlock fullSuccess = ^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
    {
        // Map anyone with a relationship to the main user object
        NSInteger cnt = (NSInteger)resultObjects.count;
        for (NSInteger i = 0; i < cnt ; i++)
        {
            VUser *user = resultObjects[i];
            BOOL following = [fullResponse[kVPayloadKey][@"objects"][i][@"following"] boolValue];
            if (following)
            {
                [self.mainUser addFollowingObject:user];
            }
        }
        [self.managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:nil];
        
        NSDictionary *params = @{ VTrackingKeyCount : @(resultObjects.count) };
        [[VTrackingManager sharedInstance] trackEvent:eventNameSuccess parameters:params];
        
        if ( success != nil )
        {
            success( operation, fullResponse, resultObjects );
        }
    };
    
    
    VFailBlock fullFail = ^(NSOperation *operation, NSError *error)
    {
        NSDictionary *params = @{ VTrackingKeyErrorMessage : error.localizedDescription ?: @"" };
        [[VTrackingManager sharedInstance] trackEvent:eventNameFailure parameters:params];
        if ( fail != nil )
        {
            fail( operation, error );
        }
    };
    
    return [self GET:path
              object:nil
          parameters:nil
        successBlock:fullSuccess
           failBlock:fullFail];
}

- (RKManagedObjectRequestOperation *)followUsers:(NSArray *)users
                                withSuccessBlock:(VSuccessBlock)success
                                       failBlock:(VFailBlock)fail
{
    NSDictionary *parameters = @{ @"target_user_ids": [users valueForKey:@"remoteId"] };
    
    VSuccessBlock fullSuccess = ^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
    {
        for ( VUser *user in users )
        {
            [self.mainUser addFollowingObject:user];
            user.numberOfFollowers = @(user.numberOfFollowers.integerValue + 1);
        }
        self.mainUser.numberOfFollowing = @(self.mainUser.following.count);
        if (success)
        {
            success(operation, fullResponse, resultObjects);
        }
    };
    
    return [self POST:@"/api/follow/batchadd"
               object:nil
           parameters:parameters
         successBlock:fullSuccess
            failBlock:fail];
}

#pragma mark - helpers

- (NSArray *)objectsForEntity:(NSString *)entityName
                    userIdKey:(NSString *)idKey
                       userId:(NSNumber *)userId
                    inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSPredicate *idFilter = [NSPredicate predicateWithFormat:@"%K == %@", idKey, userId];
    [request setPredicate:idFilter];
    
    __block NSArray *results;
    [context performBlockAndWait:^{
        NSError *error = nil;
        results = [context executeFetchRequest:request error:&error];
        if (error != nil)
        {
            VLog(@"Error occured in user objectsForEntity: %@", error);
        }
    }];
    
    return results;
}

@end
