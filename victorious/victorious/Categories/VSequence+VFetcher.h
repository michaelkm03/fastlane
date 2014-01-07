//
//  VSequence+VFetcher.h
//  victorious
//
//  Created by Will Long on 1/7/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VSequence.h"

extern  NSString*   const   kVOwnerPollCategory;
extern  NSString*   const   kVOwnerImageCategory;
extern  NSString*   const   kVOwnerVideoCategory;
extern  NSString*   const   kVOwnerForumCategory;

extern  NSString*   const   kVUGCPollCategory;
extern  NSString*   const   kVUGCImageCategory;
extern  NSString*   const   kVUGCVideoCategory;
extern  NSString*   const   kVUGCForumCategory;

@interface VSequence (VFetcher)

- (BOOL)isPoll;
- (BOOL)isImage;
- (BOOL)isVideo;
- (BOOL)isForum;
- (BOOL)isOwnerContent;


@end
