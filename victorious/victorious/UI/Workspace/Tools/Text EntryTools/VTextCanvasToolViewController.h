//
//  VTextCanvasToolViewController.h
//  victorious
//
//  Created by Patrick Lynch on 3/11/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VHasManagedDependencies.h"

@class VEditableTextPostViewController;

/**
 The canvas area of the workspace for creating text posts.  The working text will be display
 here, and all workspace tool selections will be shown, such as adding hashtags and changing background
 colors or images.  The contents of this view are also used to generate the final product that is
 published, including text and media content as well as snapshot preview images.
 */
@interface VTextCanvasToolViewController : UIViewController <VHasManagedDependencies>

/**
 A view controller that handles the primary text editing functions.
 */
@property (nonatomic, strong, readonly) VEditableTextPostViewController *textPostViewController;

@end