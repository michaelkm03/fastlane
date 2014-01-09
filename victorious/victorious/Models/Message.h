//
//  Message.h
//  victorious
//
//  Created by Will Long on 1/8/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VConversation, VMedia, VUser;

@interface Message : NSManagedObject

@property (nonatomic, retain) NSNumber * isRead;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * remoteId;
@property (nonatomic, retain) VConversation *conversation;
@property (nonatomic, retain) VMedia *media;
@property (nonatomic, retain) VUser *user;

@end
