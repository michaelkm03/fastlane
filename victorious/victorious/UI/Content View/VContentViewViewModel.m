//
//  VContentViewViewModel.m
//  victorious
//
//  Created by Michael Sena on 9/15/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VContentViewViewModel.h"

// Models
#import "VComment.h"
#import "VUser.h"

// Model Categories
#import "VSequence+Fetcher.h"
#import "VNode+Fetcher.h"
#import "VAsset+Fetcher.h"
#import "VObjectManager+Comment.h"
#import "VObjectManager+Pagination.h"
#import "VComment+Fetcher.h"


NSString * const VContentViewViewModelDidUpdateCommentsNotification = @"VContentViewViewModelDidUpdateCommentsNotification";

@interface VContentViewViewModel ()

@property (nonatomic, strong) NSArray *comments;
@property (nonatomic, strong, readonly) VNode *currentNode;
@property (nonatomic, strong, readwrite) VSequence *sequence;
@property (nonatomic, strong, readwrite) VAsset *currentAsset;

@end

@implementation VContentViewViewModel

#pragma mark - Initializers

- (instancetype)initWithSequence:(VSequence *)sequence
{
    self = [super init];
    if (self)
    {
        _sequence = sequence;
        
        if ([sequence isPoll])
        {
            _type = VContentViewTypePoll;
        }
        else if ([sequence isVideo])
        {
            _type = VContentViewTypeVideo;
        }
        else if ([sequence isImage])
        {
            _type = VContentViewTypeImage;
        }
        else
        {
            _type = VContentViewTypeInvalid;
        }

        _currentNode = [sequence firstNode];
        _currentAsset = [_currentNode firstAsset];
        
        [[VObjectManager sharedManager] fetchFiltedRealtimeCommentForAssetId:_currentAsset.remoteId.integerValue
                                                                successBlock:nil
                                                                   failBlock:nil];
        
        [[VObjectManager sharedManager] loadCommentsOnSequence:self.sequence
                                                     isRefresh:NO
                                                  successBlock:^(NSOperation *operation, id result, NSArray *resultObjects) {
                                                      //
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:VContentViewViewModelDidUpdateCommentsNotification
                                                                                                          object:self];
                                                  }
                                                     failBlock:nil];
    }
    return self;
}

- (id)init
{
    [[NSException exceptionWithName:@"Invalid initializer."
                            reason:@"-init is not allowed. Use the designate initializer: \"-initWithSequence:\""
                           userInfo:nil] raise];
    return nil;
}

#pragma mark - Property Accessors

- (NSURLRequest *)imageURLRequest
{
    NSURL* imageUrl;
    if (self.type == VContentViewTypeImage)
    {
        VAsset *currentAsset = [self.currentNode firstAsset];
        imageUrl = [NSURL URLWithString:currentAsset.data];
    }
    else
    {
        imageUrl = [NSURL URLWithString:self.sequence.previewImage];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imageUrl];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    return request;
}

- (NSURL *)videoURL
{
    VAsset *currentAsset = [self.currentNode firstAsset];
    return [NSURL URLWithString:currentAsset.data];
}

- (BOOL)shouldShowRealTimeComents
{
    VAsset *currentAsset = [self.currentNode firstAsset];
    NSArray *realTimeComments = [currentAsset.comments array];
    return (realTimeComments.count > 0) ? YES : NO;
}

- (NSArray *)comments
{
    NSMutableArray *comments = [NSMutableArray new];
    [self.sequence.comments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [comments addObject:obj];
    }];
    _comments = [NSArray arrayWithArray:_comments];
    return comments;
}

- (NSInteger)commentCount
{
    return self.comments.count;
}

#pragma mark - Public Methods

- (NSString *)commentBodyForCommentIndex:(NSInteger)commentIndex
{
    VComment *commentForIndex = [self.comments objectAtIndex:commentIndex];
    return commentForIndex.text;
}

- (NSString *)commenterNameForCommentIndex:(NSInteger)commentIndex
{
    VComment *commentForIndex = [self.comments objectAtIndex:commentIndex];
    return commentForIndex.user.name;
}

- (NSURL *)commenterAvatarULRForCommentIndex:(NSInteger)commentIndex
{
    VComment *commentForIndex = [self.comments objectAtIndex:commentIndex];
    return [NSURL URLWithString:commentForIndex.user.pictureUrl];
}

- (BOOL)commentHasMediaForCommentIndex:(NSInteger)commentIndex
{
    VComment *commentForIndex = [self.comments objectAtIndex:commentIndex];
    return commentForIndex.hasMedia;
}


@end
