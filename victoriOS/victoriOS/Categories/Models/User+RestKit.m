//
//  User+RestKit.m
//  victoriOS
//
//  Created by Will Long on 11/27/13.
//  Copyright (c) 2013 Will Long. All rights reserved.
//

#import "User+RestKit.h"

@implementation User (RestKit)
/*
 @property (nonatomic, retain) NSString * access_level;
 @property (nonatomic, retain) NSString * email;
 @property (nonatomic, retain) NSNumber * id;
 @property (nonatomic, retain) NSString * name;
 @property (nonatomic, retain) NSString * token;*/

+(RKEntityMapping*)entityMapping
{
    NSDictionary *propertyMap = @{
                                          @"access_level" : @"access_level",
                                          @"email" : @"email",
                                          @"id" : @"id",
                                          @"name" : @"name",
                                          @"token" : @"token",
                                          @"token_updated_at" : @"token_updated_at"
                                          };
    
    RKEntityMapping *mapping = [RKEntityMapping
                                        mappingForEntityForName:NSStringFromClass([User class])
                                        inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    
    mapping.identificationAttributes = @[ @"id" ];
    
    [mapping addAttributeMappingsFromDictionary:propertyMap];

    return mapping;
}

@end
