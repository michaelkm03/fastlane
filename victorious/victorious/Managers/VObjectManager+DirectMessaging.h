//
//  VObjectManager+DirectMessaging.h
//  victorious
//
//  Created by Will Long on 1/8/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VObjectManager.h"

#import "VConversation.h"

@interface VObjectManager (DirectMessaging)

- (VConversation*)conversationWithUser:(VUser*)user
                          successBlock:(VSuccessBlock)success
                             failBlock:(VFailBlock)fail;

- (RKManagedObjectRequestOperation *)conversationByID:(NSNumber*)conversationID
                                         successBlock:(VSuccessBlock)success
                                            failBlock:(VFailBlock)fail;

- (RKManagedObjectRequestOperation *)markConversationAsRead:(VConversation*)conversation
                                               successBlock:(VSuccessBlock)success
                                                  failBlock:(VFailBlock)fail;

- (RKManagedObjectRequestOperation *)unreadCountForConversationsWithSuccessBlock:(VSuccessBlock)success
                                                                       failBlock:(VFailBlock)fail;

- (RKManagedObjectRequestOperation *) deleteConversation:(VConversation*)conversation
                                            successBlock:(VSuccessBlock)success
                                               failBlock:(VFailBlock)fail;

- (RKManagedObjectRequestOperation *) flagConversation:(VConversation*)conversation
                                          successBlock:(VSuccessBlock)success
                                             failBlock:(VFailBlock)fail;

@end
