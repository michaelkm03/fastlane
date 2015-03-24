//
//  VTextTypeTool.m
//  victorious
//
//  Created by Michael Sena on 12/13/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VTextTypeTool.h"
#import "VDependencyManager.h"

static NSString * const kTitleKey = @"title";
static NSString * const kTextToolHorizontalAlignment = @"horizontalAlignment";
static NSString * const kTextToolVerticalAlignment = @"verticalAlignment";
static NSString * const kTextToolStrokeColor = @"strokeColor";
static NSString * const kTextToolStrokeWidth = @"strokeWidth";
static NSString * const kTextToolPlaceholderText = @"placeholderText";
static NSString * const kshouldForceUppercaseKey = @"shouldForceUppercase";

@interface VTextTypeTool ()

@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) NSDictionary *attributes;
@property (nonatomic, strong, readwrite) UIColor *dimmingBackgroundColor;
@property (nonatomic, strong, readwrite) NSString *placeholderText;
@property (nonatomic, assign, readwrite) VTextTypeVerticalAlignment verticalAlignment;
@property (nonatomic, assign, readwrite) BOOL shouldForceUppercase;

@end

@implementation VTextTypeTool

#pragma mark - VHasManagedDependencies

- (instancetype)initWithDependencyManager:(VDependencyManager *)dependencyManager
{
    self = [super init];
    if (self)
    {
        _title = [dependencyManager stringForKey:kTitleKey];
        _attributes = [self textAttributesWithDependencyManager:dependencyManager];
        _verticalAlignment = [self verticalAlignmentWithDependencyManager:dependencyManager];
        _placeholderText = [dependencyManager stringForKey:kTextToolPlaceholderText];
    }
    return self;
}

#pragma mark - Internal Methods

- (NSDictionary *)textAttributesWithDependencyManager:(VDependencyManager *)dependencyManager
{
    NSMutableDictionary *textAttributes = [[NSMutableDictionary alloc] init];
    
    textAttributes[NSParagraphStyleAttributeName] = [self paragraphStyleWithDependencyManager:dependencyManager];
    
    if ([dependencyManager fontForKey:VDependencyManagerParagraphFontKey] != nil)
    {
        textAttributes[NSFontAttributeName] = [dependencyManager fontForKey:VDependencyManagerParagraphFontKey];
    }
    if ([dependencyManager colorForKey:VDependencyManagerMainTextColorKey])
    {
        textAttributes[NSForegroundColorAttributeName] = [dependencyManager colorForKey:VDependencyManagerMainTextColorKey];
    }
    if ([dependencyManager colorForKey:kTextToolStrokeColor])
    {
        textAttributes[NSStrokeColorAttributeName] = [dependencyManager colorForKey:kTextToolStrokeColor];
    }
    if ([dependencyManager numberForKey:kTextToolStrokeWidth])
    {
        textAttributes[NSStrokeWidthAttributeName] = [dependencyManager numberForKey:kTextToolStrokeWidth];
    }
    if ([dependencyManager numberForKey:kshouldForceUppercaseKey])
    {
        self.shouldForceUppercase = [[dependencyManager numberForKey:kshouldForceUppercaseKey] boolValue];
    }
    
    return textAttributes;
}

- (VTextTypeVerticalAlignment)verticalAlignmentWithDependencyManager:(VDependencyManager *)dependencyManager
{
    if ([dependencyManager stringForKey:kTextToolVerticalAlignment] == nil)
    {
        return VTextTypeVerticalAlignmentCenter;
    }
    
    NSString *textToolVerticalAlignment = [dependencyManager stringForKey:kTextToolVerticalAlignment];
    if ([textToolVerticalAlignment isEqualToString:@"bottom"])
    {
        return VTextTypeVerticalAlignmentBottomUp;
    }
    else if ([textToolVerticalAlignment isEqualToString:@"center"])
    {
        return VTextTypeVerticalAlignmentCenter;
    }
    else
    {
        return VTextTypeVerticalAlignmentCenter;
    }
}

- (NSParagraphStyle *)paragraphStyleWithDependencyManager:(VDependencyManager *)dependencyManager
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    NSString *textHorizontalAlignment = [dependencyManager stringForKey:kTextToolHorizontalAlignment];
    if (textHorizontalAlignment != nil)
    {
        if ([textHorizontalAlignment isEqualToString:@"center"])
        {
            paragraphStyle.alignment = NSTextAlignmentCenter;
        }
        else if ([textHorizontalAlignment isEqualToString:@"left"])
        {
            paragraphStyle.alignment = NSTextAlignmentLeft;
        }
        else if ([textHorizontalAlignment isEqualToString:@"right"])
        {
            paragraphStyle.alignment = NSTextAlignmentRight;
        }
    }
    return paragraphStyle;
}

@end
