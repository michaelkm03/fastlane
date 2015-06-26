//
//  VShareItemCollectionViewCell.m
//  victorious
//
//  Created by Sharif Ahmed on 6/11/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VShareItemCollectionViewCell.h"
#import "VShareMenuItem.h"
#import "VButton.h"
#import "VDependencyManager.h"

@interface VShareItemCollectionViewCell ()

@property (nonatomic, weak) IBOutlet VButton *button;
@property (nonatomic, readwrite) VShareMenuItem *shareMenuItem;

@end

@implementation VShareItemCollectionViewCell

#pragma mark - Cell setup methods

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.button.layer.borderWidth = 1.0f;
}

- (void)populateWithShareMenuItem:(VShareMenuItem *)menuItem andBackgroundColor:(UIColor *)backgroundColor
{
    self.shareMenuItem = menuItem;
    self.backgroundColor = backgroundColor;
    self.state = VShareItemCellStateUnselected;
    [self.button setImage:[menuItem.unselectedIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.button setImage:[menuItem.selectedIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
    self.button.activityIndicatorTintColor = menuItem.unselectedColor;
}

#pragma mark - Setters

- (void)setState:(VShareItemCellState)state
{
    _state = state;
    
    // Update state of button
    if ( state == VShareItemCellStateLoading )
    {
        [self.button showActivityIndicator];
    }
    else
    {
        [self.button hideActivityIndicator];
        BOOL isSelected = state == VShareItemCellStateSelected;
        self.button.selected = isSelected;
    }
    [self updateButtonAppearance];
}

- (void)updateToBackgroundColor:(UIColor *)backgroundColor
{
    self.backgroundColor = backgroundColor;
    [self updateButtonAppearance];
}

#pragma mark - Private methods

- (void)updateButtonAppearance
{
    if ( self.state == VShareItemCellStateSelected )
    {
        UIColor *tintColor = self.shareMenuItem.selectedColor;
        self.button.tintColor = self.backgroundColor;
        self.button.backgroundColor = tintColor;
        self.button.layer.borderColor = tintColor.CGColor;
    }
    else
    {
        UIColor *tintColor = self.shareMenuItem.unselectedColor;
        self.button.tintColor = tintColor;
        self.button.backgroundColor = self.backgroundColor;
        self.button.layer.borderColor = tintColor.CGColor;
    }
}

@end