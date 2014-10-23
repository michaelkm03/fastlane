//
//  VFileCache+VVoteTypeTests.m
//  victorious
//
//  Created by Patrick Lynch on 10/14/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VFileCache.h"
#import "VFileCache+VVoteType.h"
#import "VAsyncTestHelper.h"
#import "VFileSystemTestHelpers.h"
#import "VDummyModels.h"
#import "VVoteType+Fetcher.h"

@interface VFileCache ( UnitTest)

- (NSString *)savePathForVoteTypeSprite:(VVoteType *)voteType atFrameIndex:(NSUInteger)index;
- (NSString *)savePathForImage:(NSString *)imageName forVote:(VVoteType *)voteType;
- (NSArray *)savePathsForVoteTypeSprites:(VVoteType *)voteType;
- (BOOL)validateVoteType:(VVoteType *)voteType;

@end

static NSString * const kTestImageUrl = @"https://www.google.com/images/srpr/logo11w.png";

@interface VoteTypeTests : XCTestCase

@property (nonatomic, strong) VFileCache *fileCache;
@property (nonatomic, strong) VAsyncTestHelper *asyncHelper;
@property (nonatomic, strong) VVoteType *voteType;

@end

@implementation VoteTypeTests

- (void)setUp
{
    [super setUp];
    
    self.asyncHelper = [[VAsyncTestHelper alloc] init];
    self.fileCache = [[VFileCache alloc] init];
    
    self.voteType = [VDummyModels objectWithEntityName:@"VoteType" subclass:[VVoteType class]];
    [self resetVoteType];
    
    NSString *directoryPath = [NSString stringWithFormat:VVoteTypeFilepathFormat, self.voteType.name];
    [VFileSystemTestHelpers deleteCachesDirectory:directoryPath];
}

- (void)tearDown
{
    [super tearDown];
    
    self.voteType = nil;
    
    self.fileCache = nil;
}

- (void)resetVoteType
{
    self.voteType.name = @"vote_type_test_name";
    self.voteType.iconImage = kTestImageUrl;
    self.voteType.imageFormat = @"http://media-dev-public.s3-website-us-west-1.amazonaws.com/_static/ballistics/7/images/firework_XXXXX.png";
    self.voteType.imageCount = @( 10 );
}

- (void)testSavePathConstructionIcon
{
    NSString *savePath;
    NSString *expectedSavePath;
    
    savePath = [self.fileCache savePathForImage:VVoteTypeIconName forVote:self.voteType];
    expectedSavePath = [[NSString stringWithFormat:VVoteTypeFilepathFormat, self.voteType.name] stringByAppendingPathComponent:VVoteTypeIconName];
    XCTAssertEqualObjects( expectedSavePath, savePath );
}

- (void)testSpriteSavePathConstruction
{
    for ( NSUInteger i = 0; i < 20; i++ )
    {
        NSString *spriteSavePath = [self.fileCache savePathForVoteTypeSprite:self.voteType atFrameIndex:i];
        NSString *spriteName = [NSString stringWithFormat:VVoteTypeSpriteNameFormat, i];
        NSString *expectedSavePath = [[NSString stringWithFormat:VVoteTypeFilepathFormat, self.voteType.name] stringByAppendingPathComponent:spriteName];
        XCTAssertEqualObjects( expectedSavePath, spriteSavePath );
    }
}

- (void)testSpriteSavePathConstructionArray
{
    NSArray *savePaths = [self.fileCache savePathsForVoteTypeSprites:self.voteType];
    
    [savePaths enumerateObjectsUsingBlock:^(NSString *savePath, NSUInteger i, BOOL *stop) {
        NSString *spriteName = [NSString stringWithFormat:VVoteTypeSpriteNameFormat, i];
        NSString *expectedSavePath = [[NSString stringWithFormat:VVoteTypeFilepathFormat, self.voteType.name] stringByAppendingPathComponent:spriteName];
        XCTAssertEqualObjects( expectedSavePath, savePath );
    }];
}

- (void)testCacheVoteTypeImages
{
    [self.fileCache cacheImagesForVoteType:self.voteType];
    
    [self.asyncHelper waitForSignal:10.0f withSignalBlock:^BOOL{
        
        NSString *iconPath = [self.fileCache savePathForImage:VVoteTypeIconName forVote:self.voteType];
        BOOL iconExists = [VFileSystemTestHelpers fileExistsInCachesDirectoryWithLocalPath:iconPath];
        
        // Make sure the sprite image swere saved
        __block BOOL spritesExist = YES;
        NSArray *images = self.voteType.images;
        [images enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *spritePath = [self.fileCache savePathForVoteTypeSprite:self.voteType atFrameIndex:idx];
            if ( ![VFileSystemTestHelpers fileExistsInCachesDirectoryWithLocalPath:spritePath] )
            {
                spritesExist = NO;
                *stop = YES;
            }
        }];
        
        return iconExists && spritesExist;
    }];
}

- (void)testCacheImagesInvalid
{
    XCTAssertFalse( [self.fileCache cacheImagesForVoteType:nil] );
}

- (void)testLoadFiles
{
    // Run this test again to save theimages
    [self testCacheVoteTypeImages];
    
    UIImage *image = [self.fileCache getImageWithName:VVoteTypeIconName forVoteType:self.voteType];
    XCTAssertNotNil( image );
    XCTAssertNotNil( [[UIImageView alloc] initWithImage:image] );
    
    NSArray *spriteImages = [self.fileCache getSpriteImagesForVoteType:self.voteType];
    XCTAssertEqual( spriteImages.count, self.voteType.images.count );
    [spriteImages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        XCTAssert( [obj isKindOfClass:[UIImage class]] );
        UIImage *image = (UIImage *)obj;
        XCTAssertNotNil( image );
        XCTAssertNotNil( [[UIImageView alloc] initWithImage:image] );
    }];
}

- (void)testFilesDoNotExist
{
    // Dont load files first
    XCTAssertFalse( [self.fileCache isImageCached:VVoteTypeIconName forVoteType:self.voteType] );
    XCTAssertFalse( [self.fileCache areSpriteImagesCachedForVoteType:self.voteType] );
}

- (void)testFilesExist
{
    // Run this test again to save theimages
    [self testCacheVoteTypeImages];
    
    XCTAssert( [self.fileCache isImageCached:VVoteTypeIconName forVoteType:self.voteType] );
    XCTAssert( [self.fileCache areSpriteImagesCachedForVoteType:self.voteType] );
}

@end
