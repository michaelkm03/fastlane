//
//  Node+RestKit.m
//  victoriOS
//
//  Created by Will Long on 11/30/13.
//  Copyright (c) 2013 Will Long. All rights reserved.
//

#import "VNode+RestKit.h"

@implementation VNode (RestKit)

+ (NSString *)entityName
{
    return @"Node";
}

+ (RKEntityMapping*)entityMapping
{
    NSDictionary *propertyMap = @{
                                  @"display_order" : VSelectorName(displayOrder),
                                  @"node_id" : VSelectorName(nodeId)
                                  };
    
    RKEntityMapping *mapping = [RKEntityMapping
                                mappingForEntityForName:[self entityName]
                                inManagedObjectStore:[RKObjectManager sharedManager].managedObjectStore];
    
    mapping.identificationAttributes = @[ VSelectorName(nodeId) ];
    
    [mapping addAttributeMappingsFromDictionary:propertyMap];
    
    //Now add relationships
    [mapping addRelationshipMappingWithSourceKeyPath:VSelectorName(assets) mapping:[VAsset entityMapping]];
    [mapping addRelationshipMappingWithSourceKeyPath:VSelectorName(interactions) mapping:[VInteraction entityMapping]];
    [mapping addRelationshipMappingWithSourceKeyPath:VSelectorName(nodeAction) mapping:[VNodeAction entityMapping]];
    
    return mapping;
}

@end
