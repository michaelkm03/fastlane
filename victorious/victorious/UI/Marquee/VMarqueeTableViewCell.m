//
//  VMarqueeTableViewCell.m
//  victorious
//
//  Created by Will Long on 9/25/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VMarqueeTableViewCell.h"

#import "VMarqueeViewController.h"
#import "VUserProfileViewController.h"

#import "VStreamItem.h"
#import "VUser.h"

@interface VMarqueeTableViewCell() <VMarqueeDelegate>

@property (nonatomic, strong) VMarqueeViewController *marquee;

@end

@implementation VMarqueeTableViewCell

- (void)awakeFromNib
{
    // Initialization code
    self.marquee = [[VMarqueeViewController alloc] init];
    self.marquee.view.bounds = self.bounds;
    self.marquee.delegate = self;
    [self addSubview:self.marquee.view];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (VStreamItem *)currentItem
{
    return self.marquee.currentStreamItem;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.marquee.autoScrollTimer invalidate];
}

- (void)restartAutoScroll
{
    [self.marquee scheduleAutoScrollTimer];
}

#pragma mark - VMarqueeDelegate

- (void)marquee:(VMarqueeViewController *)marquee selectedItem:(VStreamItem *)streamItem atIndexPath:(NSIndexPath *)path
{
    [self.delegate marqueTableCell:self selectedItem:streamItem];
}

- (void)marquee:(VMarqueeViewController *)marquee selectedUser:(VUser *)user atIndexPath:(NSIndexPath *)path
{
    [self.delegate marqueTableCell:self selectedUser:user];
}

#pragma mark - VSharedCollectionReusableViewMethods

+ (NSString *)suggestedReuseIdentifier
{
    return NSStringFromClass([self class]);
}

+ (UINib *)nibForCell
{
    return [UINib nibWithNibName:NSStringFromClass([self class])
                          bundle:nil];
}

+ (CGSize)desiredSizeWithCollectionViewBounds:(CGRect)bounds
{
    return [VMarqueeViewController desiredSizeWithCollectionViewBounds:bounds];
}

@end
