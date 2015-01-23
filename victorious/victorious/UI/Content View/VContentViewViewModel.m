//
//  VContentViewViewModel.m
//  victorious
//
//  Created by Michael Sena on 9/15/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VContentViewViewModel.h"

// Experiments
#import "VSettingManager.h"

// Models
#import "VComment.h"
#import "VUser.h"
#import "VAsset.h"
#import "VAnswer.h"
#import "VPollResult.h"
#import "VNode+Fetcher.h"

// Model Categories
#import "VSequence+Fetcher.h"
#import "VNode+Fetcher.h"
#import "VObjectManager+Comment.h"
#import "VObjectManager+Pagination.h"
#import "VObjectManager+ContentCreation.h"
#import "VObjectManager+Sequence.h"
#import "VObjectManager+Users.h"
#import "VObjectManager+Login.h"
#import "VComment+Fetcher.h"
#import "VUser+Fetcher.h"
#import "VPaginationManager.h"

// Formatters
#import "NSDate+timeSince.h"
#import "VRTCUserPostedAtFormatter.h"
#import "NSString+VParseHelp.h"
#import "VLargeNumberFormatter.h"

// Media
#import "NSURL+MediaType.h"

// Monetization
#import "VAdBreak.h"
#import "VAdBreakFallback.h"

@interface VContentViewViewModel ()

@property (nonatomic, strong, readwrite) VSequence *sequence;

@property (nonatomic, strong) NSArray *comments;
@property (nonatomic, strong, readwrite) VAsset *currentAsset;
@property (nonatomic, strong, readwrite) VRealtimeCommentsViewModel *realTimeCommentsViewModel;
@property (nonatomic, strong, readwrite) VExperienceEnhancerController *experienceEnhancerController;

@property (nonatomic, strong) NSString *followersText;
@property (nonatomic, strong, readwrite) VHistogramDataSource *histogramDataSource;
@property (nonatomic, assign, readwrite) VVideoCellViewModel *videoViewModel;

@property (nonatomic, strong) NSMutableArray *adChain;
@property (nonatomic, assign, readwrite) NSInteger currentAdChainIndex;
@property (nonatomic, assign, readwrite) VMonetizationPartner monetizationPartner;
@property (nonatomic, assign, readwrite) NSArray *monetizationDetails;

@property (nonatomic, assign) BOOL hasCreatedAdChain;

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
            _realTimeCommentsViewModel = [[VRealtimeCommentsViewModel alloc] init];
        }
        else if ([sequence isImage])
        {
            _type = VContentViewTypeImage;
        }
        else
        {
            // Fall back to image.
            _type = VContentViewTypeImage;
        }
        
        _experienceEnhancerController = [[VExperienceEnhancerController alloc] initWithSequence:sequence];

        _currentNode = [sequence firstNode];
        
        _currentAsset = [_currentNode mp4Asset];
        
        // Set the default ad chain index
        self.currentAdChainIndex = 0;
    }
    return self;
}

- (id)init
{
    NSAssert(false, @"-init is not allowed. Use the designate initializer: \"-initWithSequence:\"");
    return nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)repost
{
    [[VObjectManager sharedManager] repostNode:self.currentNode
                                      withName:nil
                                  successBlock:^(NSOperation *operation, id result, NSArray *resultObjects)
     {
         self.hasReposted = YES;
         self.sequence.repostCount = @(self.sequence.repostCount.integerValue + 1);
     }
                                     failBlock:nil];
}

#pragma mark - Create the ad chain

- (void)createAdChainWithCompletion:(void(^)(void))completionBlock
{
    if (self.hasCreatedAdChain)
    {
        return;
    }
    
    self.adChain = [[NSMutableArray alloc] init];
    NSOrderedSet *adBreakSet = self.sequence.adBreaks;
    
    for (VAdBreak *ad in adBreakSet)
    {
        NSOrderedSet *fallbackSet = ad.fallbacks;
        for (VAdBreakFallback *item in fallbackSet)
        {
            [self.adChain addObject:item];
        }
    }
    
    // Grab the preroll
    VAdBreakFallback *breakItem = [self.adChain objectAtIndex:(long)self.currentAdChainIndex];
    int adSystemPartner = [[breakItem adSystem] intValue];
    self.monetizationPartner = adSystemPartner;
    self.monetizationDetails = self.adChain;
    self.hasCreatedAdChain = YES;
    
    if (completionBlock)
    {
        completionBlock();
    }
}

#pragma mark - Sequence data fetching methods

- (void)fetchSequenceData
{
    [[VObjectManager sharedManager] fetchSequenceByID:self.sequence.remoteId
                                         successBlock:^(NSOperation *operation, id result, NSArray *resultObjects)
     {
        // This is here to update the vote counts
        [self.experienceEnhancerController updateData];
         
        // Sets up the monetization chain
         if (self.sequence.adBreaks.count > 0)
         {
             [self createAdChainWithCompletion:^(void)
              {
                  self.videoViewModel = [VVideoCellViewModel videoCellViewModelWithItemURL:[self videoURL]
                                                                              withAdSystem:self.monetizationPartner
                                                                               withDetails:self.monetizationDetails
                                                                                  withLoop:[self loop]];
                  [self.delegate didUpdateContent];
              }];
         }
         else
         {
             self.videoViewModel = [VVideoCellViewModel videoCellViewModelWithItemURL:[self videoURL]
                                                                         withAdSystem:VMonetizationPartnerNone
                                                                          withDetails:nil
                                                                             withLoop:[self loop]];
             [self.delegate didUpdateContent];

         }
    }
                                            failBlock:nil];
}

- (void)reloadData
{
    [self fetchPollData];
    [self fetchComments];
    [self fetchHistogramData];
    [self fetchUserinfo];
    [self fetchSequenceData];
}

- (void)fetchUserinfo
{
    __weak typeof(self) welf = self;
    [[VObjectManager sharedManager] countOfFollowsForUser:self.user
                                             successBlock:^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
     {
         NSInteger followerCount = [resultObjects[0] integerValue];
         if (followerCount > 0)
         {
             
             welf.followersText =  [NSString stringWithFormat:@"%@ %@", [[VLargeNumberFormatter new] stringForInteger:followerCount], NSLocalizedString(@"followers", @"")];
         }
     }
                                                failBlock:nil];
    if ( [VObjectManager sharedManager].mainUserLoggedIn )
    {
        [[VObjectManager sharedManager] fetchUserInteractionsForSequence:self.sequence
                                                          withCompletion:^(VSequenceUserInteractions *userInteractions, NSError *error)
         {
             self.hasReposted = userInteractions.hasReposted;
         }];
    }
}

- (void)fetchHistogramData
{
    if (![self.sequence isVideo])
    {
        return;
    }

    [[VObjectManager sharedManager] fetchHistogramDataForSequence:self.sequence
                                                        withAsset:self.currentAsset
                                                   withCompletion:^(NSArray *histogramData, NSError *error)
     {
         if (histogramData)
         {
             self.histogramDataSource = [VHistogramDataSource histogramDataSourceWithDataPoints:histogramData];
             [self.delegate didUpdateHistogramData];
         }
     }];
}

- (void)fetchPollData
{
    if (![self.sequence isPoll])
    {
        return;
    }
    
    [[VObjectManager sharedManager] pollResultsForSequence:self.sequence
                                              successBlock:^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
     {
         [self.delegate didUpdatePollsData];
     }
                                                 failBlock:nil];
}

#pragma mark - Property Accessors

- (NSURLRequest *)imageURLRequest
{
    NSURL *imageUrl;
    if (self.type == VContentViewTypeImage)
    {
        imageUrl = [NSURL URLWithString:self.currentAsset.data];
    }
    else
    {
        imageUrl = [NSURL URLWithString:self.sequence.previewImagesObject];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imageUrl];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    return request;
}

/*
- (VAdSystem)adSystem
{
    VAdBreak *adBreak = self.sequence.adBreaks;
    NSNumber *system_type = adBreak.adSystem;
    VAdSystem ad_system = [system_type intValue];
    return ad_system;
}
*/

- (VUser *)user
{
    return self.sequence.user;
}

- (NSString *)name
{
    return self.sequence.name;
}

- (BOOL)shouldShowTitle
{
    BOOL isPollOrnameEmbedded = ([self.sequence.nameEmbeddedInContent boolValue]) || ([self.sequence isPoll]);
    return !isPollOrnameEmbedded;
}

- (NSURL *)videoURL
{
    return [NSURL URLWithString:self.currentAsset.data];
}

- (float)speed
{
    return [self.currentAsset.speed floatValue];
}

- (BOOL)loop
{
    return [self.currentAsset.loop boolValue];
}

- (BOOL)playerControlsDisabled
{
    return [self.currentAsset.playerControlsDisabled boolValue];
}

- (BOOL)audioMuted
{
    return [self.currentAsset.audioMuted boolValue];
}

- (BOOL)shouldShowRealTimeComents
{
    NSArray *realTimeComments = [self.currentAsset.comments array];
    return (realTimeComments.count > 0) ? YES : NO;
}

- (void)setComments:(NSArray *)comments
{
    NSArray *sortedComments = [comments sortedArrayUsingComparator:^NSComparisonResult(VComment *comment1, VComment *comment2)
     {
         return [comment2.postedAt compare:comment1.postedAt];
     }];
    _comments = sortedComments;
}

#pragma mark - Public Methods

- (void)removeCommentAtIndex:(NSUInteger)index
{
    NSMutableArray *updatedComments = [self.comments mutableCopy];
    [updatedComments removeObjectAtIndex:index];
    self.comments = [NSArray arrayWithArray:updatedComments];
    [self.delegate didUpdateCommentsWithPageType:VPageTypeFirst];
}

- (void)addCommentWithText:(NSString *)text
                  mediaURL:(NSURL *)mediaURL
                  realTime:(CMTime)realTime
                completion:(void (^)(BOOL succeeded))completion
{
    Float64 currentTime = CMTimeGetSeconds(self.realTimeCommentsViewModel.currentTime);
    if (isnan(currentTime))
    {
        [[VObjectManager sharedManager] addCommentWithText:text
                                                  mediaURL:mediaURL
                                                toSequence:self.sequence
                                                 andParent:nil
                                              successBlock:^(NSOperation *operation, id result, NSArray *resultObjects)
         {
             if (completion)
             {
                 completion(YES);
             }
         }
                                                 failBlock:^(NSOperation *operation, NSError *error)
         {
             if (completion)
             {
                 completion(NO);
             }
         }];
    }
    else
    {
        [[VObjectManager sharedManager] addRealtimeCommentWithText:text
                                                          mediaURL:mediaURL
                                                           toAsset:self.currentAsset
                                                            atTime:@(CMTimeGetSeconds(realTime))
                                                      successBlock:^(NSOperation *operation, id fullResponse, NSArray *resultObjects)
         {
             if (completion)
             {
                 completion(YES);
             }
         }
                                                         failBlock:^(NSOperation *operation, NSError *error)
         {
             if (completion)
             {
                 completion(NO);
             }
         }];
    }
}

- (void)fetchComments
{
    if ( self.deepLinkCommentId != nil )
    {
        [self loadCommentsWithCommentId:self.deepLinkCommentId];
    }
    else
    {
        [self loadComments:VPageTypeFirst];
    }
}

- (void)loadCommentsWithCommentId:(NSNumber *)commentId
{
    [[VObjectManager sharedManager] findCommentPageOnSequence:self.sequence
                                                withCommentId:self.deepLinkCommentId
                                                 successBlock:^(NSOperation *operation, id result, NSArray *resultObjects)
     {
         self.comments = [self.sequence.comments array];
         [self.delegate didUpdateCommentsWithDeepLink:commentId];
     }
                                                    failBlock:nil];
}

- (void)loadComments:(VPageType)pageType
{
    VAbstractFilter *filter = [[VObjectManager sharedManager] commentsFilterForSequence:self.sequence];
    const BOOL isFilterAlreadyLoading = [[[VObjectManager sharedManager] paginationManager] isLoadingFilter:filter];
    if ( isFilterAlreadyLoading || ![filter canLoadPageType:pageType] )
    {
        return;
    }
    
    [[VObjectManager sharedManager] loadCommentsOnSequence:self.sequence
                                                  pageType:pageType
                                              successBlock:^(NSOperation *operation, id result, NSArray *resultObjects)
     {
         self.comments = [self.sequence.comments array];
         [self.delegate didUpdateCommentsWithPageType:pageType];
     }
                                                 failBlock:nil];
}

- (NSString *)commentTimeAgoTextForCommentIndex:(NSInteger)commentIndex
{
    VComment *commentForIndex = [self.comments objectAtIndex:commentIndex];
    return [commentForIndex.postedAt timeSince];
}

- (VUser *)userForCommentIndex:(NSInteger)commentIndex
{
    VComment *commentForIndex = [self.comments objectAtIndex:commentIndex];
    return commentForIndex.user;
}

- (NSString *)authorName
{
    return self.sequence.user.name;
}

- (BOOL)isCurrentUserOwner
{
    return [self.sequence.user isOwner];
}

- (NSString *)shareText
{
    NSString *shareText;
    
    if ([self isCurrentUserOwner])
    {
        switch (self.type)
        {
            case VContentViewTypePoll:
                shareText = [NSString stringWithFormat:NSLocalizedString(@"OwnerSharePollFormat", nil), self.sequence.user.name];
                break;
            case VContentViewTypeImage:
                shareText = [NSString stringWithFormat:NSLocalizedString(@"OwnerShareImageFormat", nil), self.sequence.user.name];
                break;
            case VContentViewTypeVideo:
                shareText = [NSString stringWithFormat:NSLocalizedString(@"OwnerShareVideoFormat", nil), self.sequence.name, self.sequence.user.name];
                break;
            case VContentViewTypeInvalid:
                break;
        }
    }
    else
    {
        switch (self.type)
        {
            case VContentViewTypePoll:
                shareText = NSLocalizedString(@"UGCSharePollFormat", nil);
                break;
            case VContentViewTypeImage:
                shareText = NSLocalizedString(@"UGCShareImageFormat", nil);
                break;
            case VContentViewTypeVideo:
                shareText = NSLocalizedString(@"UGCShareVideoFormat", nil);
                break;
            case VContentViewTypeInvalid:
                break;
        }
    }
    
    return shareText;
}

- (NSString *)analyticsContentTypeText
{
    return self.sequence.category;
}

- (NSURL *)sourceURLForCurrentAssetData
{
    return [self.currentAsset.data mp4UrlFromM3U8];
}

- (NSURL *)shareURL
{
    return [NSURL URLWithString:self.currentNode.shareUrlPath] ?: nil;
}

- (NSInteger)nodeID
{
    return [self.currentNode.remoteId integerValue];
}

- (NSString *)authorCaption
{
    if (self.followersText)
    {
        return self.followersText;
    }
    return nil;
}

- (NSURL *)avatarForAuthor
{
    return [NSURL URLWithString:self.sequence.user.pictureUrl];
}

- (NSString *)remixCountText
{
    return [NSString stringWithFormat:@"%@", self.sequence.remixCount];
}

- (NSString *)repostCountText
{
    return [NSString stringWithFormat:@"%@", self.sequence.repostCount];
}

- (NSString *)shareCountText
{
    return nil;
}

- (NSURL *)mediaURLForCommentIndex:(NSInteger)commentIndex
{
    VComment *commentForIndex = [self.comments objectAtIndex:commentIndex];
    return [NSURL URLWithString:commentForIndex.mediaUrl];
}

- (VAnswer *)answerA
{
    return ((VAnswer *)[[[self.sequence firstNode] firstAnswers] firstObject]);
}

- (VAnswer *)answerB
{
    return ((VAnswer *)[[[self.sequence firstNode] firstAnswers] lastObject]);
}

- (NSString *)answerALabelText
{
    return [self answerA].label;
}

- (NSString *)answerBLabelText
{
    return [self answerB].label;
}

- (NSURL *)answerAThumbnailMediaURL
{
    return [self answerAIsVideo] ? [NSURL URLWithString:[self answerA].thumbnailUrl] : [NSURL URLWithString:((VAnswer *)[[[self.sequence firstNode] firstAnswers] firstObject]).mediaUrl];
}

- (NSURL *)answerBThumbnailMediaURL
{
    return [self answerBIsVideo] ? [NSURL URLWithString:[self answerB].thumbnailUrl] : [NSURL URLWithString:((VAnswer *)[[[self.sequence firstNode] firstAnswers] lastObject]).mediaUrl];
}

- (BOOL)answerAIsVideo
{
    return [[self answerA].mediaUrl v_hasVideoExtension];
}

- (BOOL)answerBIsVideo
{
    return [[self answerB].mediaUrl v_hasVideoExtension];
}

- (NSURL *)answerAVideoUrl
{
    return [NSURL URLWithString:[self answerA].mediaUrl];
}

- (NSURL *)answerBVideoUrl
{
    return [NSURL URLWithString:[self answerB].mediaUrl];
}

- (BOOL)votingEnabled
{
    for (VPollResult *result in [VObjectManager sharedManager].mainUser.pollResults)
    {
        if ([result.sequenceId isEqualToString:self.sequence.remoteId])
        {
            return NO;
        }
    }
    return YES;
}

- (CGFloat)answerAPercentage
{
    if ([self totalVotes] > 0)
    {
        return (CGFloat) [self answerAResult].count.doubleValue / [self totalVotes];
    }
    return 0.0f;
}

- (CGFloat)answerBPercentage
{
    if ([self totalVotes] > 0)
    {
        return (CGFloat) [self answerBResult].count.doubleValue / [self totalVotes];
    }
    return 0.0f;
}

- (VPollResult *)answerAResult
{
    if ([self answerA].remoteId == nil)
    {
        return nil;
    }
    
    for (VPollResult *result in self.sequence.pollResults.allObjects)
    {
        if ([result.answerId isEqualToNumber:[self answerA].remoteId])
        {
            return result;
        }
    }
    return nil;
}

- (VPollResult *)answerBResult
{
    if ([self answerB].remoteId == nil)
    {
        return nil;
    }
    
    for (VPollResult *result in self.sequence.pollResults.allObjects)
    {
        if ([result.answerId isEqualToNumber:[self answerB].remoteId])
        {
            return result;
        }
    }
    return nil;
}

- (NSInteger)totalVotes
{
    NSInteger totalVotes = 0;
    for (VPollResult *pollResult in self.sequence.pollResults)
    {
        totalVotes = totalVotes + [pollResult.count integerValue];
    }

    return totalVotes;
}

- (void)reloadPollData
{
    [self fetchPollData];
}

- (VPollAnswer)favoredAnswer
{
    for (VPollResult *result in [VObjectManager sharedManager].mainUser.pollResults)
    {
        if ([result.sequenceId isEqualToString:self.sequence.remoteId])
        {
            return [result.answerId isEqualToNumber:[self answerA].remoteId] ? VPollAnswerA : VPollAnswerB;
        }
    }
    return VPollAnswerInvalid;
}

- (void)answerPollWithAnswer:(VPollAnswer)selectedAnswer
                  completion:(void (^)(BOOL succeeded, NSError *error))completion
{
    [[VObjectManager sharedManager] answerPoll:self.sequence
                                    withAnswer:(selectedAnswer == VPollAnswerA) ? [self answerA] : [self answerB]
                                  successBlock:^(NSOperation *operation, id result, NSArray *resultObjects)
     {
         [self.delegate didUpdatePollsData];
         
         completion(YES, nil);
     }
                                     failBlock:^(NSOperation *operation, NSError *error)
     {
         //
         completion(NO, error);
     }];
}

- (NSString *)numberOfVotersText
{
    if (![self.sequence isVoteCountVisible])
    {
        return nil;
    }
    return [NSString stringWithFormat:@"%@ %@", [[[VLargeNumberFormatter alloc] init]stringForInteger:[self totalVotes]], NSLocalizedString(@"Voters", @"")];
}

@end
