//
//  VObjectManager+Discover.h
//  victorious
//
//  Created by Patrick Lynch on 10/7/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VObjectManager.h"

@class VHashtag;

@interface VObjectManager (Discover)

- (RKManagedObjectRequestOperation *)getSuggestedUsers:(VSuccessBlock)success
                                             failBlock:(VFailBlock)fail;

- (RKManagedObjectRequestOperation *)getSuggestedHashtags:(VSuccessBlock)success
                                                failBlock:(VFailBlock)fail;

- (RKManagedObjectRequestOperation *)getHashtagsSubscribedToWithRefresh:(BOOL)refresh
                                                           successBlock:(VSuccessBlock)success
                                                              failBlock:(VFailBlock)fail;

- (RKManagedObjectRequestOperation *)unsubscribeToHashtag:(VHashtag *)hashtag
                                             successBlock:(VSuccessBlock)success
                                                failBlock:(VFailBlock)fail;

- (RKManagedObjectRequestOperation *)subscribeToHashtag:(VHashtag *)hashtag
                                           successBlock:(VSuccessBlock)success
                                              failBlock:(VFailBlock)fail;

@end
