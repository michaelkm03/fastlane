//
//  Comment.h
//  victoriOS
//
//  Created by Will Long on 11/25/13.
//  Copyright (c) 2013 Will Long. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Sequence;

@interface Comment : NSManagedObject

@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * media_type;
@property (nonatomic, retain) id media_url;
@property (nonatomic, retain) NSNumber * parent_id;
@property (nonatomic, retain) NSDate * posted_at;
@property (nonatomic, retain) NSNumber * sequence_id;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) Sequence *sequence;

@end
