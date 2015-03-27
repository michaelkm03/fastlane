//
//  VHashtagTool.h
//  victorious
//
//  Created by Patrick Lynch on 3/11/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VWorkspaceTool.h"
#import "VToolPicker.h"
#import "VEditTextToolViewController.h"

@interface VHashtagTool : NSObject <VWorkspaceTool>

@property (nonatomic, readonly) UIViewController <VToolPicker> *toolPicker;

@end
