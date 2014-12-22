//
//  VSwipeTableViewCell.m
//  SwipeCell
//
//  Created by Patrick Lynch on 12/18/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VSwipeTableViewCell.h"

@implementation VSwipeTableViewCell 

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupSwipeView];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self setupSwipeView];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.swipeViewController reset];
}

- (void)setupSwipeView
{
    if ( self.swipeViewController != nil )
    {
        return;
    }
    
    self.clipsToBounds = NO;
    
    self.swipeViewController = [[VSwipeViewController alloc] initWithFrame:self.bounds];
    [self.contentView addSubview:self.swipeViewController.view];
    [self.contentView sendSubviewToBack:self.swipeViewController.view];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if ( !self.clipsToBounds && !self.hidden && self.alpha > 0 )
    {
        CGPoint subPoint = [self.swipeViewController.utilityButtonsContainer convertPoint:point fromView:self];
        UIView *result = [self.swipeViewController.utilityButtonsContainer hitTest:subPoint withEvent:event];
        if ( result != nil )
        {
            return result;
        }
    }
    
    return [super hitTest:point withEvent:event];
}

@end
