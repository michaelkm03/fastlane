//
//  VTemplateImageMacro.h
//  victorious
//
//  Created by Josh Hinman on 6/22/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 An image macro is a set of related images, e.g. the frames in an animated sequence.
 The macro URL starts with a format like this: http://www.example.com/heart_XXXXX.png. 
 Then the individual image URLs are generated by replacing the "XXXXX" portion at the
 end with numbers, e.g. 00001, 00002, etc.
 
 For more information, see the "Image Set" data type in the template specification.
 */
@interface VTemplateImageMacro : NSObject

@property (nonatomic, readonly) NSArray *images; ///< An array of VTemplateImage objects created from the JSON passed into the initWithJSON: method

/**
 Initializes a new instance of VTemplateImageMacro
 with a snippet of JSON from a template.
 */
- (instancetype)initWithJSON:(NSDictionary *)imageMacroJSON NS_DESIGNATED_INITIALIZER;

/**
 Returns YES for an input that looks like an image
 macro. Does not guarantee that the input is 100%
 valid, only that it contains a key that suggests
 it is an image macro and not some other template
 data type.
 
 Returns NO for JSON objects that don't appear to
 be image macros.
 */
+ (BOOL)isImageMacroJSON:(NSDictionary *)imageMacroJSON;

/**
 Returns a set of NSURL objects representing
 all the imageURLs in this image macro.
 */
- (NSSet *)allImageURLs;

@end

NS_ASSUME_NONNULL_END
