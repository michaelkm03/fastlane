//
//  VGifLinkViewController.m
//  victorious
//
//  Created by Sharif Ahmed on 7/19/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VGifLinkViewController.h"

@implementation VGifLinkViewController

- (instancetype)initWithUrl:(NSURL *)url
{
    return [super initWithUrl:url];
}

- (BOOL)loop
{
    return YES;
}

- (BOOL)muteAudio
{
    return YES;
}

- (BOOL)hidePlayControls
{
    return YES;
}

@end