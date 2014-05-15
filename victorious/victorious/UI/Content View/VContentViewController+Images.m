//
//  VContentViewController+Images.m
//  victorious
//
//  Created by Will Long on 3/26/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VContentViewController+Images.h"
#import "VContentViewController+Private.h"
#import "VContentViewController+Videos.h"

@implementation VContentViewController (Images)

- (void)loadImage
{
    NSURL* imageUrl;
    if ([self.currentAsset.type isEqualToString:VConstantsMediaTypeImage])
    {
        imageUrl = [NSURL URLWithString:self.currentAsset.data];
    }
    else
    {
        imageUrl = [NSURL URLWithString:self.sequence.previewImage];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imageUrl];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    [self.previewImage setImageWithURLRequest:request
                             placeholderImage:self.backgroundImage.image
                                      success:nil
                                      failure:nil];
    
    self.previewImage.hidden = NO;
    self.pollPreviewView.hidden = YES;
    self.remixButton.hidden = YES;
    if ([self isVideoLoadingOrLoaded])
    {
        [self unloadVideoWithDuration:0 completion:nil];
    }
}

@end
