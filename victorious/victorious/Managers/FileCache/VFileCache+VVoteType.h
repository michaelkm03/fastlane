//
//  VFileCache+VVoteType.h
//  victorious
//
//  Created by Patrick Lynch on 10/13/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString * const VVoteTypeFilepathFormat;
extern NSString * const VVoteTypeSpriteNameFormat;
extern NSString * const VVoteTypeIconName;

@class VVoteType;

@interface VFileCache (VVoteType)

/**
 Download and save the files to the cache directory asynchronously
 */
- (BOOL)cacheImagesForVoteType:(VVoteType *)voteType;

/**
 Retrieve an image synchronously.
 */
- (UIImage *)getImageWithName:(NSString *)imageName forVoteType:(VVoteType *)voteType;

/**
 Retrieve an array of sprite images synchronously.
 */
- (NSArray *)getSpriteImagesForVoteType:(VVoteType *)voteType;

/**
 Retrieve an array of sprite images asynchronously.
 */
- (BOOL)getSpriteImagesForVoteType:(VVoteType *)voteType completionCallback:(void(^)(NSArray *))callback;

/**
 Retrieve an image asynchronously.
 */
- (BOOL)getImageWithName:(NSString *)imageName forVoteType:(VVoteType *)voteType completionCallback:(void(^)(UIImage *))callback;

@end
