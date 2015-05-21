//
//  VCoachmarkPassthroughContainerView.m
//  victorious
//
//  Created by Sharif Ahmed on 5/20/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VCoachmarkPassthroughContainerView.h"

@interface VCoachmarkPassthroughContainerView ()

@property (nonatomic, readwrite) VCoachmarkView *coachmarkView;

@end

@implementation VCoachmarkPassthroughContainerView

+ (instancetype)coachmarkPassthroughContainerViewWithCoachmarkView:(VCoachmarkView *)coachmarkView frame:(CGRect)frame andDelegate:(id <VCoachmarkPassthroughContainerViewDelegate>)delegate
{
    VCoachmarkPassthroughContainerView *coachmarkPassthroughContainerView = [[VCoachmarkPassthroughContainerView alloc] init];
    coachmarkPassthroughContainerView.coachmarkView = coachmarkView;
    coachmarkPassthroughContainerView.frame = frame;
    coachmarkPassthroughContainerView.delegate = delegate;
    return coachmarkPassthroughContainerView;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *result = [super hitTest:point withEvent:event];
    if ( result == self )
    {
        if ( self.delegate != nil )
        {
            [self.delegate passthroughViewRecievedTouch:self];
        }
        return nil;
    }
    return result;
}

@end
