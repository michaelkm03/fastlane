//
//  VProfileDeeplinkHandler.m
//  victorious
//
//  Created by Patrick Lynch on 4/6/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VProfileDeeplinkHandler.h"
#import "VUserProfileViewController.h"
#import "VDependencyManager.h"
#import "NSURL+VPathHelper.h"

static NSString * const kProfileDeeplinkHostComponent = @"profile";

@implementation VProfileDeeplinkHandler

- (BOOL)canDisplayContentForDeeplinkURL:(NSURL *)url
{
    const BOOL isValidUserID = [url v_firstNonSlashPathComponent] != nil && [[url v_firstNonSlashPathComponent] integerValue] > 0;
    const BOOL isValidHost = [url.host isEqualToString:kProfileDeeplinkHostComponent];
    return isValidUserID && isValidHost;
}

- (BOOL)requiresAuthorization
{
    return NO;
}

- (BOOL)displayContentForDeeplinkURL:(NSURL *)url completion:(VDeeplinkHandlerCompletionBlock)completion
{
    NSInteger userID = [[url v_firstNonSlashPathComponent] integerValue];
    VUserProfileViewController *profileVC = [self.dependencyManager userProfileViewControllerWithRemoteId:@(userID)];
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       completion( profileVC );
                   });
    return YES;
}

@end
