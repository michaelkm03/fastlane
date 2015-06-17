//
//  VShareItemCollectionViewCell.h
//  victorious
//
//  Created by Sharif Ahmed on 6/11/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VBaseCollectionViewCell.h"

@class VShareMenuItem;
@class VDependencyManager;

/**
    Describes the state of the cell, providing an easy means of determining when the
    share menu item that it represents has been selected, is authorizing (loading) or is unselected.
 */
typedef NS_ENUM(NSInteger, VShareItemCellState)
{
    VShareItemCellStateSelected,
    VShareItemCellStateLoading,
    VShareItemCellStateUnselected
};

/**
    A cell that represents a share menu item by displaying it's icon in the center.
 */
@interface VShareItemCollectionViewCell : VBaseCollectionViewCell

/**
    Sets up the cell with the provided share menu item and dependency manager, styling the border as appropriate.
    
    @property menuItem The share menu item that this cell should represent.
    @property dependencyManager The dependency manager that will style this cell.
 */
- (void)populateWithShareMenuItem:(VShareMenuItem *)menuItem andDependencyManager:(VDependencyManager *)dependencyManager;

@property (nonatomic, assign) VShareItemCellState state; ///< The current state of this cell.
@property (nonatomic, strong) VDependencyManager *dependencyManager; ///< The dependency manager used to style this cell.
@property (nonatomic, readonly) VShareMenuItem *shareMenuItem; ///< The share menu item that this cell represents.

@end
