//
//  VCropWorkspaceToolViewController.h
//  victorious
//
//  Created by Michael Sena on 12/4/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "VHasManagedDependencies.h"

@interface VCropWorkspaceToolViewController : UIViewController <VHasManagedDependancies>

- (void)setImage:(UIImage *)imageToCrop;

- (UIImage *)croppedImage;

@end
