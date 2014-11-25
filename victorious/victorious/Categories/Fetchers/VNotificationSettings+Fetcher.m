//
//  VNotificationSettings+Fetcher.m
//  victorious
//
//  Created by Patrick Lynch on 11/24/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VNotificationSettings.h"
#import "VObjectManager.h"
#import "VNotificationSettings+RestKit.h"

@implementation VNotificationSettings (Fetcher)

+ (VNotificationSettings *)createDefaultSettings
{
    NSString *entityName = [VNotificationSettings entityName];
    id obj = [[VObjectManager sharedManager] objectWithEntityName:entityName subclass:[VNotificationSettings class]];
    NSAssert( [obj isKindOfClass:[VNotificationSettings class]], @"" );
    return obj;
}

@end
