//
//  VContentInputAccessoryView.h
//  victorious
//
//  Created by Josh Hinman on 5/29/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VContentInputAccessoryView;

@protocol VContentInputAccessoryViewDelegate <NSObject>

@optional
- (void)hashTagButtonTappedOnInputAccessoryView:(VContentInputAccessoryView *)inputAccessoryView;
- (BOOL)shouldLimitTextEntryForInputAccessoryView:(VContentInputAccessoryView *)inputAccessoryView;
- (BOOL)shouldAddHashTagsForInputAccessoryView:(VContentInputAccessoryView *)inputAccessoryView;

@end

/**
 A toolbar that displays a character count and a hashtag button.
 */
@interface VContentInputAccessoryView : UIView

@property (nonatomic, weak)           id<UITextInput>  textInputView; ///< The text input view for which the receiver is an input accessory.
@property (nonatomic, weak, readonly) UIBarButtonItem *hashtagButton; ///< Pressing this button inserts a hashtag into the textInputView
@property (nonatomic)                 NSUInteger       maxCharacterLength; ///<The max length for the text input
@property (nonatomic, weak)           id<VContentInputAccessoryViewDelegate> delegate; ///< The delegate of the inputAccessoryView

@end