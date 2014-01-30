//
//  VCreateViewController.h
//  victorious
//
//  Created by David Keegan on 1/7/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VCreateSequenceDelegate.h"

#import "VImagePickerViewController.h"
#import "VCreateSequenceDelegate.h"

@interface VCreateViewController : VImagePickerViewController

- (instancetype)initWithType:(VImagePickerViewControllerType)type
                 andDelegate:(id<VCreateSequenceDelegate>)delegate;

@property (weak, nonatomic) IBOutlet UILabel *characterCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *mediaLabel;

@property (weak, nonatomic) IBOutlet UIButton *mediaButton;
@property (weak, nonatomic) IBOutlet UIButton *removeMediaButton;
@property (weak, nonatomic) IBOutlet UIButton *postButton;

@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (weak, nonatomic) IBOutlet UITextView *textView;


@property (weak, nonatomic) id<VCreateSequenceDelegate> delegate;

@end