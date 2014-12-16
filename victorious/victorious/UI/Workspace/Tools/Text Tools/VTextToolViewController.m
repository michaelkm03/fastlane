//
//  VTextToolViewController.h
//  victorious
//
//  Created by Michael Sena on 12/4/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VTextToolViewController.h"

static const CGFloat kTextRenderingSize = 1024;

@interface VTextToolViewController () <UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UITextView *placeholderTextView;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, strong) IBOutletCollection(UITextView) NSArray *textViews;

@property (nonatomic, strong) NSArray *centerVerticalAlignmentConstraints;
@property (nonatomic, strong) NSArray *bottomVerticalAlignmentConstraints;

@property (nonatomic, strong) dispatch_queue_t searialTextRenderingQueue;

@property (nonatomic, strong, readwrite) UIImage *renderedImage;

@end

@implementation VTextToolViewController

+ (instancetype)textToolViewController
{
    UIStoryboard *workspaceStoryboard = [UIStoryboard storyboardWithName:@"Workspace"
                                                                  bundle:nil];
    return [workspaceStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
}

#pragma mark - UIViewController
#pragma mark Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.searialTextRenderingQueue = dispatch_queue_create("com.victorious.textToolRenderingQueue", DISPATCH_QUEUE_SERIAL);

    [self updateTextAttributesForTextType:self.textType];
    
    [self.textViews enumerateObjectsUsingBlock:^(UITextView *textView, NSUInteger idx, BOOL *stop)
    {
        textView.textContainerInset = UIEdgeInsetsZero;
        textView.scrollEnabled = NO;
    }];
    
    UITapGestureRecognizer *tapToEditGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(startEditing:)];
    [self.view addGestureRecognizer:tapToEditGesture];
}

#pragma mark - Property Accessors

- (void)setTextType:(VTextTypeTool *)textType
{
    if (_textType == textType)
    {
        return;
    }
    
    [self updateTextAttributesForTextType:textType];
    if (_textType.verticalAlignment != textType.verticalAlignment)
    {
        [self updateTextViewConstraintsForTextType:textType];
    }
    [self.view layoutIfNeeded];
    
    _textType = textType;
}

- (UIImage *)renderedImage
{
    if (_renderedImage != nil)
    {
        return _renderedImage;
    }
    
    dispatch_sync(self.searialTextRenderingQueue, ^
    {
        // Wait for render to complete
    });
    
    return _renderedImage;
}

#pragma mark - Target/Action

- (void)startEditing:(UITapGestureRecognizer *)tapGesture
{
    [self.textView becomeFirstResponder];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView
shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    _renderedImage = nil;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.placeholderTextView.hidden = YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.placeholderTextView.hidden = (textView.text.length > 0) ? YES : NO;
    
    dispatch_async(self.searialTextRenderingQueue, ^
    {
        CGFloat scaleFactor = kTextRenderingSize / CGRectGetWidth(self.view.bounds);
        CGRect scaledRect = CGRectMake(0,
                                       0,
                                       CGRectGetWidth(self.view.bounds) * scaleFactor,
                                       CGRectGetHeight(self.view.bounds) * scaleFactor);
        UIGraphicsBeginImageContextWithOptions(scaledRect.size, NO, scaleFactor);
        CGContextRef context = UIGraphicsGetCurrentContext();
        __block UIImage *renderedImage;
        CGContextSaveGState(context);
        {
            CGContextScaleCTM(context, scaleFactor, scaleFactor);
            [self.textView.attributedText drawWithRect:self.textView.frame
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
            renderedImage = UIGraphicsGetImageFromCurrentImageContext();
        }
        CGContextRestoreGState(context);
        UIGraphicsEndImageContext();
        
        self.renderedImage = renderedImage;
    });
}

#pragma mark - Private Methods

- (void)updateTextAttributesForTextType:(VTextTypeTool *)textType
{
    [self.textViews enumerateObjectsUsingBlock:^(UITextView *textView, NSUInteger idx, BOOL *stop)
    {
        textView.attributedText = [[NSAttributedString alloc] initWithString:textView.text
                                                                  attributes:textType.attributes];
        textView.typingAttributes = textType.attributes;
    }];
}

- (void)updateTextViewConstraintsForTextType:(VTextTypeTool *)textType
{
    [self.centerVerticalAlignmentConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop)
     {
         [self.view removeConstraint:constraint];
     }];
    [self.bottomVerticalAlignmentConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop)
     {
         [self.view removeConstraint:constraint];
     }];
    
    NSMutableArray *centerConstraints = [[NSMutableArray alloc] init];
    NSMutableArray *bottomConstraints = [[NSMutableArray alloc] init];
    
    [self.textViews enumerateObjectsUsingBlock:^(UITextView *textView, NSUInteger idx, BOOL *stop)
     {
         NSDictionary *viewMap = NSDictionaryOfVariableBindings(textView);
         
         switch (textType.verticalAlignment)
         {
             case VTextTypeVerticalAlignmentCenter:
             {
                 [centerConstraints addObject:[NSLayoutConstraint constraintWithItem:textView
                                                                           attribute:NSLayoutAttributeCenterY
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.view
                                                                           attribute:NSLayoutAttributeCenterY
                                                                          multiplier:1.0f
                                                                            constant:0.0f]];
                 [centerConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[textView]-|"
                                                                                                options:kNilOptions
                                                                                                metrics:nil
                                                                                                  views:viewMap]];
                 [self.view addConstraints:centerConstraints];
                 self.centerVerticalAlignmentConstraints = centerConstraints;
             }
                 break;
             case VTextTypeVerticalAlignmentBottomUp:
             {
                 NSLayoutConstraint *constraintToTop = [NSLayoutConstraint constraintWithItem:textView
                                                                                    attribute:NSLayoutAttributeTop
                                                                                    relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                                       toItem:self.view
                                                                                    attribute:NSLayoutAttributeTop
                                                                                   multiplier:1.0f
                                                                                     constant:0.0f];
                 [bottomConstraints addObject:constraintToTop];
                 [bottomConstraints addObject:[NSLayoutConstraint constraintWithItem:textView
                                                                           attribute:NSLayoutAttributeBottom
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.view
                                                                           attribute:NSLayoutAttributeBottom
                                                                          multiplier:1.0f
                                                                            constant:0.0f]];
                 [bottomConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[textView]-|"
                                                                                                options:kNilOptions
                                                                                                metrics:nil
                                                                                                  views:viewMap]];
                 [self.view addConstraints:bottomConstraints];
                 self.bottomVerticalAlignmentConstraints = bottomConstraints;
             }
                 break;
         }
     }];
}

@end
