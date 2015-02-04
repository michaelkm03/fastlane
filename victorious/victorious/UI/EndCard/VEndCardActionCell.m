//
//  VEndCardActionCell.m
//  AutoplayNext
//
//  Created by Patrick Lynch on 1/23/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VEndCardActionCell.h"

static const CGFloat kScaleInactive     = 0.8f;
static const CGFloat kScaleActive       = 1.0f;
static const CGFloat kScaleScaledUp     = 1.2f;
static const CGFloat kDisabledAlpha     = 0.5f;

@interface VEndCardActionCell ()

@property (weak, nonatomic) IBOutlet UILabel *actionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) NSString *successImageName;
@property (strong, nonatomic) NSString *textLabelSuccess;
@property (nonatomic, readwrite) NSString *actionIdentifier;

@end

@implementation VEndCardActionCell

+ (NSString *)cellIdentifier
{
    return NSStringFromClass( [self class] );
}

+ (CGSize)minimumSize
{
    return CGSizeMake( 68.0f, 95.0f );
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.enabled = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.enabled = YES;
}

- (void)setTitleAlpha:(CGFloat)alpha
{
    self.actionLabel.alpha = alpha;
}

- (void)setModel:(VEndCardActionModel *)model
{
    self.actionLabel.text = model.textLabel;
    self.textLabelSuccess = model.textLabelSuccess;
    self.iconImageView.image = [UIImage imageNamed:model.iconImageName];
    self.successImageName = model.successImageName;
    self.actionIdentifier = model.identifier;
}

- (void)setFont:(UIFont *)font
{
    if ( font != nil )
    {
        self.actionLabel.font = font;
    }
}

- (void)setSelected:(BOOL)selected
{
    if ( self.enabled )
    {
        return;
    }
    
    [super setSelected:selected];
}

- (void)showSuccess
{
    if ( self.successImageName != nil )
    {
        self.iconImageView.image = [UIImage imageNamed:self.successImageName];
    }
    
    if ( self.textLabelSuccess != nil )
    {
        self.actionLabel.text = self.textLabelSuccess;
    }
    
    [self playActionCompleteAnimation];
}

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    
    self.containerView.alpha = enabled ? 1.0f : kDisabledAlpha;
}

- (void)playActionCompleteAnimation
{
    [UIView animateWithDuration:0.15f
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0.8f
                        options:kNilOptions animations:^
     {
         CGFloat scale = kScaleScaledUp;
         self.transform = CGAffineTransformMakeScale( scale, scale );
     }
                     completion:^(BOOL finished)
     {
         [UIView animateWithDuration:0.5f
                               delay:0.0f
              usingSpringWithDamping:0.8f
               initialSpringVelocity:0.9f
                             options:kNilOptions animations:^
          {
              self.transform = CGAffineTransformMakeScale( kScaleActive, kScaleActive );
          }
                          completion:nil];
     }];
}

- (void)transitionInWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay
{
    CGFloat scale = 0.8f;
    self.alpha = 0.0f;
    self.transform = CGAffineTransformMakeScale( scale, scale );
    
    [UIView animateWithDuration:duration
                          delay:delay
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.8
                        options:kNilOptions animations:^
     {
         CGFloat scale = kScaleScaledUp;
         self.alpha = 1.0f;
         self.transform = CGAffineTransformMakeScale( scale, scale );
     }
                     completion:^(BOOL finished)
     {
         [UIView animateWithDuration:0.5f
                               delay:0.0f
              usingSpringWithDamping:0.8
               initialSpringVelocity:0.0
                             options:kNilOptions animations:^
          {
              self.alpha = 1.0f;
              self.transform = CGAffineTransformMakeScale( kScaleActive, kScaleActive );
          }
                          completion:nil];
     }];
}

- (void)transitionOutWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay completion:(void(^)(BOOL finished))completion
{
    [UIView animateWithDuration:duration
                          delay:delay
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.8
                        options:kNilOptions animations:^
     {
         self.alpha = 0.0f;
         self.transform = CGAffineTransformMakeScale( kScaleInactive, kScaleInactive );
     }
                     completion:completion];
}

@end
