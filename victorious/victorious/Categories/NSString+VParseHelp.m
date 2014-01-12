//
//  NSString+VParseHelp.m
//  VictoriOS
//
//  Created by Will Long on 11/18/13.
//  Copyright (c) 2013 Victorious Inc. All rights reserved.
//

#import "NSString+VParseHelp.h"

@implementation NSString (VParseHelp)


- (NSString*)typeByExtension
{
    if ([[self pathExtension] isEqualToString:VConstantMediaExtensionM3U8])
        return VConstantsMediaTypeVideo;
    
    if ([[self pathExtension] isEqualToString:VConstantMediaExtensionM3U8]
        || [[self pathExtension] isEqualToString:VConstantMediaExtensionPNG]
        || [[self pathExtension] isEqualToString:VConstantMediaExtensionJPEG]
        || [[self pathExtension] isEqualToString:VConstantMediaExtensionJPG])
        return VConstantsMediaTypeImage;
    
    return nil;
}

- (NSString*)previewImageURLForM3U8
{
    //    $basename . '/playlist.m3u8';
    //    $basename . '/thumbnail-00001.png';
    return  [[self stringByDeletingLastPathComponent] stringByAppendingString:@"/thumbnail-00001.png"];
}

- (BOOL ) isEmpty
{
    return [self isEmptyWithCleanWhiteSpace:YES];
}

- (BOOL ) isEmptyWithCleanWhiteSpace:(BOOL)cleanWhileSpace
{
    
    if ((NSNull *) self == [NSNull null]) {
        return YES;
    }
    
    if (self == nil) {
        return YES;
    } else if ([self length] == 0) {
        return YES;
    }
    
    if (cleanWhileSpace) {
        NSString* aString = [self stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([aString length] == 0) {
            return YES;
        }
    }
    
    return NO;  
}

@end
