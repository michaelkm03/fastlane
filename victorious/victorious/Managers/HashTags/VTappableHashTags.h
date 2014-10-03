//
//  VTappableHashTags.h
//  victorious
//
//  Created by Patrick Lynch on 10/2/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VTappableHashTagsDelegate <NSObject>

@required
- (NSTextStorage *)textStorage;
- (NSLayoutManager *)layoutManager;
- (NSTextContainer *)textContainer;

@optional
- (void)hashTag:(NSString *)hashTag tappedInTextView:(UITextView *)textView;

@end

/**
 A class that facilitates tappable hash tags in a UITextView that displays an attributed string.
 */
@interface VTappableHashTags : NSObject

/**
 Creates and returns a UITextView instance that is configured to work with ther hash tag tapping routines in this class.
 Also adds a tap gesture recognizer and handles all input until a hashtag is detect and the delegate's main method is called.
 */
- (UITextView *)createTappableTextViewWithFrame:(CGRect)frame;

/**
 Configures an existing UITextView instance to work with ther hash tag tapping routines in this class.
 Also adds a tap gesture recognizer and handles all input until a hashtag is detect and the delegate's main method is called.
 */
-(void) configureTappableTextView:(UITextView *)textView withFrame:(CGRect)frame;

/**
 Use this method to set the delegate.  There are some specific requirements for this delegate
 that go beyond simply conforming to a protocol, so make sure to check the return value and
 read the error message if something's not working/
 */
- (BOOL)setDelegate:(id<VTappableHashTagsDelegate>)delegate error:(NSError**)error;

@end
