//
//  VContentPollQuestionCell.m
//  victorious
//
//  Created by Michael Sena on 10/20/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VContentPollQuestionCell.h"

#import "VThemeManager.h"

@interface VContentPollQuestionCell ()

@property (weak, nonatomic) IBOutlet UILabel *questionLabel;

@end

@implementation VContentPollQuestionCell

+ (CGSize)desiredSizeWithCollectionViewBounds:(CGRect)bounds
{
    return CGSizeMake(CGRectGetWidth(bounds), 90);
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.questionLabel.font = [[VThemeManager sharedThemeManager] themedFontForKey:kVHeading2Font];
}

- (void)setQuestion:(NSString *)question
{
    _question = [question copy];
    self.questionLabel.text = _question;
}

@end