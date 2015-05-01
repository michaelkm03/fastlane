//
//  VHashTagTextViewTests.m
//  victorious
//
//  Created by Michael Sena on 11/11/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "VAsyncTestHelper.h"

#import "VHashTagTextView.h"
#import "CCHLinkTextViewDelegate.h"

@interface CCHLinkTextView (testingExtensions)

- (void)didTapAtLocation:(CGPoint)location;
- (void)didLongPressAtLocation:(CGPoint)location;

@end

@interface VHashTagTextViewTests : XCTestCase <CCHLinkTextViewDelegate>

@property (nonatomic, strong) VHashTagTextView *textView;

@property (nonatomic, strong) NSString *expectedValue;
@property (nonatomic, strong) NSString *delegateValue;

@end

@implementation VHashTagTextViewTests

- (void)setUp
{
    [super setUp];
    self.textView = [[VHashTagTextView alloc] initWithFrame:CGRectMake(0, 0, 50, 20)];
    self.textView.textAlignment = NSTextAlignmentCenter;
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testFindsTags
{
    NSMutableAttributedString *attributedSimpleString = [[NSMutableAttributedString alloc] initWithString:@"#hashTag"];
    
    self.textView.attributedText = attributedSimpleString;

    __block BOOL appliedLinkAttribute = NO;
    
    [self.textView.attributedText enumerateAttributesInRange:NSMakeRange(0, attributedSimpleString.string.length)
                                                     options:kNilOptions
                                                  usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop)
     {
         NSArray *allKeys = [attrs allKeys];
         NSLog(@"%@", allKeys);
         [allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
         {
             if ([key isEqualToString:CCHLinkAttributeName])
             {
                 appliedLinkAttribute = YES;
             }
         }];
     }];
    XCTAssert(appliedLinkAttribute);
}

- (void)testNoTags
{
    self.textView.attributedText = [[NSMutableAttributedString alloc] initWithString:@"hashTag"];;
    
    __block BOOL appliedLinkAttribute = NO;
    
    [self.textView.attributedText enumerateAttributesInRange:NSMakeRange(0, self.textView.text.length)
                                                     options:kNilOptions
                                                  usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop)
     {
         NSArray *allKeys = [attrs allKeys];
         NSLog(@"%@", allKeys);
         [allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
          {
              if ([key isEqualToString:CCHLinkAttributeName])
              {
                  appliedLinkAttribute = YES;
              }
          }];
     }];
    XCTAssertFalse(appliedLinkAttribute);
}

- (void)testValueOfHashTag
{
    NSString *hashyText = @"#hashy";
    self.textView.attributedText = [[NSAttributedString alloc] initWithString:hashyText];
    [self.textView.attributedText enumerateAttributesInRange:NSMakeRange(0, self.textView.text.length)
                                                     options:kNilOptions
                                                  usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop)
     {
         XCTAssertEqualObjects([attrs valueForKey:CCHLinkAttributeName], @"hashy");
     }];
}

#pragma mark - CCHLinkTextViewDelegate

- (void)linkTextView:(CCHLinkTextView *)linkTextView didTapLinkWithValue:(id)value
{
    self.delegateValue = value;
}

@end
