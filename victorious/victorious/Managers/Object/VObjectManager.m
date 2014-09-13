//
//  VObjectManager.m
//  victorious
//
//  Created by Will Long on 1/16/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VEnvironment.h"
#import "VErrorMessage.h"
#import "VObjectManager.h"
#import "VObjectManager+Environment.h"
#import "VObjectManager+Private.h"
#import "VPaginationManager.h"
#import "VRootViewController.h"

#import "VConstants.h"

#import "NSString+SHA1Digest.h"
#import "NSString+VParseHelp.h"

#import "VUser+RestKit.h"
#import "VSequence+RestKit.h"
#import "VComment+RestKit.h"
#import "VConversation+RestKit.h"
#import "VImageSearchResult.h"
#import "VPollResult+RestKit.h"
#import "VMessage+RestKit.h"
#import "VUnreadConversation+RestKit.h"
#import "VVoteType+RestKit.h"
#import "VNotification+RestKit.h"

#define EnableRestKitLogs 0 // Set to "1" to see RestKit logging, but please remember to set it back to "0" before committing your changes.

@interface VObjectManager ()

@property (nonatomic, strong, readwrite) VPaginationManager *paginationManager;

@end

@implementation VObjectManager

+ (void)setupObjectManager
{
#if DEBUG && EnableRestKitLogs
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
#warning RestKit logging is enabled. Please remember to disable it when you're done debugging.
#else
    RKLogConfigureByName("*", RKLogLevelOff);
#endif
    
    VObjectManager *manager = [self managerWithBaseURL:[[self currentEnvironment] baseURL]];
    manager.paginationManager = [[VPaginationManager alloc] initWithObjectManager:manager];
    
    //Add the App ID to the User-Agent field
    //(this is the only non-dynamic header, so set it now)
    NSString *userAgent = ([manager HTTPClient].defaultHeaders)[kVUserAgentHeader];
    
    NSString *buildNumber = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSNumber* appID = [VObjectManager currentEnvironment].appID;
    userAgent = [NSString stringWithFormat:@"%@ aid:%@ uuid:%@ build:%@", userAgent, appID.stringValue, [[UIDevice currentDevice].identifierForVendor UUIDString], buildNumber];
    [[manager HTTPClient] setDefaultHeader:kVUserAgentHeader value:userAgent];
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"victoriOS" withExtension:@"momd"];
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    
    manager.managedObjectStore = managedObjectStore;
    
    // Initialize the Core Data stack
    NSError *error = nil;
    [managedObjectStore createPersistentStoreCoordinator];
    [managedObjectStore addInMemoryPersistentStore:&error];
    [managedObjectStore createManagedObjectContexts];
    
    // Configure a managed object cache to ensure we do not create duplicate objects
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    
    [manager victoriousSetup];
    
    //This will allow us to call this manager with [RKObjectManager sharedManager]
    [self setSharedManager:manager];
}

- (void)victoriousSetup
{
    //Should one of our requests to get data fail, RestKit will use this mapping and send us an NSError object with the error message of the response as the string.
    RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [errorMapping addPropertyMapping:
     [RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"errorMessage"]];
    RKResponseDescriptor *errorDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorMapping
                                                                                         method:RKRequestMethodAny
                                                                                    pathPattern:nil
                                                                                        keyPath:@"error"
                                                                                    statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError)];
    
    RKResponseDescriptor *verrorDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[VErrorMessage objectMapping]
                                                                                          method:RKRequestMethodAny
                                                                                     pathPattern:nil
                                                                                         keyPath:nil
                                                                                     statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    
    [self addResponseDescriptorsFromArray:[VUser descriptors]];
    [self addResponseDescriptorsFromArray:[VSequence descriptors]];
    [self addResponseDescriptorsFromArray:[VConversation descriptors]];
    [self addResponseDescriptorsFromArray:[VMessage descriptors]];
    [self addResponseDescriptorsFromArray:[VComment descriptors]];
    [self addResponseDescriptorsFromArray:[VNotification descriptors]];
    
    [self addResponseDescriptorsFromArray: @[errorDescriptor,
                                             verrorDescriptor,
                                             
                                             [VPollResult descriptor],
                                             [VPollResult createPollResultDescriptor],
                                             [VPollResult byUserDescriptor],
                                             [VUnreadConversation descriptor],
                                             [VVoteType descriptor],
                                             [VImageSearchResult descriptor],
                                             ]];
    
    self.objectCache = [[NSCache alloc] init];
}

- (VUser *)mainUser
{
    NSAssert([NSThread isMainThread], @"mainUser should be accessed only from the main thread");
    return _mainUser;
}

#pragma mark - operation

- (RKManagedObjectRequestOperation *)requestMethod:(RKRequestMethod)method
                                            object:(id)object
                                              path:(NSString *)path
                                        parameters:(NSDictionary *)parameters
                                      successBlock:(VSuccessBlock)successBlock
                                         failBlock:(VFailBlock)failBlock
{
    NSURL* url = [NSURL URLWithString:path];
    if ([path isEmpty] || !url)
    {
        //Something has gone horribly wrong, so fail.
        if (failBlock)
        {
            failBlock(nil, nil);
        }
        return nil;
    }
    
    RKManagedObjectRequestOperation *requestOperation =
    [self  appropriateObjectRequestOperationWithObject:object method:method path:path parameters:parameters];

     void (^rkSuccessBlock) (RKObjectRequestOperation*, RKMappingResult*) = ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult)
    {
        NSMutableArray* mappedObjects = [mappingResult.array mutableCopy];
        VErrorMessage* error;
        for (id object in mappedObjects)
        {
            if ([object isKindOfClass:[VErrorMessage class]])
            {
                error = object;
                [mappedObjects removeObject:object];
                break;
            }
        }
        
        if (error.errorCode == kVUnauthoizedError && self.mainUser)
        {
            self.mainUser = nil;
            [self requestMethod:method object:object path:path parameters:parameters successBlock:successBlock failBlock:failBlock];
        }
        else if (!error.errorCode && successBlock)
        {
            //Grab the response data, and make sure to process it... we must guarentee that the payload is a dictionary
            NSMutableDictionary *JSON = [[NSJSONSerialization JSONObjectWithData:operation.HTTPRequestOperation.responseData options:0 error:nil] mutableCopy];
            id payload = JSON[kVPayloadKey];
            if (payload && ![payload isKindOfClass:[NSDictionary class]])
            {
                JSON[kVPayloadKey] = @{@"objects":payload};
            }
            successBlock(operation, JSON, mappedObjects);
        }
        else if (error.errorCode)
        {
            NSError* nsError = [NSError errorWithDomain:kVictoriousErrorDomain code:error.errorCode
                                             userInfo:@{NSLocalizedDescriptionKey:[error.errorMessages componentsJoinedByString:@","]}];
            [self defaultErrorHandlingForCode:nsError.code];
            
            if (failBlock)
            {
                failBlock(operation, nsError);
            }
        }
    };
    
    VFailBlock rkFailBlock = ^(NSOperation* operation, NSError* error)
    {
        RKErrorMessage* rkErrorMessage = [error.userInfo[RKObjectMapperErrorObjectsKey] firstObject];
        if (rkErrorMessage.errorMessage.integerValue == kVUnauthoizedError && self.mainUser)
        {
            self.mainUser = nil;
            [self requestMethod:method object:object path:path parameters:parameters successBlock:successBlock failBlock:failBlock];
        }
        else
        {
            [self defaultErrorHandlingForCode:rkErrorMessage.errorMessage.integerValue];
            
            if (failBlock)
            {
                failBlock(operation, error);
            }
        }
    };
    
    [requestOperation setCompletionBlockWithSuccess:rkSuccessBlock failure:rkFailBlock];
    [requestOperation start];
    return requestOperation;
}

- (void)defaultErrorHandlingForCode:(NSInteger)errorCode
{
    if (errorCode == kVUpgradeRequiredError)
    {
        [[VRootViewController rootViewController] presentForceUpgradeScreen];
    }
    else if(errorCode == kVUserBannedError)
    {
        self.mainUser = nil;
        UIAlertView*    alert   =   [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UserBannedTitle", @"")
                                                               message:NSLocalizedString(@"UserBannedMessage", @"")
                                                              delegate:nil
                                                     cancelButtonTitle:NSLocalizedString(@"OKButton", @"")
                                                     otherButtonTitles:nil];
        [alert show];
    }
}

- (RKManagedObjectRequestOperation *)GET:(NSString *)path
                                  object:(id)object
                              parameters:(NSDictionary *)parameters
                            successBlock:(VSuccessBlock)successBlock
                               failBlock:(VFailBlock)failBlock
{
    return [self requestMethod:RKRequestMethodGET
                        object:object
                          path:path
                    parameters:parameters
                  successBlock:successBlock
                     failBlock:failBlock];
}

- (RKManagedObjectRequestOperation *)POST:(NSString *)path
                                   object:(id)object
                               parameters:(NSDictionary *)parameters
                             successBlock:(VSuccessBlock)successBlock
                                failBlock:(VFailBlock)failBlock
{
    return [self requestMethod:RKRequestMethodPOST
                        object:object
                          path:path
                    parameters:parameters
                  successBlock:successBlock
                     failBlock:failBlock];
}

- (RKManagedObjectRequestOperation *)DELETE:(NSString *)path
                                     object:(id)object
                                 parameters:(NSDictionary *)parameters
                               successBlock:(VSuccessBlock)successBlock
                                  failBlock:(VFailBlock)failBlock
{
    return [self requestMethod:RKRequestMethodDELETE
                        object:object
                          path:path
                    parameters:parameters
                  successBlock:successBlock
                     failBlock:failBlock];
}

- (AFHTTPRequestOperation *)uploadURLs:(NSDictionary *)allUrls
                                toPath:(NSString *)path
                            parameters:(NSDictionary *)parameters
                          successBlock:(VSuccessBlock)successBlock
                             failBlock:(VFailBlock)failBlock
{
    if ([path isEmpty])
    {
        //Something has gone horribly wrong, so fail.
        if (failBlock)
        {
            failBlock(nil, nil);
        }
        return nil;
    }
    
    [self updateHTTPHeadersForPath:path method:RKRequestMethodPOST];
    
    NSMutableURLRequest *request =
    [self.HTTPClient multipartFormRequestWithMethod:@"POST"
                                               path:path
                                         parameters:parameters
                          constructingBodyWithBlock: ^(id <AFMultipartFormData>formData)
     {
         [allUrls enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
          {
              NSString* extension = [[obj pathExtension] lowercaseStringWithLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
              if (extension)
              {
                  NSString* mimeType = [extension isEqualToString:VConstantMediaExtensionMOV] || [extension isEqualToString:VConstantMediaExtensionMP4]
                    ? @"video/quicktime" : @"image/png";
                  
                  [formData appendPartWithFileURL:obj
                                             name:key
                                         fileName:[key stringByAppendingPathExtension:extension]
                                         mimeType:mimeType
                                            error:nil];
              }
          }];
     }];
    
    //Wrap the vsuccess block in a afsuccess block
    void (^afSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject)  = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSError             *error                 = [self errorForResponse:responseObject];
        NSMutableDictionary *mutableResponseObject = [responseObject mutableCopy];
        
        id payload = mutableResponseObject[kVPayloadKey];
        if (payload && ![payload isKindOfClass:[NSDictionary class]])
        {
            mutableResponseObject[kVPayloadKey] = @{@"objects":payload};
        }

        if (!error && successBlock)
        {
            successBlock(operation, mutableResponseObject, nil);
        }
        else
        {
            [self defaultErrorHandlingForCode:error.code];
            if (failBlock)
            {
                failBlock(operation, error);
            }
        }
    };
    
    AFHTTPRequestOperation *operation = [self.HTTPClient HTTPRequestOperationWithRequest:request
                                                                                 success:afSuccessBlock
                                                                                 failure:failBlock];
    [operation start];
    return operation;
}

- (NSError *)errorForResponse:(NSDictionary *)responseObject
{
    if ([responseObject[@"error"] integerValue] == 0)
    {
        return nil;
    }
    
    NSString* errorMessage = responseObject[@"message"];
    if ([errorMessage isKindOfClass:[NSArray class]])
    {
        errorMessage = [(NSArray *)errorMessage componentsJoinedByString:@", "];
    }
    
    return [NSError errorWithDomain:kVictoriousErrorDomain code:[responseObject[@"error"] integerValue]
                           userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
}

- (NSManagedObject *)objectForID:(NSNumber *)objectID
                           idKey:(NSString *)idKey
                      entityName:(NSString *)entityName
            managedObjectContext:(NSManagedObjectContext *)context
{
    NSManagedObject* object = [self.objectCache objectForKey:[entityName stringByAppendingString:objectID.stringValue]];
    if (object)
    {
        return object;
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
    NSPredicate* idFilter = [NSPredicate predicateWithFormat:@"%K == %@", idKey, objectID];
    [request setPredicate:idFilter];
    NSError *error = nil;
    object = [[context executeFetchRequest:request error:&error] firstObject];
    if (error != nil)
    {
        VLog(@"Error occured in commentForId: %@", error);
    }
    
    if (object)
    {
        [self.objectCache setObject:object forKey:[entityName stringByAppendingString:objectID.stringValue]];
    }
    
    return object;
}

#pragma mark - Subclass
- (id)appropriateObjectRequestOperationWithObject:(id)object
                                           method:(RKRequestMethod)method
                                             path:(NSString *)path
                                       parameters:(NSDictionary *)parameters
{
    [self updateHTTPHeadersForPath:path method:method];
    
    return [super appropriateObjectRequestOperationWithObject:object
                                                       method:method
                                                         path:path
                                                   parameters:parameters];
}

- (void)updateHTTPHeadersForPath:(NSString *)path method:(RKRequestMethod)method
{
    
    AFHTTPClient* client = [self HTTPClient];
    
    NSString *currentDate = [self rFC2822DateTimeString];
    NSString* userAgent = (client.defaultHeaders)[kVUserAgentHeader];
    
    __block NSString* token;
    __block NSNumber* userID;
    // this may cause a deadlock if the main thread synchronously calls a background thread which then tries to initiate a networking call.
    // Can't think of a good reason why you'd ever do that, but still, beware.
    [self.managedObjectStore.mainQueueManagedObjectContext performBlockAndWait:^(void)
    {
        userID = self.mainUser.remoteId;
        token = self.mainUser.token ?: @"";
    }];
    
    // Build string to be hashed.
    NSString *sha1String = [[NSString stringWithFormat:@"%@%@%@%@%@",
                             currentDate,
                             path,
                             userAgent,
                             token,
                             RKStringFromRequestMethod(method)] SHA1HexDigest];
    
    sha1String = [NSString stringWithFormat:@"Basic %@:%@", userID, sha1String];
    
    [client setDefaultHeader:@"Authorization" value:sha1String];
    [client setDefaultHeader:@"Date" value:currentDate];
}

- (NSString *)rFC2822DateTimeString
{
    static NSDateFormatter *sRFC2822DateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sRFC2822DateFormatter = [[NSDateFormatter alloc] init];
        sRFC2822DateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        sRFC2822DateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z"; //RFC2822-Format
        
        NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        [sRFC2822DateFormatter setTimeZone:gmt];
    });
    
    return [sRFC2822DateFormatter stringFromDate:[NSDate date]];
}

@end