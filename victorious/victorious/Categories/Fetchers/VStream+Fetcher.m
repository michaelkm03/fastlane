//
//  VStream+Fetcher.m
//  victorious
//
//  Created by Will Long on 9/9/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VStream+Fetcher.h"
#import "VStream+RestKit.h"

#import "VSequence.h"
#import "VObjectManager.h"
#import "VThemeManager.h"
#import "VUser.h"
#import "VPaginationManager.h"
#import "NSCharacterSet+VURLParts.h"

NSString * const VStreamFollowerStreamPath = @"/api/sequence/follows_detail_list_by_stream/";

NSString * const VStreamFilterTypeRecent = @"recent";
NSString * const VStreamFilterTypePopular = @"popular";

@implementation VStream (Fetcher)

- (BOOL)isHashtagStream
{
    return self.hashtag != nil;
}

+ (VStream *)remixStreamForSequence:(VSequence *)sequence
{
    NSString *escapedRemoteId = [(sequence.remoteId ?: @"0") stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet v_pathPartCharacterSet]];
    NSString *apiPath = [NSString stringWithFormat:@"/api/sequence/remixes_by_sequence/%@/%@/%@",
                         escapedRemoteId, VPaginationManagerPageNumberMacro, VPaginationManagerItemsPerPageMacro];
    return [self streamForPath:apiPath inContext:[[VObjectManager sharedManager].managedObjectStore mainQueueManagedObjectContext]];
}

+ (VStream *)streamForUser:(VUser *)user
{
    NSString *escapedRemoteId = [(user.remoteId.stringValue ?: @"0") stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet v_pathPartCharacterSet]];
    NSString *apiPath = [NSString stringWithFormat:@"/api/sequence/detail_list_by_user/%@/%@/%@",
                         escapedRemoteId, VPaginationManagerPageNumberMacro, VPaginationManagerItemsPerPageMacro];
    return [self streamForPath:apiPath inContext:[[VObjectManager sharedManager].managedObjectStore mainQueueManagedObjectContext]];
}

+ (VStream *)streamForHashTag:(NSString *)hashTag
{
    NSString *escapedHashtag = [hashTag stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet v_pathPartCharacterSet]];
    NSString *apiPath = [NSString stringWithFormat:@"/api/sequence/detail_list_by_hashtag/%@/%@/%@",
                         escapedHashtag, VPaginationManagerPageNumberMacro, VPaginationManagerItemsPerPageMacro];
    NSManagedObjectContext *context = [[VObjectManager sharedManager].managedObjectStore mainQueueManagedObjectContext];
    VStream *stream = [self streamForPath:apiPath inContext:context];
    stream.hashtag = hashTag;
    stream.name = [@"#" stringByAppendingString:hashTag];
    return stream;
}

+ (VStream *)streamForMarqueeInContext:(NSManagedObjectContext *)context
{
    return [self streamForRemoteId:@"marquee" filterName:@"0" managedObjectContext:context];
}

+ (VStream *)streamForRemoteId:(NSString *)remoteId
                    filterName:(NSString *)filterName
          managedObjectContext:(NSManagedObjectContext *)context
{
    NSString *streamIdKey = remoteId ?: @"0";
    NSString *filterIdKey;
    NSString *apiPath = [@"/api/sequence/detail_list_by_stream/" stringByAppendingPathComponent:streamIdKey];
    if (filterName.length)
    {
        filterIdKey = filterName;
        apiPath = [apiPath stringByAppendingPathComponent:filterIdKey];
    }
    
    VStream *stream = [self streamForPath:apiPath inContext:context];
    stream.remoteId = remoteId;
    stream.filterName = filterName;
    [stream.managedObjectContext saveToPersistentStore:nil];
    return stream;
}

+ (VStream *)streamForPath:(NSString *)apiPath
                 inContext:(NSManagedObjectContext *)context
{
    static NSCache *streamCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,
                  ^{
                      streamCache = [[NSCache alloc] init];
                  });
    
    VStream *object = [streamCache objectForKey:apiPath];
    if (object)
    {
        if (object.managedObjectContext != context)
        {
            // If the contexts don't match, release the safety valve: dump all the chached objects and re-create them.
            [streamCache removeAllObjects];
        }
        else
        {
            return object;
        }
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:[VStream entityName]];
    NSPredicate *idFilter = [NSPredicate predicateWithFormat:@"%K == %@", @"apiPath", apiPath];
    [request setPredicate:idFilter];
    NSError *error = nil;
    object = [[context executeFetchRequest:request error:&error] firstObject];
    if (error != nil)
    {
        VLog(@"Error occured in commentForId: %@", error);
    }
    
    if (object)
    {
        [streamCache setObject:object forKey:apiPath];
    }
    else
    {
        //Create a new one if it doesn't exist
        object = [NSEntityDescription insertNewObjectForEntityForName:[VStream entityName]
                                               inManagedObjectContext:context];
        object.apiPath = apiPath;
        object.name = @"";
        object.previewImagesObject = @"";
        [object.managedObjectContext saveToPersistentStore:nil];
        
        [streamCache setObject:object forKey:apiPath];
    }
    
    return object;
}

@end
