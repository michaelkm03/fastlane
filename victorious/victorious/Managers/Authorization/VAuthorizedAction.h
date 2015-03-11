//
//  VAuthorizedAction.h
//  victorious
//
//  Created by Patrick Lynch on 3/3/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VAuthorizationViewController.h"
#import "VAuthorizationContextHelper.h"

@class VObjectManager, VDependencyManager;

@interface VAuthorizedAction : NSObject

@property (nonatomic, weak) VObjectManager *objectManager;

- (instancetype)initWithObjectManager:(VObjectManager *)objectManager
                    dependencyManager:(VDependencyManager *)dependencyManager;

- (BOOL)performFromViewController:(UIViewController *)presentingViewController
                                      withContext:(VAuthorizationContext)authorizationContext
                                      withSuccess:(void(^)())successActionBlock;

@end
