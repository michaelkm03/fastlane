//
//  VExperienceEnhancerController.h
//  victorious
//
//  Created by Michael Sena on 10/6/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VExperienceEnhancerBar.h"

@class VSequence;

@interface VExperienceEnhancerController : NSObject <VExperienceEnhancerBarDataSource>

+ (instancetype)experienceEnhancerControllerForSequence:(VSequence *)sequence;

@property (nonatomic, strong, readonly) VSequence *sequence;

@property (nonatomic, weak) VExperienceEnhancerBar *enhancerBar;

@end
