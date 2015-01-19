//
//  VWorkspaceViewController.h
//  victorious
//
//  Created by Michael Sena on 12/2/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "VHasManagedDependencies.h"

@class VToolController;

typedef void (^VWorkspaceCompletion)(BOOL finished, UIImage *previewImage, NSURL *renderedMediaURL);

/**
 
 VWorkspaceViewController is the container for all of the major components of editing. It's primary responsibility is to maintain the view hierarchy of three key areas:
 
 The Canvas View -The canvas view is the area where a user can preview their edits to their currently selected item. It has an ImageView which sits inside of a scrollView. The scrollView is used as an artboard and slice tool (the bounds of the scrollview represent the currently selected slice for exporting).
 The inspector View - The inspector view is where tools can add additional UI such as a picker, slider, etc.
 A toolbar - Representing the currently selected top level tool. For images these are: Text, Filters, and crop.
 
 */
@interface VWorkspaceViewController : UIViewController <VHasManagedDependancies>

@property (nonatomic, copy) VWorkspaceCompletion completionBlock; ///< Called upon completion. PreviewImage and RenderedMediaURL will be nil if unsuccessful.

@property (nonatomic, strong) UIImage *previewImage; ///< An image to use while the image while the asset at mediaURL is loading.
@property (nonatomic, strong) NSURL *mediaURL; ///< The image or video to use in this workspace.

@property (nonatomic, readonly) NSURL *renderedMediaURL; ///< The URL of the rendered media

@property (nonatomic, readonly) VToolController *toolController;

@end
