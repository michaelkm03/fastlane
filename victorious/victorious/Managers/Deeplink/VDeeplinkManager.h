//
//  VDeeplinkManager.h
//  victorious
//
//  Created by Will Long on 6/17/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VDeeplinkManager : NSObject

+ (instancetype)sharedManager;

- (void)handleOpenURL:(NSURL *)aURL;

@end
