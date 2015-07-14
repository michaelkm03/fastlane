//
//  VForcedWorkspaceContainerViewController.h
//  victorious
//
//  Created by Cody Kolodziejzyk on 7/10/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VHasManagedDependencies.h"
#import "VLoginFlowControllerDelegate.h"

extern NSString * const kHashtagKey;

@interface VForcedWorkspaceContainerViewController : UIViewController <VHasManagedDependencies, VLoginFlowScreen>

@end
