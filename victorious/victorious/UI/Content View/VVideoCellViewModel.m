//
//  VVideoCellViewModel.m
//  victorious
//
//  Created by Michael Sena on 10/22/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VVideoCellViewModel.h"

@interface VVideoCellViewModel ()

@property (nonatomic, strong, readwrite) NSURL *itemURL;
@property (nonatomic, assign, readwrite) VMonetizationPartner monetizationPartner;
@property (nonatomic, strong, readwrite) NSArray *monetizationDetails;

@end

@implementation VVideoCellViewModel

+ (instancetype)videoCellViewModelWithItemURL:(NSURL *)itemURL
                                 withAdSystem:(VMonetizationPartner)monetizationPartner
                                 withDetails:(NSArray *)details
{
    if (![itemURL isKindOfClass:[NSURL class]])
    {
        return nil;
    }
    
    VVideoCellViewModel *videoCellViewModel = [[VVideoCellViewModel alloc] init];
    videoCellViewModel.itemURL = itemURL;
    videoCellViewModel.monetizationPartner = monetizationPartner;
    videoCellViewModel.monetizationDetails = details;
    
    return videoCellViewModel;
}

@end
