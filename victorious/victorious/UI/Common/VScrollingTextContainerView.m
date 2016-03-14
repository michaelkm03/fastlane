//
//  VScrollingTextContainerView.m
//  victorious
//
//  Created by Vincent Ho on 2/2/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

#import "VScrollingTextContainerView.h"
#import "VTimerManager.h"
#import "VLinearGradientView.h"

static CGFloat const kGradientOffset = 20.0f;
static CGFloat const kScrollBoundary = 20.0f;
static CGFloat const kTimerInterval = 0.1f;

@interface VScrollingTextContainerView()

@property (nonatomic, readwrite, strong) UILabel *label;

/*
 * Gradient mask view, which will only be shown when the content needs to be scrolled.
 */
@property (nonatomic, strong) VLinearGradientView *gradientMaskView;

/*
 * ScrollView holding the label
 */
@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) VTimerManager *timer;
@property (nonatomic) BOOL scrollDown;
@property (nonatomic) CGFloat scrollSpeed;

@end

@implementation VScrollingTextContainerView

#pragma mark - Setup

- (void)awakeFromNib
{
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.userInteractionEnabled = NO;
    
    self.label = [[UILabel alloc] init];
    self.label.numberOfLines = 0;
    self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.label.textAlignment = NSTextAlignmentCenter;
    
    [self addSubview:self.scrollView];
    [self.scrollView addSubview:self.label];
}

#pragma mark - Reload Views

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.gradientMaskView.frame = self.bounds;
    self.scrollView.frame = self.bounds;
    
    [self reloadScrollviewSubviews];
}

- (void)reloadScrollviewSubviews
{
    [self stopScroll];
    
    CGRect frame = self.bounds;
    
    CGRect labelFrame = self.label.frame;
    labelFrame.size.height = [self.label sizeThatFits:CGSizeMake(frame.size.width, CGFLOAT_MAX)].height;
    
    /// If the label's height is greater than the max cell height, we add an offset and allow for scrolling
    /// Otherwise, we don't allow for scrolling
    if (self.label.frame.size.height > self.maxHeight)
    {
        labelFrame.origin.y = kGradientOffset;
        self.label.frame = labelFrame;
        
        CGSize contentSize = labelFrame.size;
        contentSize.height += 2*kGradientOffset;
        self.scrollView.contentSize = contentSize;
        
        self.maskView = self.gradientMaskView;
        
        [self startScroll];
    }
    else
    {
        self.scrollView.contentSize = frame.size;
        
        
        CGFloat differenceInHeight = frame.size.height - labelFrame.size.height;
        labelFrame.origin.y = differenceInHeight/2;
        self.label.frame = labelFrame;
        self.maskView = nil;
    }
    
    CGPoint center = self.label.center;
    center.x = self.center.x;
    self.label.center = center;
}

#pragma mark - Timer

- (void)autoscrollTimerFired
{
    if (!self.timer.isValid)
    {
        return;
    }
    CGFloat yOffset = self.scrollView.contentOffset.y;
    if (self.scrollDown)
    {
        yOffset += self.scrollSpeed;
        CGFloat maxOffset = self.scrollView.contentSize.height - self.bounds.size.height + kScrollBoundary;
        if (yOffset > maxOffset)
        {
            yOffset = maxOffset;
            self.scrollDown = NO;
        }
    }
    else
    {
        yOffset -= 3*self.scrollSpeed;
        if (yOffset < -kScrollBoundary)
        {
            yOffset = -kScrollBoundary;
            self.scrollDown = YES;
        }
    }
    [UIView animateWithDuration:kTimerInterval animations:^
    {
        self.scrollView.contentOffset = CGPointMake(0, yOffset);
    }];
    
}

#pragma mark - Auto-scroll controls

- (void)stopScroll
{
    [self.timer invalidate];
}

- (void)startScrollWithScrollSpeed:(CGFloat)speed
{
    self.scrollSpeed = speed * kTimerInterval;
    [self startScroll];
}

- (void)startScroll
{
    if (self.timer)
    {
        [self.timer invalidate];
    }
    if (self.scrollView.contentSize.height > self.maxHeight)
    {
        self.scrollDown = YES;
        self.timer = [VTimerManager addTimerManagerWithTimeInterval:kTimerInterval target:self selector:@selector(autoscrollTimerFired) userInfo:nil repeats:YES toRunLoop:[NSRunLoop mainRunLoop] withRunMode:NSRunLoopCommonModes];
    }
}

#pragma mark - Dealloc

- (void)dealloc
{
    [self.timer invalidate];
}

#pragma mark - Scrollview Attributes

- (void)setText:(NSAttributedString *)text
{
    _text = [text copy];
    self.label.attributedText = text;
}

- (void)setGradient:(CGFloat)gradient direction:(VGradientType)gradientDirection colors:(NSArray <UIColor *> *)colors
{
    self.gradientMaskView = [[VLinearGradientView alloc] initWithFrame:self.bounds];
    [self.gradientMaskView setColors:colors];
    [self.gradientMaskView setLocations:@[@(0.0f), [NSNumber numberWithFloat:gradient], [NSNumber numberWithFloat:1.0-gradient], @(1.0f)]];
    if (gradientDirection == VGradientTypeVertical)
    {
        self.gradientMaskView.startPoint = CGPointMake(0.5f, 0);
        self.gradientMaskView.endPoint = CGPointMake(0.5f, 1);
    }
    else
    {
        self.gradientMaskView.startPoint = CGPointMake(0, 0.5f);
        self.gradientMaskView.endPoint = CGPointMake(1, 0.5f);
    }
    self.maskView = self.gradientMaskView;
    [self reloadScrollviewSubviews];
}

@end