//
//  User+RestKit.h
//  victoriOS
//
//  Created by Will Long on 11/27/13.
//  Copyright (c) 2013 Will Long. All rights reserved.
//

#import "User.h"

@interface User (RestKit)

+(RKEntityMapping*)entityMapping;

@end
