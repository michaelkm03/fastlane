//
//  VCategory+RestKit.h
//  victoriOS
//
//  Created by Will Long on 11/30/13.
//  Copyright (c) 2013 Victorious Inc. All rights reserved.
//

#import "VCategory.h"
#import "NSManagedObject+RestKit.h"

@interface VCategory (RestKit)

+ (RKResponseDescriptor*)descriptor;

@end
