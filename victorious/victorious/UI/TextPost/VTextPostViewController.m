//
//  VTextPostViewController.m
//  victorious
//
//  Created by Patrick Lynch on 3/11/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VTextPostViewController.h"
#import "VTextLayoutHelper.h"
#import "VDependencyManager.h"
#import "VTextPostTextView.h"

static const CGFloat kTextLineHeight = 35.0f;
static const CGFloat kVerticalSpacing = 2;
static const CGFloat kLineOffsetMultiplier = 0.4f;
static const CGFloat kHorizontalSpacing = 3;
static const NSUInteger kMaxTextLength = 200;

@interface VTextPostViewController () <UITextViewDelegate>

@property (nonatomic, strong) VDependencyManager *dependencyManager;
@property (nonatomic, strong) IBOutlet VTextLayoutHelper *textLayoutHelper;
@property (nonatomic, weak) IBOutlet VTextPostTextView *textView;
@property (nonatomic, weak) IBOutlet VTextPostTextView *hashtagTextView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *hashtagTextViewLeadingConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *hashtagTextViewTopConstraint;

@end

@implementation VTextPostViewController

+ (instancetype)newWithDependencyManager:(VDependencyManager *)dependencyManager
{
    NSString *nibName = NSStringFromClass([self class]);
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    VTextPostViewController *viewController = [[VTextPostViewController alloc] initWithNibName:nibName bundle:bundle];
    viewController.dependencyManager = dependencyManager;
    return viewController;
}

- (void)startEditingText
{
    [self.textView becomeFirstResponder];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.text = @"";
    self.supplementaryHashtagText = @"";
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.text = @"What's on your mind?";
    self.supplementaryHashtagText = @"#hashtag";
}

- (void)setSupplementaryHashtagText:(NSString *)supplementaryHashtagText
{
    _supplementaryHashtagText = supplementaryHashtagText;
    
    self.hashtagTextView.translatesAutoresizingMaskIntoConstraints = NO;
    
    const BOOL wasSelectable = self.hashtagTextView.selectable;
    self.hashtagTextView.selectable = YES; ///< UITextView's attributedString property cannot be read unless this is set to YES
    
    NSDictionary *attribtues = [self hashtagTextAttributesWithDependencyManager:self.dependencyManager];
    self.hashtagTextView.attributedText = [[NSAttributedString alloc] initWithString:supplementaryHashtagText
                                                                          attributes:attribtues];
    [self.hashtagTextView sizeToFit];
    
    self.hashtagTextView.selectable = wasSelectable;
    
    self.hashtagTextView.hidden = supplementaryHashtagText.length == 0;
    
    [self updateTextBackground];
    [self updateHashtagPostiion];
}

- (void)updateHashtagPostiion
{
    CGRect textLastLineFrame = [self.textView.backgroundFrames.lastObject CGRectValue];
    CGRect hashtagTextFrame = [self.hashtagTextView.backgroundFrames.lastObject CGRectValue];
    
    CGFloat targetLeading = textLastLineFrame.size.width + CGRectGetMinX( self.textView.frame ) + kHorizontalSpacing;
    CGFloat spaceNeededForHashtagText = CGRectGetWidth( self.textView.frame ) - CGRectGetWidth( hashtagTextFrame );
    if ( targetLeading < spaceNeededForHashtagText )
    {
        self.hashtagTextViewTopConstraint.constant = CGRectGetMinY( textLastLineFrame );
        self.hashtagTextViewLeadingConstraint.constant = targetLeading;
    }
    else
    {
        self.hashtagTextViewTopConstraint.constant = CGRectGetMaxY( textLastLineFrame );
        self.hashtagTextViewLeadingConstraint.constant = CGRectGetMinX( self.textView.frame );
    }
    [self.view layoutIfNeeded];
}

- (void)setText:(NSString *)text
{
    _text = text;
    
    NSDictionary *attributes = [self textAttributesWithDependencyManager:self.dependencyManager];
    self.textView.attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributes];
    
    [self updateTextBackground];
    [self updateHashtagPostiion];
}

- (void)updateTextBackground
{
    
    for ( VTextPostTextView *textView in @[ self.textView, self.hashtagTextView] )
    {
        if ( textView.attributedText.string.length == 0 )
        {
            textView.backgroundFrames = @[]; ///< Don't draw any background for empty text
            continue;
        }
        
        textView.backgroundFrameColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3f];
        
        // Use this function of text storange to get the usedRect of each line fragment
        NSRange fullRange = NSMakeRange( 0, textView.attributedText.string.length );
        __block NSMutableArray *lineFragmentRects = [[NSMutableArray alloc] init];
        [textView.layoutManager enumerateLineFragmentsForGlyphRange:fullRange usingBlock:^( CGRect rect,
                                                                                           CGRect usedRect,
                                                                                           NSTextContainer *textContainer,
                                                                                           NSRange glyphRange, BOOL *stop )
         {
             [lineFragmentRects addObject:[NSValue valueWithCGRect:usedRect]];
         }];
        
        // Calculate the actual line count a bit differently, since the one above is not as accurate while typing
        CGRect singleCharRect = [textView boundingRectForCharacterRange:NSMakeRange( 0, 1 )];
        CGRect totalRect = [textView boundingRectForCharacterRange:NSMakeRange( 0, textView.attributedText.string.length)];
        totalRect.size = [textView sizeThatFits:CGSizeMake( textView.bounds.size.width, CGFLOAT_MAX )];
        totalRect.size.width = textView.bounds.size.width;
        
        __block NSMutableArray *backgroundFrames = [[NSMutableArray alloc] init];
        NSInteger numLines = totalRect.size.height / singleCharRect.size.height;
        for ( NSInteger i = 0; i < numLines; i++ )
        {
            // Calculate individual rects for each line to draw in the background of text view
            CGRect lineRect = totalRect;
            lineRect.size.height = singleCharRect.size.height - kVerticalSpacing;
            lineRect.origin.y = singleCharRect.size.height * i + singleCharRect.size.height * kLineOffsetMultiplier;
            if ( i == numLines - 1 )
            {
                // If this is the last line, use the line fragment rects collected above
                lineRect.size.width = ((NSValue *)lineFragmentRects.lastObject).CGRectValue.size.width;
                if ( lineRect.size.width == 0 )
                {
                    // Sometimes the line fragment rect will give is 0 width for a singel word overhanging on the next line
                    // So, we'll take that last word and calcualte its width to get a proper value for the line's background rect
                    NSString *lastWord = [textView.attributedText.string componentsSeparatedByString:@" "].lastObject;
                    NSRange lastWordRange = [textView.attributedText.string rangeOfString:lastWord];
                    CGRect lastWordBoundingRect = [textView boundingRectForCharacterRange:lastWordRange];
                    lineRect.size.width = lastWordBoundingRect.size.width + lastWordBoundingRect.size.height * 0.3;
                }
            }
            [backgroundFrames addObject:[NSValue valueWithCGRect:lineRect]];
        }
        
        textView.backgroundFrames = [NSArray arrayWithArray:backgroundFrames];
    }
}

#pragma mark - Text Attributes

- (NSDictionary *)textAttributesWithDependencyManager:(VDependencyManager *)dependencyManager
{
    return @{ NSFontAttributeName: [dependencyManager fontForKey:@"font.heading2"],
              NSForegroundColorAttributeName: [UIColor cyanColor], //[dependencyManager colorForKey:@"color.text.content"],
              NSParagraphStyleAttributeName: [self paragraphStyle] };
}

- (NSDictionary *)hashtagTextAttributesWithDependencyManager:(VDependencyManager *)dependencyManager
{
    return @{ NSFontAttributeName: [dependencyManager fontForKey:@"font.heading2"],
              NSForegroundColorAttributeName: [dependencyManager colorForKey:@"color.link"],
              NSParagraphStyleAttributeName: [self paragraphStyle] };
}

- (NSParagraphStyle *)paragraphStyle
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.minimumLineHeight = paragraphStyle.maximumLineHeight = kTextLineHeight;
    return paragraphStyle;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    [self updateTextBackground];
    [self updateHashtagPostiion];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ( [text isEqualToString:@"\n"] )
    {
        [textView resignFirstResponder];
        return NO;
    }
    
    return textView.text.length + text.length < kMaxTextLength;
}

@end
