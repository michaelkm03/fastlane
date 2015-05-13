//
//  NSURL+VCustomScheme.m
//  victorious
//
//  Created by Patrick Lynch on 4/8/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "NSURL+VCustomScheme.h"

/**
 The generic victorious URL scheme.
 
 @see https://wiki.victorious.com/display/ENG/Deep+Linking+Specification
 */
static NSString * const kVictoriousThisAppGenericScheme = @"vthisapp";

@implementation NSURL (VCustomScheme)

- (BOOL)v_hasCustomScheme
{
    NSArray *nonCustomSchemes = @[ @"http", @"https" ];
    return ![nonCustomSchemes containsObject:self.scheme.lowercaseString] && self.scheme != nil;
}

- (BOOL)v_isThisAppGenericScheme
{
    return [self.scheme.lowercaseString isEqualToString:kVictoriousThisAppGenericScheme];
}

@end
