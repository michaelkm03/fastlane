//
//  VStatSequence.h
//  victoriOS
//
//  Created by David Keegan on 12/12/13.
//  Copyright (c) 2013 Victorious, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VStatInteraction, VUser;

@interface VStatSequence : NSManagedObject

@property (nonatomic, retain) NSDate * completedAt;
@property (nonatomic, retain) NSNumber * correctAnswers;
@property (nonatomic, retain) NSNumber * statSequenceId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * questionsAnswered;
@property (nonatomic, retain) NSString * outcome;
@property (nonatomic, retain) NSNumber * possiblePoints;
@property (nonatomic, retain) NSNumber * totalPoints;
@property (nonatomic, retain) NSNumber * totalQuestions;
@property (nonatomic, retain) NSSet *interactionDetails;
@property (nonatomic, retain) VUser *user;
@end

@interface VStatSequence (CoreDataGeneratedAccessors)

- (void)addInteractionDetailsObject:(VStatInteraction *)value;
- (void)removeInteractionDetailsObject:(VStatInteraction *)value;
- (void)addInteractionDetails:(NSSet *)values;
- (void)removeInteractionDetails:(NSSet *)values;

@end
