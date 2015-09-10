//
//  VSelectorViewBase.h
//  victorious
//
//  Created by Josh Hinman on 12/16/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#include "VHasManagedDependencies.h"

#import <UIKit/UIKit.h>

@class VSelectorViewBase;

@protocol VSelectorViewDelegate <NSObject>

@optional

/**
 Notifies the delegate that a view controller has been selected.
 This should not be called when the view controller is changed
 by programatically setting the activeViewControllerIndex 
 property.
 
 @param index The index of the selected view controller in the sender's viewControllers array
 */
- (void)viewSelector:(VSelectorViewBase *)viewSelector didSelectViewControllerAtIndex:(NSUInteger)index;

@end

/**
 Base class for a view that offers the user a
 chance to select from multiple views 
 (e.g. a tab bar)
 */
@interface VSelectorViewBase : UIView <VHasManagedDependencies>

@property (nonatomic, strong) NSArray *arrayOfBadgeNumbers; ///< Array containing all the badge numbers corresponding to the selectors
@property (nonatomic, readonly) VDependencyManager *dependencyManager;
@property (nonatomic, weak) id<VSelectorViewDelegate> delegate; ///< A delegate object to be notified when the selection changes
@property (nonatomic, copy) NSArray /* UIViewController */ *viewControllers; ///< The views from which we are selecting
@property (nonatomic) NSUInteger activeViewControllerIndex; ///< The index of the currently selected view controller in the viewControllers array
@property (nonatomic, readonly) UIColor *foregroundColor; ///< The foreground color of the selector

- (instancetype)initWithDependencyManager:(VDependencyManager *)dependencyManager NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/**
 Returns the frame of a button at the provided index.
 This method must be overridden by subclasses of this class.

 @param index The index of the button whose frame should be returned.
 
 @return The frame of the button at the provided index.
 */
- (CGRect)frameOfButtonAtIndex:(NSUInteger)index;

- (void)updateSelectorTitle;

@end