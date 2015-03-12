//
//  VTextColorTool.m
//  victorious
//
//  Created by Patrick Lynch on 3/11/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VTextColorTool.h"
#import "VDependencyManager.h"
#import "VEditTextToolViewController.h"

static NSString * const kTitleKey = @"title";
static NSString * const kIconKey = @"icon";
static NSString * const kIconSelectedKey = @"iconSelected";
static NSString * const kImageURLKey = @"imageURL";

@interface VTextColorTool ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *icon;
@property (nonatomic, strong) UIImage *iconSelected;
@property (nonatomic, strong) VEditTextToolViewController *canvasToolViewController;

@end

@implementation VTextColorTool

#pragma mark - VHasManagedDependancies

- (instancetype)initWithDependencyManager:(VDependencyManager *)dependencyManager
{
    self = [super init];
    if (self)
    {
        _title = [dependencyManager stringForKey:kTitleKey];
        _icon = [UIImage imageNamed:[dependencyManager templateValueOfType:[NSDictionary class] forKey:kIconKey][kImageURLKey]];
        _iconSelected = [UIImage imageNamed:[dependencyManager templateValueOfType:[NSDictionary class] forKey:kIconSelectedKey][kImageURLKey]];
        _canvasToolViewController = [VEditTextToolViewController newWithDependencyManager:dependencyManager];
    }
    return self;
}

@end
