//
//  VObjectManager+Sequence.m
//  victoriOS
//
//  Created by David Keegan on 12/10/13.
//  Copyright (c) 2013 Victorious, Inc. All rights reserved.
//

#import "VObjectManager+Private.h"
#import "VObjectManager+Users.h"
#import "VObjectManager+Login.h"

#import "VUser+RestKit.h"
#import "VCategory+RestKit.h"
#import "VSequence+RestKit.h"
#import "VStatSequence+RestKit.h"

#import "VPollResult.h"

#import "VPaginationStatus.h"

#import "NSString+VParseHelp.h"

@implementation VObjectManager (Sequence)

#pragma mark - Sequences

- (RKManagedObjectRequestOperation *)initialSequenceLoad
{
    return [[VObjectManager sharedManager] loadSequenceCategoriesWithSuccessBlock:^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
      {
          
          [self loadNextPageOfSequencesForCategory:nil
                                      successBlock:nil
                                         failBlock:nil];
          [self loadNextPageOfSequencesForCategory:kFeaturedCategory
                                      successBlock:nil
                                         failBlock:nil];
      } failBlock:nil];
}

- (RKManagedObjectRequestOperation *)loadSequenceCategoriesWithSuccessBlock:(VSuccessBlock)success
                                                                  failBlock:(VFailBlock)fail
{
    return [self GET:@"/api/sequence/categories"
               object:nil
           parameters:nil
         successBlock:success
            failBlock:fail];
}

/*! Loads the next page of sequences for the category
 * \param category: category of sequences to load
 * \returns RKManagedObjectRequestOperation* or nil if theres no more pages to load
 */
- (RKManagedObjectRequestOperation *)loadNextPageOfSequencesForCategory:(NSString*)category
                                                           successBlock:(VSuccessBlock)success
                                                              failBlock:(VFailBlock)fail
{
    __block VPaginationStatus* status = [self statusForKey:category ?: @"nocategory"];
    if([status isFullyLoaded])
    {
        return nil;
    }
    
    NSString* path = [NSString stringWithFormat:@"/api/sequence/detail_list_by_category/%@", category ?: @"0"];
    if (!status.pagesLoaded)
    {
        path = [path stringByAppendingFormat:@"/0/%lu/%lu", (unsigned long)status.pagesLoaded, (unsigned long)status.itemsPerPage];
    } else
    {
        path = [path stringByAppendingFormat:@"/0/%lu/%lu", (unsigned long)status.pagesLoaded + 1, (unsigned long)status.itemsPerPage];
    }
    
    VSuccessBlock fullSuccessBlock = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        status.pagesLoaded = [fullResponse[@"page_number"] integerValue];
        status.totalPages = [fullResponse[@"page_total"] integerValue];
        [self.paginationStatuses setObject:status forKey:category];
        
        //If we don't have the user then we need to fetch em.
        NSMutableArray* nonExistantUsers = [[NSMutableArray alloc] init];
        for (VSequence* sequence in resultObjects)
        {
            if (!sequence.user)
            {
                [nonExistantUsers addObject:sequence.createdBy];
            }
        }
        
        if ([nonExistantUsers count])
            [[VObjectManager sharedManager] fetchUsers:nonExistantUsers
                                      withSuccessBlock:success
                                             failBlock:fail];
        
        else if (success)
            success(operation, fullResponse, resultObjects);
    };
    
    return [self GET:path
              object:nil
          parameters:nil
        successBlock:fullSuccessBlock
           failBlock:fail];
}

- (RKManagedObjectRequestOperation *)fetchSequence:(VSequence*)sequence
                                      successBlock:(VSuccessBlock)success
                                         failBlock:(VFailBlock)fail
{
    return [self fetchSequenceByID:sequence.remoteId
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
        return nil;
    
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
    
    __block NSString* statusKey = [NSString stringWithFormat:@"commentsForSequence%@", sequence.remoteId];
    __block VPaginationStatus* status = [self statusForKey:statusKey];
    if([status isFullyLoaded])
        return nil;
    
    NSString* path = [NSString stringWithFormat:@"/api/comment/all/%@", sequence.remoteId];
    if (status.pagesLoaded) //only add page to the path if we've looked it up before.
    {
        path = [path stringByAppendingFormat:@"/%lu/%lu", (unsigned long)status.pagesLoaded + 1, (unsigned long)status.itemsPerPage];
    }
    
    __block VSequence* commentOwner = sequence; //Keep the sequence around until the block gets called
    VSuccessBlock fullSuccessBlock = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        status.pagesLoaded = [fullResponse[@"page_number"] integerValue];
        status.totalPages = [fullResponse[@"page_total"] integerValue];
        [self.paginationStatuses setObject:status forKey:statusKey];
        
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
    NSMutableDictionary* parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    [parameters setObject:[NSString stringWithFormat:@"%@", sequence.remoteId] forKey:@"sequence_id"];
    [parameters setObject:type forKey:@"shared_to"];
    
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
                                        voteType:(NSString*)type
                                    successBlock:(VSuccessBlock)success
                                       failBlock:(VFailBlock)fail
{
    NSMutableDictionary* parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    [parameters setObject:[NSString stringWithFormat:@"%@", sequence.remoteId] forKey:@"sequence_id"];
    [parameters setObject:type forKey:@"vote"];
    
    return [self POST:@"/api/sequence/vote"
               object:nil
           parameters:parameters
         successBlock:success
            failBlock:fail];
}

- (RKManagedObjectRequestOperation *)likeSequence:(VSequence*)sequence
                                     successBlock:(VSuccessBlock)success
                                        failBlock:(VFailBlock)fail
{
    return [self voteSequence:sequence voteType:@"like" successBlock:success failBlock:fail];
}

- (RKManagedObjectRequestOperation *)dislikeSequence:(VSequence*)sequence
                                        successBlock:(VSuccessBlock)success
                                           failBlock:(VFailBlock)fail
{
    return [self voteSequence:sequence voteType:@"dislike" successBlock:success failBlock:fail];
}

- (RKManagedObjectRequestOperation *)unvoteSequence:(VSequence*)sequence
                                       successBlock:(VSuccessBlock)success
                                          failBlock:(VFailBlock)fail
{
    return [self voteSequence:sequence voteType:@"unvote" successBlock:success failBlock:fail];
}

#pragma mark - StatSequence Methods

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
        [self.mainUser.managedObjectContext save:nil];
        
        if (success)
            success(operation, fullResponse, resultObjects);
    };
    
    return [self POST:@"/api/pollresult/create"
               object:nil
           parameters:@{@"sequence_id" : poll.remoteId, @"answer_id" : answer.remoteId}
         successBlock:fullSuccess
            failBlock:fail];
}

- (RKManagedObjectRequestOperation *)pollResultsForUser:(VUser*)user
                                           successBlock:(VSuccessBlock)success
                                              failBlock:(VFailBlock)fail
{
    if (!user)
        user = self.mainUser;
    
    NSString* path = [NSString stringWithFormat:@"/api/pollresult/summary_by_user/%@", user.remoteId];
    
    VSuccessBlock fullSuccess = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        for (VPollResult* pollResult in resultObjects)
        {
            VPollResult* poll = (VPollResult*)[user.managedObjectContext objectWithID:[pollResult objectID]];
            [user addPollResultsObject: poll];
        }
        [user.managedObjectContext save:nil];
        
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
        for (VPollResult* result in resultObjects)
        {
            result.sequenceId = sequence.remoteId;
            result.sequence = (VSequence*)[result.managedObjectContext objectWithID:[sequence objectID]];
            [result.managedObjectContext save:nil];
        }
      
        if(success)
            success(operation, fullResponse, resultObjects);
    };
    
    return [self GET:[NSString stringWithFormat:@"/api/pollresult/summary_by_sequence/%@", sequence.remoteId]
              object:nil
          parameters:nil
        successBlock:fullSuccess
           failBlock:fail];
}

- (AFHTTPRequestOperation * )createPollWithName:(NSString*)name
                                    description:(NSString*)description
                                       question:(NSString*)question
                                    answer1Text:(NSString*)answer1Text
                                    answer2Text:(NSString*)answer2Text
                                     media1Data:(NSData*)media1Data
                                media1Extension:(NSString*)media1Extension
                                      media1Url:(NSURL*)media1Url
                                     media2Data:(NSData*)media2Data
                                media2Extension:(NSString*)media2Extension
                                      media2Url:(NSURL*)media2Url
                                   successBlock:(VSuccessBlock)success
                                      failBlock:(VFailBlock)fail
{
    //Required Fields
    NSString* category = self.isOwner ? kVOwnerPollCategory : kVUGCPollCategory;
    NSMutableDictionary* parameters = [@{@"name":name ?: [NSNull null],
                                         @"description":description ?: [NSNull null],
                                         @"question":question ?: [NSNull null],
                                         @"category":category} mutableCopy];

    //Optional fields
    if (answer1Text)
        parameters[@"answer1_label"] = answer1Text ?: [NSNull null];
    if (answer2Text)
        parameters[@"answer2_label"] = answer2Text ?: [NSNull null];
    
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
            NSNumber* sequenceID = fullResponse[@"payload"][@"sequence_id"];
            [self fetchSequenceByID:sequenceID
                        successBlock:success
                           failBlock:fail
                         loadAttempt:0];
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

- (AFHTTPRequestOperation * )createVideoWithName:(NSString*)name
                                     description:(NSString*)description
                                       mediaData:(NSData*)mediaData
                                        mediaUrl:(NSURL*)mediaUrl
                                    successBlock:(VSuccessBlock)success
                                       failBlock:(VFailBlock)fail
{
    NSString* category = self.isOwner ? kVOwnerVideoCategory : kVUGCVideoCategory;
    return [self uploadMediaWithName:name
                         description:description
                            category:category
                           mediaData:mediaData
                           extension:VConstantMediaExtensionMOV
                            mediaUrl:nil
                        successBlock:success
                           failBlock:fail];
}

- (AFHTTPRequestOperation * )createImageWithName:(NSString*)name
                                     description:(NSString*)description
                                       mediaData:(NSData*)mediaData
                                        mediaUrl:(NSURL*)mediaUrl
                                    successBlock:(VSuccessBlock)success
                                       failBlock:(VFailBlock)fail
{
    NSString* category = self.isOwner ? kVOwnerImageCategory : kVUGCImageCategory;
    return [self uploadMediaWithName:name
                         description:description
                            category:category
                           mediaData:mediaData
                           extension:VConstantMediaExtensionPNG
                            mediaUrl:nil
                        successBlock:success
                           failBlock:fail];
}

- (AFHTTPRequestOperation * )createForumWithName:(NSString*)name
                                     description:(NSString*)description
                                       mediaData:(NSData*)mediaData
                                        mediaUrl:(NSURL*)mediaUrl
                                    successBlock:(VSuccessBlock)success
                                       failBlock:(VFailBlock)fail
{
    NSString* category = self.isOwner ? kVOwnerForumCategory : kVUGCForumCategory;
    return [self uploadMediaWithName:name
                         description:description
                            category:category
                           mediaData:mediaData
                           extension:VConstantMediaExtensionPNG
                            mediaUrl:nil
                        successBlock:success
                           failBlock:fail];
}

- (AFHTTPRequestOperation * )uploadMediaWithName:(NSString*)name
                                     description:(NSString*)description
                                        category:(NSString*)category
                                       mediaData:(NSData*)mediaData
                                       extension:(NSString*)extension
                                        mediaUrl:(NSURL*)mediaUrl
                                    successBlock:(VSuccessBlock)success
                                       failBlock:(VFailBlock)fail
{
    if (!mediaData || !extension)
        return nil;
    
    NSDictionary* parameters = @{@"name":name ?: [NSNull null],
                                 @"description":description ?: [NSNull null],
                                 @"category":category ?: [NSNull null]};
    
    NSDictionary* allData = @{@"media_data":mediaData ?: [NSNull null]};
    NSDictionary* allExtensions = @{@"media_data":extension ?: [NSNull null]};
    
    VSuccessBlock fullSuccess = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        NSNumber* sequenceID = fullResponse[@"payload"][@"sequence_id"];
        [self fetchSequenceByID:sequenceID
                   successBlock:success
                      failBlock:fail
                     loadAttempt:0];
    };
    
    return [self upload:allData
          fileExtension:allExtensions
                 toPath:@"/api/mediaupload/create"
             parameters:parameters
           successBlock:fullSuccess
              failBlock:fail];
}

@end
