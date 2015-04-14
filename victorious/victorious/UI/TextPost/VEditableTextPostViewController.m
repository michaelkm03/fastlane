//
//  VEditableTextPostViewController.m
//  victorious
//
//  Created by Patrick Lynch on 3/27/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VEditableTextPostViewController.h"
#import "VHashTags.h"
#import "NSArray+VMap.h"
#import "VTextPostViewModel.h"
#import "VDependencyManager.h"
#import "UIView+AutoLayout.h"
#import "VTextPostTextView.h"
#import "VEditableTextPostHashtagHelper.h"
#import "VContentInputAccessoryView.h"

static NSString * const kDefaultTextKey = @"defaultText";
static NSString * const kCharacterLimit = @"characterLimit";
static const CGFloat kAccessoryViewHeight = 44.0f;

@interface VEditableTextPostViewController() <UITextViewDelegate, VContentInputAccessoryViewDelegate>

@property (nonatomic, strong) NSString *placeholderText;
@property (nonatomic, strong) UIButton *overlayButton;

@property (nonatomic, assign) BOOL isShowingPlaceholderText;
@property (nonatomic, assign) NSUInteger characterCountMax;
@property (nonatomic, assign) BOOL hasAppeared;

@property (nonatomic, strong) VEditableTextPostHashtagHelper *hashtagHelper;

@end

@implementation VEditableTextPostViewController

+ (instancetype)newWithDependencyManager:(VDependencyManager *)dependencyManager
{
    NSString *nibName = NSStringFromClass([VTextPostViewController class]);
    NSBundle *bundle = [NSBundle bundleForClass:[VTextPostViewController class]];
    VEditableTextPostViewController *viewController = [[VEditableTextPostViewController alloc] initWithNibName:nibName bundle:bundle];
    viewController.dependencyManager = dependencyManager;
    return viewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.hashtagHelper = [[VEditableTextPostHashtagHelper alloc] init];
    
    self.overlayButton = [[UIButton alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:self.overlayButton atIndex:0];
    [self.view v_addFitToParentConstraintsToSubview:self.overlayButton];
    [self.overlayButton addTarget:self action:@selector(overlayButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    self.placeholderText = [self.dependencyManager stringForKey:kDefaultTextKey];
    self.characterCountMax = [self.dependencyManager numberForKey:kCharacterLimit].integerValue;
    [self showPlaceholderText];
    
    self.textView.userInteractionEnabled = YES;
    self.textView.editable = YES;
    CGRect accessoryFrame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), kAccessoryViewHeight );
    VContentInputAccessoryView *inputAccessoryView = [[VContentInputAccessoryView alloc] initWithFrame:accessoryFrame];
    inputAccessoryView.textInputView = self.textView;
    inputAccessoryView.maxCharacterLength = self.characterCountMax;
    inputAccessoryView.delegate = self;
    inputAccessoryView.tintColor = [self.dependencyManager colorForKey:VDependencyManagerLinkColorKey];
    self.textView.inputAccessoryView = inputAccessoryView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.delegate textDidUpdate:self.textOutput];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ( !self.hasAppeared )
    {
        self.isEditing = YES;
        self.hasAppeared = YES;
    }
    
    self.text = @"asdsa das dsa dsadsa#ddasd sad saA#Dsa dsa da#d sda dsad sa#dsa dsa dsada#dsad3#dadsdsa#dsadasdsa#dsa d asd#dsa dsadsa das#d";
}

- (NSString *)textOutput
{
    return self.isShowingPlaceholderText ? @"" : self.text;
}

- (BOOL)addHashtag:(NSString *)hashtagText
{
    if ( hashtagText.length == 0 )
    {
        return NO;
    }
    
    NSUInteger lengthWithAddedHashtag = self.text.length + hashtagText.length;
    BOOL lengthWillBeWithinMaximum = lengthWithAddedHashtag < self.characterCountMax;;
    if ( !lengthWillBeWithinMaximum )
    {
        return NO;
    }
    
    const BOOL didAdd = [self.hashtagHelper addHashtag:hashtagText];
    if ( didAdd )
    {
        [self addHashtagToText:hashtagText];
    }
    
    return didAdd;
}

- (BOOL)removeHashtag:(NSString *)hashtagText
{
    if ( hashtagText.length == 0 )
    {
        return NO;
    }
    
    const BOOL didRemove = [self.hashtagHelper removeHashtag:hashtagText];
    if ( didRemove && ![self.hashtagHelper.collectedHashtagsRemoved containsObject:hashtagText] )
    {
        [self removeHashtagFromText:hashtagText];
    }
    
    return didRemove;
}

- (void)removeHashtagFromText:(NSString *)hashtag
{
    NSString *hashtagTextWithHashMark = [VHashTags stringWithPrependedHashmarkFromString:hashtag];
    NSRange rangeOfHashtag = [self.text rangeOfString:hashtagTextWithHashMark];
    
    if ( rangeOfHashtag.location != NSNotFound )
    {
        NSString *stringToReplace = hashtagTextWithHashMark;
        NSRange characterAfterHashtagRange = NSMakeRange( rangeOfHashtag.location + rangeOfHashtag.length - 1, 1 );
        NSRange characterBeforeHashtagRange = NSMakeRange( rangeOfHashtag.location - 1, 1 );
        
        if ( rangeOfHashtag.location + rangeOfHashtag.length < self.text.length )
        {
            const BOOL isThereASpaceAfterTheHashtag = [[self.text substringWithRange:characterAfterHashtagRange] isEqualToString:@" "];
            if ( isThereASpaceAfterTheHashtag )
            {
                // Remove the space after the hastag as well
                stringToReplace = [stringToReplace stringByAppendingString:@" "];
                rangeOfHashtag.length++;
            }
        }
        if ( rangeOfHashtag.location > 0 )
        {
            const BOOL isThereASpaceBeforeTheHashtag = [[self.text substringWithRange:characterBeforeHashtagRange] isEqualToString:@" "];
            if ( isThereASpaceBeforeTheHashtag )
            {
                // Remove the space after the hastag as well
                stringToReplace = [NSString stringWithFormat:@" %@", stringToReplace];
                rangeOfHashtag.location--;
                rangeOfHashtag.length++;
            }
        }
        self.text = [self.text stringByReplacingOccurrencesOfString:stringToReplace withString:@""];
    }

    [self showPlaceholderText];
    
    [self.delegate textDidUpdate:self.textOutput];
}

- (void)addHashtagToText:(NSString *)hashtag
{
    [self hidePlaceholderText];
    
    NSString *hashtagTextWithHashMark = [VHashTags stringWithPrependedHashmarkFromString:hashtag];
    if ( ![self.text containsString:hashtagTextWithHashMark] )
    {
        NSRange replacementRange = self.textView.selectedRange;
        
        BOOL isSpaceRequired = NO;
        if ( replacementRange.location > 0 )
        {
            NSRange characterBeforeSelectedRange = NSMakeRange( replacementRange.location-1, 1 );
            isSpaceRequired = ![[self.text substringWithRange:characterBeforeSelectedRange] isEqualToString:@" "];
        }
        
        NSString *stringReplacement = [NSString stringWithFormat:@"%@%@%@", (isSpaceRequired ? @" " : @""), hashtagTextWithHashMark, @" "];
        self.text = [self.text stringByReplacingCharactersInRange:replacementRange withString:stringReplacement];
        NSRange rangeOfAddedString = [self.text rangeOfString:hashtagTextWithHashMark];
        self.textView.selectedRange = NSMakeRange( rangeOfAddedString.location + rangeOfAddedString.length + 1, 0 );
    }
    
    [self.delegate textDidUpdate:self.textOutput];  
}

- (void)setText:(NSString *)text
{
    // This keeps the cursor position the same after adding hashtags in superclass
    NSRange selectedRange = self.textView.selectedRange;
    [super setText:text];
    self.textView.selectedRange = selectedRange;
}

- (BOOL)isLastCharacterASpace:(NSString *)string
{
    if ( string.length == 0 )
    {
        return NO;
    }
    return [[string substringFromIndex:string.length-1] isEqualToString:@" "];
}

- (void)setIsEditing:(BOOL)isEditing
{
    if ( isEditing == _isEditing )
    {
        return;
    }
    _isEditing = isEditing;
    if ( _isEditing )
    {
        [self.textView becomeFirstResponder];
    }
    else
    {
        [self.textView resignFirstResponder];
        
        [self showPlaceholderText];
    }
}

- (void)overlayButtonTapped:(UIButton *)sender
{
    self.isEditing = !self.isEditing;
}

#pragma mark - Placeholder text

- (void)showPlaceholderText
{
    if ( self.text.length == 0 && self.hashtagHelper.embeddedHashtags.count == 0 )
    {
        self.isShowingPlaceholderText = YES;
        self.text = self.placeholderText;
        self.textView.alpha = 0.5f;
        self.textView.selectedRange = NSMakeRange( self.textView.text.length, 0 );
    }
}

- (void)hidePlaceholderText
{
    if ( self.isShowingPlaceholderText )
    {
        self.text = @"";
        self.isShowingPlaceholderText = NO;
        self.textView.alpha = 1.0;
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.isEditing = YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    self.text = self.textView.text;
    
    [self updateAddedAndDeletedHashtags];
    
    [self.delegate textDidUpdate:self.textOutput];
}

- (void)updateAddedAndDeletedHashtags
{
    if ( self.delegate == nil )
    {
        return;
    }
    
    NSString *(^removeHashmarkBlock)(NSString *) = ^NSString *(NSString *string)
    {
        return [string stringByReplacingOccurrencesOfString:@"#" withString:@""];
    };
    
    [self.delegate textPostViewController:self didDeleteHashtags:[self.hashtagHelper.collectedHashtagsRemoved v_map:removeHashmarkBlock]];
    [self.delegate textPostViewController:self didAddHashtags:[self.hashtagHelper.collectedHashtagsAdded v_map:removeHashmarkBlock]];
    [self.delegate textDidUpdate:self.textOutput];
    
    [self.hashtagHelper resetCollectedHashtagEdits];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.isEditing = NO;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ( [text isEqualToString:@"\n"] )
    {
        self.isEditing = NO;
        return NO;
    }
    
    NSString *textAfter = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if ( self.delegate != nil )
    {
        [self.hashtagHelper collectHashtagEditsFromBeforeText:textView.text toAfterText:textAfter];
    }
    
    [self hidePlaceholderText];
    
    return YES; //textAfter.length < self.characterCountMax;
}

#pragma mark - VContentInputAccessoryViewDelegate

- (BOOL)shouldLimitTextEntryForInputAccessoryView:(VContentInputAccessoryView *)inputAccessoryView
{
    return YES;
}

- (BOOL)shouldAddHashTagsForInputAccessoryView:(VContentInputAccessoryView *)inputAccessoryView
{
    return YES;
}

@end
