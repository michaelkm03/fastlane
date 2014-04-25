//
//  VObjectManager+Sequence.m
//  victoriOS
//
//  Created by David Keegan on 12/10/13.
//  Copyright (c) 2013 Victorious, Inc. All rights reserved.
//

#import "VObjectManager+Sequence.h"
#import "VObjectManager+Private.h"
#import "VObjectManager+Users.h"
#import "VObjectManager+Login.h"

#import "VUser.h"
#import "VUserManager.h"
#import "VSequence+RestKit.h"
#import "VAnswer.h"
#import "VComment.h"
#import "VVoteType.h"

#import "VPollResult.h"

#import "VPaginationStatus.h"

#import "NSString+VParseHelp.h"

NSString* const kPollResultsLoaded = @"kPollResultsLoaded";

@implementation VObjectManager (Sequence)

#pragma mark - Sequences

- (RKManagedObjectRequestOperation *)fetchSequence:(NSNumber*)sequenceId
                                      successBlock:(VSuccessBlock)success
                                         failBlock:(VFailBlock)fail
{
    
    VSequence* sequence = (VSequence*)[self objectForID:sequenceId idKey:kRemoteIdKey entityName:[VSequence entityName]];
    if (sequence)
    {
        if (success)
            success(nil, nil, @[sequence]);
        
        return nil;
    }
    
    return [self fetchSequenceByID:sequenceId
                      successBlock:success
                         failBlock:fail
                       loadAttempt:0];
}

- (RKManagedObjectRequestOperation *)fetchSequenceByID:(NSNumber*)sequenceID
                                          successBlock:(VSuccessBlock)success
                                             failBlock:(VFailBlock)fail
                                           loadAttempt:(NSInteger)attemptCount
{
    if (!sequenceID)
    {
        if (fail)
            fail(nil, nil);
        return nil;
    }
    NSString* path = [@"/api/sequence/fetch/" stringByAppendingString:sequenceID.stringValue];
    
    VFailBlock fullFail = ^(NSOperation* operation, NSError* error)
    {
        //keep trying until we are done transcoding
        if (error.code == 5500 && attemptCount < 15)
        {
            double delayInSeconds = 2.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self fetchSequenceByID:sequenceID
                            successBlock:success
                               failBlock:fail
                             loadAttempt:(attemptCount+1)];
            });
        }
        else if (fail)
            fail(operation, error);
    };
    
    return [self GET:path
              object:nil
          parameters:nil
        successBlock:success
           failBlock:fullFail];
}

- (RKManagedObjectRequestOperation *)loadNextPageOfCommentsForSequence:(VSequence*)sequence
                                                          successBlock:(VSuccessBlock)success
                                                             failBlock:(VFailBlock)fail
{
    if (!sequence)
        return nil;
    
    __block NSString* statusKey = [@"commentsForSequence%@" stringByAppendingString:sequence.remoteId.stringValue];
    __block VPaginationStatus* status = [self statusForKey:statusKey];
    if([status isFullyLoaded])
    {
        if (success)
            success(nil, nil, nil);
        return nil;
    }
    
    NSString* path = [@"/api/comment/all/" stringByAppendingString:sequence.remoteId.stringValue];
    path = [path stringByAppendingFormat:@"/%lu/%lu", (unsigned long)status.pagesLoaded + 1, (unsigned long)status.itemsPerPage];
    
    __block VSequence* commentOwner = sequence; //Keep the sequence around until the block gets called
    VSuccessBlock fullSuccessBlock = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        status.pagesLoaded = [fullResponse[@"page_number"] integerValue];
        status.totalPages = [fullResponse[@"total_pages"] integerValue];
        (self.paginationStatuses)[statusKey] = status;
        
        NSMutableArray* nonExistantUsers = [[NSMutableArray alloc] init];
        for (VComment* comment in resultObjects)
        {
            [commentOwner addCommentsObject:(VComment*)[commentOwner.managedObjectContext
                                                        objectWithID:[comment objectID]]];
            if (!comment.user )
                [nonExistantUsers addObject:comment.userId];
        }
        
        if ([nonExistantUsers count])
            [[VObjectManager sharedManager] fetchUsers:nonExistantUsers withSuccessBlock:success failBlock:fail];
        else if (success)
            success(operation, fullResponse, resultObjects);
    };
    
    return [self GET:path
              object:nil
          parameters:nil
        successBlock:fullSuccessBlock
           failBlock:fail];
}

- (RKManagedObjectRequestOperation *)shareSequence:(VSequence*)sequence
                                         shareType:(NSString*)type
                                      successBlock:(VSuccessBlock)success
                                         failBlock:(VFailBlock)fail
{
    NSDictionary* parameters = @{@"sequence_id": sequence.remoteId.stringValue ?: [NSNull null],
                                 @"shared_to":type ?: [NSNull null]
                                 };
    
    return [self POST:@"/api/sequence/share"
               object:nil
           parameters:parameters
         successBlock:success
            failBlock:fail];
}

- (RKManagedObjectRequestOperation *)shareSequenceToTwitter:(VSequence*)sequence
                                               successBlock:(VSuccessBlock)success
                                                  failBlock:(VFailBlock)fail
{
    return [self shareSequence:sequence shareType:@"twitter" successBlock:success failBlock:fail];
}

- (RKManagedObjectRequestOperation *)shareSequenceToFacebook:(VSequence*)sequence
                                                successBlock:(VSuccessBlock)success
                                                   failBlock:(VFailBlock)fail
{
    return [self shareSequence:sequence shareType:@"facebook" successBlock:success failBlock:fail];
}

#pragma mark - Sequence Vote Methods
- (RKManagedObjectRequestOperation *)voteSequence:(VSequence*)sequence
                                        voteTypes:(NSArray*)voteTypes
                                       votecounts:(NSArray*)voteCounts
                                     successBlock:(VSuccessBlock)success
                                        failBlock:(VFailBlock)fail
{
    NSDictionary* parameters = @{@"sequence_id":sequence.remoteId.stringValue ?: [NSNull null],
                                 @"votetypes": voteTypes ?: [NSNull null],
                                 @"votecounts": voteCounts ?: [NSNull null]
                                 };
    
    return [self POST:@"/api/sequence/vote"
               object:nil
           parameters:parameters
         successBlock:success
            failBlock:fail];
}

#pragma mark - Poll Methods

- (RKManagedObjectRequestOperation *)answerPoll:(VSequence*)poll
                                     withAnswer:(VAnswer*)answer
                                   successBlock:(VSuccessBlock)success
                                      failBlock:(VFailBlock)fail;
{
    if (!poll || !answer)
        return nil;
    
    VSuccessBlock fullSuccess = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        VPollResult *newPollResult = [NSEntityDescription
                                        insertNewObjectForEntityForName:[VPollResult entityName]
                                        inManagedObjectContext:self.mainUser.managedObjectContext];
        newPollResult.answerId = answer.remoteId;
        newPollResult.sequenceId = poll.remoteId;
        [self.mainUser addPollResultsObject:newPollResult];
        
        [self.mainUser.managedObjectContext performBlockAndWait:^
         {
             [self.mainUser.managedObjectContext save:nil];
         }];
        
        if (success)
            success(operation, fullResponse, resultObjects);
    };
    
    return [self POST:@"/api/pollresult/create"
               object:nil
           parameters:@{@"sequence_id" : poll.remoteId ?: [NSNull null],
                        @"answer_id" : answer.remoteId ?: [NSNull null]
                        }
         successBlock:fullSuccess
            failBlock:fail];
}

- (RKManagedObjectRequestOperation *)pollResultsForUser:(VUser*)user
                                           successBlock:(VSuccessBlock)success
                                              failBlock:(VFailBlock)fail
{
    user = user ?: self.mainUser;
    
    if (!user)
        return nil;
    
    NSString* path = [@"/api/pollresult/summary_by_user/" stringByAppendingString: user.remoteId.stringValue];
    
    VSuccessBlock fullSuccess = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        for (VPollResult* pollResult in resultObjects)
        {
            VPollResult* poll = (VPollResult*)[user.managedObjectContext objectWithID:[pollResult objectID]];
            [user addPollResultsObject: poll];
        }
        
        [user.managedObjectContext performBlockAndWait:^
         {
             [user.managedObjectContext save:nil];
         }];

        [[NSNotificationCenter defaultCenter] postNotificationName:kPollResultsLoaded object:nil];
        
        if (success)
            success(operation, fullResponse, resultObjects);
    };
    
    return [self GET:path
              object:nil
          parameters:nil
            successBlock:fullSuccess
           failBlock:fail];
}




- (RKManagedObjectRequestOperation *)pollResultsForSequence:(VSequence*)sequence
                                               successBlock:(VSuccessBlock)success
                                                  failBlock:(VFailBlock)fail
{
    if (!sequence)
        return nil;
    
    VSuccessBlock fullSuccess = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        NSManagedObjectContext* context;
        for (VPollResult* result in resultObjects)
        {
            result.sequenceId = sequence.remoteId;
            result.sequence = (VSequence*)[result.managedObjectContext objectWithID:[sequence objectID]];
            context = result.managedObjectContext;
        }
        
        [context performBlockAndWait:^
         {
             [context save:nil];
         }];
      
        if(success)
            success(operation, fullResponse, resultObjects);
    };
    
    return [self GET:[@"/api/pollresult/summary_by_sequence/" stringByAppendingString:sequence.remoteId.stringValue]
              object:nil
          parameters:nil
        successBlock:fullSuccess
           failBlock:fail];
}

#pragma mark - Create Methods
- (AFHTTPRequestOperation * )createPollWithName:(NSString*)name
                                    description:(NSString*)description
                                       question:(NSString*)question
                                    answer1Text:(NSString*)answer1Text
                                    answer2Text:(NSString*)answer2Text
                                     media1Data:(NSData*)media1Data
                                media1Extension:(NSString*)media1Extension
                                     media2Data:(NSData*)media2Data
                                media2Extension:(NSString*)media2Extension
                                   successBlock:(VSuccessBlock)success
                                      failBlock:(VFailBlock)fail
{
    //Required Fields
    NSDictionary* parameters = @{@"name":name ?: [NSNull null],
                                 @"description":description ?: [NSNull null],
                                 @"question":question ?: [NSNull null],
                                 @"answer1_label" : answer1Text ?: [NSNull null],
                                 @"answer2_label" : answer2Text ?: [NSNull null]};

    NSMutableDictionary *allData = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *allExtensions = [[NSMutableDictionary alloc] init];

    if (media1Data && ![media1Extension isEmpty] && media2Data && ![media2Extension isEmpty])
    {
        allData[@"answer1_media"] = media1Data;
        allExtensions[@"answer1_media"] = media1Extension;

        allData[@"answer2_media"] = media2Data;
        allExtensions[@"answer2_media"] = media2Extension;
    }
    else if (media1Data && ![media1Extension isEmpty] )
    {
        allData[@"poll_media"] = media1Data;
        allExtensions[@"poll_media"] = media1Extension;
    }
    
    VSuccessBlock fullSuccess = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        if ([fullResponse[@"error"] integerValue] == 0)
        {
            NSDictionary* payload = fullResponse[@"payload"];
            if (![payload isKindOfClass:[NSDictionary class]])
            {
                payload = nil;
            }
            
            NSNumber* sequenceID = payload[@"sequence_id"];

            [self fetchSequence:sequenceID
                   successBlock:success
                      failBlock:fail];
        }
        else
        {
            NSError*    error = [NSError errorWithDomain:NSCocoaErrorDomain code:[fullResponse[@"error"] integerValue] userInfo:nil];
            if (fail)
                fail(operation, error);
        }
    };
    
    return [self upload:allData
          fileExtension:allExtensions
                 toPath:@"/api/poll/create"
             parameters:parameters
           successBlock:fullSuccess
              failBlock:fail];
}

- (AFHTTPRequestOperation * )uploadMediaWithName:(NSString*)name
                                     description:(NSString*)description
                                       expiresAt:(NSString*)expiresAt
                                    parentNodeId:(NSNumber*)parentNodeId
                                           speed:(CGFloat)speed
                                        loopType:(VLoopType)loopType
                                    shareOptions:(VShareOptions)shareOptions
                                       mediaData:(NSData*)mediaData
                                       extension:(NSString*)extension
                                    successBlock:(VSuccessBlock)success
                                       failBlock:(VFailBlock)fail
{
    if (!mediaData || !extension)
        return nil;
    
    NSMutableDictionary* parameters = [@{@"name":name ?: [NSNull null],
                                         @"speed":@(speed) ?:@(1),
                                         @"description":description ?: [NSNull null]} mutableCopy];
    if (expiresAt)
        parameters[@"expires_at"] = expiresAt;
    if (parentNodeId)
        parameters[@"parent_node_id"] = parentNodeId;
    if (shareOptions & kVShareToFacebook)
        parameters[@"share_facebook"] = @"1";
    if (shareOptions & kVShareToTwitter)
        parameters[@"share_twitter"] = @"1";
    
    NSString* loopParam = [self stringForLoopType:loopType];
    if (loopParam)
        parameters[@"playback"] = loopParam;
    
    NSDictionary* allData = @{@"media_data":mediaData ?: [NSNull null]};
    NSDictionary* allExtensions = @{@"media_data":extension ?: [NSNull null]};
    
    VSuccessBlock fullSuccess = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        NSDictionary* payload = fullResponse[@"payload"];
        if (![payload isKindOfClass:[NSDictionary class]])
        {
            payload = nil;
        }
        
        NSNumber* sequenceID = payload[@"sequence_id"];

        [self fetchSequence:sequenceID
               successBlock:success
                  failBlock:fail];
    };
    
    return [self upload:allData
          fileExtension:allExtensions
                 toPath:@"/api/mediaupload/create"
             parameters:[parameters copy]
           successBlock:fullSuccess
              failBlock:fail];
}

- (NSString*)stringForLoopType:(VLoopType)type
{
    if (type == kVLoopRepeat)
        return @"loop";
    if (type == kVLoopReverse)
        return @"reverse";
    return nil;
}

@end
