//
//  VMessageSubViewController.m
//  victorious
//
//  Created by Gary Philipp on 1/13/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VMessageContainerViewController.h"
#import "VMessageViewController.h"
#import "VObjectManager.h"
#import "VObjectManager+ContentCreation.h"
#import "VObjectManager+DirectMessaging.h"
#import "VConversation.h"
#import "VUser.h"
#import "NSString+VParseHelp.h"

#import "UIActionSheet+VBlocks.h"

#import "MBProgressHUD.h"

@interface VMessageContainerViewController ()
@end

@implementation VMessageContainerViewController
@synthesize conversationTableViewController = _conversationTableViewController;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    VMessageViewController* messageVC = (VMessageViewController*)self.conversationTableViewController;
    
    self.navigationItem.title = messageVC.conversation.user.name ? [@"@" stringByAppendingString:messageVC.conversation.user.name] : @"Message";
    
    UIBarButtonItem *flagButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"More"]
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(flagConversation:)];
    
    self.navigationItem.rightBarButtonItems =  [@[flagButtonItem] arrayByAddingObjectsFromArray:self.navigationItem.rightBarButtonItems];
}

- (IBAction)flagConversation:(id)sender
{
    NSString *reportTitle = NSLocalizedString(@"Report Inappropriate", @"Comment report inappropriate button");
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button")
                                                       onCancelButton:nil
                                               destructiveButtonTitle:reportTitle
                                                  onDestructiveButton:^(void)
                                  {
                                      [[VObjectManager sharedManager] flagConversation:self.conversation
                                                                      successBlock:^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
                                       {
                                           UIAlertView*    alert   =   [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ReportedTitle", @"")
                                                                                                  message:NSLocalizedString(@"ReportUserMessage", @"")
                                                                                                 delegate:nil
                                                                                        cancelButtonTitle:NSLocalizedString(@"OKButton", @"")
                                                                                        otherButtonTitles:nil];
                                           [alert show];
                                           
                                       }
                                                                         failBlock:^(NSOperation* operation, NSError* error)
                                       {
                                           VLog(@"Failed to flag conversation %@", self.conversation);
                                           
                                           //TODO: we may want to remove this later.
                                           UIAlertView*    alert   =   [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ReportedTitle", @"")
                                                                                                  message:NSLocalizedString(@"ReportUserMessage", @"")
                                                                                                 delegate:nil
                                                                                        cancelButtonTitle:NSLocalizedString(@"OKButton", @"")
                                                                                        otherButtonTitles:nil];
                                           [alert show];
                                       }];
                                  }
                                           otherButtonTitlesAndBlocks:nil];
    
    [actionSheet showInView:self.view];
}

- (void)setConversation:(VConversation *)conversation
{
    _conversation = conversation;
    ((VMessageViewController*)self.conversationTableViewController).conversation = conversation;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //Be sure to delete the conversation if we've come to create a new conversation and stopped
    if (![[self.conversation messages] count])
    {
        NSManagedObjectContext* context =   self.conversation.managedObjectContext;
        [context deleteObject:self.conversation];
        [context saveToPersistentStore:nil];
        
        //Delete the evidence!
        ((VMessageViewController*)self.conversationTableViewController).conversation = nil;
        self.conversation = nil;
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UITableViewController *)conversationTableViewController
{
    if (_conversationTableViewController == nil)
    {
        _conversationTableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"messages"];
    }
    
    return _conversationTableViewController;
}

- (void)keyboardBar:(VKeyboardBarViewController *)keyboardBar didComposeWithText:(NSString *)text mediaURL:(NSURL *)mediaURL
{
    MBProgressHUD*  progressHUD =   [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progressHUD.labelText = NSLocalizedString(@"JustAMoment", @"");
    progressHUD.detailsLabelText = NSLocalizedString(@"PublishUpload", @"");
    
    __block NSNumber* oldID = self.conversation.remoteId;
    
    VSuccessBlock success = ^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
    {
        if (![oldID isEqualToValue:self.conversation.remoteId])
        {
            //If the ID on the conversation changes we need to refresh the fetch controller with the new ID.
            //This happens because we do not have the remote ID for the conversation until the first message is sent
            [((VMessageViewController*)self.conversationTableViewController) refreshFetchController];
        }
        [progressHUD hide:YES];
    };
    
    [[VObjectManager sharedManager] sendMessageToConversation:self.conversation
                                                     withText:text
                                                     mediaURL:mediaURL
                                                 successBlock:success
                                                    failBlock:^(NSOperation* operation, NSError* error)
     {
         VLog(@"Failed in creating message with error: %@", error);
         [progressHUD hide:YES];
         
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UploadError", @"")
                                                         message: NSLocalizedString(@"UploadErrorBody", @"")
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                               otherButtonTitles:nil];
         [alert show];
     }];
}

@end
