//
//  VMediaPreviewViewController.h
//  victorious
//
//  Created by Josh Hinman on 4/9/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^VMediaCaptureCompletion)(BOOL finished, UIImage *capturedImage, NSURL *capturedVideoURL);

/**
 Abstract base class for view controllers 
 that show a preview of captured media.
 */
@interface VMediaPreviewViewController : UIViewController

/**
 A completion block to call when the user has finished previewing media
 */
@property (nonatomic, copy) VMediaCaptureCompletion completionBlock;

@end
