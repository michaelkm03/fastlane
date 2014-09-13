//
//  VObjectManager.h
//  victorious
//
//  Created by Will Long on 1/16/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "RKObjectManager.h"

@class VPaginationManager, VUser;

/*! Block that executes when the request succeeds.*/
typedef void (^VSuccessBlock) (NSOperation *operation, id result, NSArray *resultObjects);
/*! Block that executes when the request fails.*/
typedef void (^VFailBlock) (NSOperation *operation, NSError *error);

@interface VObjectManager : RKObjectManager

@property (nonatomic, readonly) VUser              *mainUser;
@property (nonatomic, readonly) VPaginationManager *paginationManager; ///< The pagination manager for the receiver

+ (void)setupObjectManager;

@end