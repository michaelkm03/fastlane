//
//  VUser.h
//  victorious
//
//  Created by Will Long on 8/19/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VComment, VConversation, VMessage, VNotification, VPollResult, VSequence, VUnreadConversation, VUser;

@interface VUser : NSManagedObject

@property (nonatomic, retain) NSString * accessLevel;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * pictureUrl;
@property (nonatomic, retain) NSString * profileImagePathOriginal;
@property (nonatomic, retain) NSString * profileImagePathSmall;
@property (nonatomic, retain) NSNumber * remoteId;
@property (nonatomic, retain) NSString * tagline;
@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) NSDate * tokenUpdatedAt;
@property (nonatomic, retain) NSSet *childSequences;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) VConversation *conversation;
@property (nonatomic, retain) NSSet *followers;
@property (nonatomic, retain) NSSet *following;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) VNotification *notifications;
@property (nonatomic, retain) NSSet *pollResults;
@property (nonatomic, retain) NSSet *postedSequences;
@property (nonatomic, retain) NSSet *remixedSequences;
@property (nonatomic, retain) VSequence *repostedSequences;
@property (nonatomic, retain) VUnreadConversation *unreadConversation;
@end

@interface VUser (CoreDataGeneratedAccessors)

- (void)addChildSequencesObject:(VSequence *)value;
- (void)removeChildSequencesObject:(VSequence *)value;
- (void)addChildSequences:(NSSet *)values;
- (void)removeChildSequences:(NSSet *)values;

- (void)addCommentsObject:(VComment *)value;
- (void)removeCommentsObject:(VComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addFollowersObject:(VUser *)value;
- (void)removeFollowersObject:(VUser *)value;
- (void)addFollowers:(NSSet *)values;
- (void)removeFollowers:(NSSet *)values;

- (void)addFollowingObject:(VUser *)value;
- (void)removeFollowingObject:(VUser *)value;
- (void)addFollowing:(NSSet *)values;
- (void)removeFollowing:(NSSet *)values;

- (void)addMessagesObject:(VMessage *)value;
- (void)removeMessagesObject:(VMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

- (void)addPollResultsObject:(VPollResult *)value;
- (void)removePollResultsObject:(VPollResult *)value;
- (void)addPollResults:(NSSet *)values;
- (void)removePollResults:(NSSet *)values;

- (void)addPostedSequencesObject:(VSequence *)value;
- (void)removePostedSequencesObject:(VSequence *)value;
- (void)addPostedSequences:(NSSet *)values;
- (void)removePostedSequences:(NSSet *)values;

- (void)addRemixedSequencesObject:(VSequence *)value;
- (void)removeRemixedSequencesObject:(VSequence *)value;
- (void)addRemixedSequences:(NSSet *)values;
- (void)removeRemixedSequences:(NSSet *)values;

@end