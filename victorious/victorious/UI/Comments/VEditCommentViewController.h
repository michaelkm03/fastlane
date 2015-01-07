//
//  VEditCommentViewController.h
//  victorious
//
//  Created by Patrick Lynch on 12/22/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VComment;

@interface VCommentTextView : UITextView

@end

@protocol VEditCommentViewControllerDelegate <NSObject>

- (void)didFinishEditingComment:(VComment *)comment;

@end

@interface VEditCommentViewController : UIViewController

+ (VEditCommentViewController *)instantiateFromStoryboardWithComment:(VComment *)comment;

@property (weak, nonatomic) IBOutlet UIView *modalContainer;
@property (weak, nonatomic) IBOutlet UIView *backgroundScreen;
@property (weak, nonatomic) IBOutlet UIButton *buttonConfirm;
@property (weak, nonatomic) IBOutlet UIButton *buttonCancel;

@property (strong, nonatomic) id<VEditCommentViewControllerDelegate> delegate;

@end