//
//  VStreamsSubViewController.m
//  victoriOS
//
//  Created by Gary Philipp on 12/12/13.
//  Copyright (c) 2013 Victorious, Inc. All rights reserved.
//

#import "VAnalyticsRecorder.h"
#import "VCommentsTableViewController.h"
#import "VCommentTextAndMediaView.h"
#import "VThemeManager.h"
#import "VRTCUserPostedAtFormatter.h"

#import "VLoginViewController.h"
#import "VCommentCell.h"

#import "VObjectManager+Pagination.h"
#import "VObjectManager+Comment.h"
#import "VUser.h"
#import "VUserProfileViewController.h"

#import "UIActionSheet+VBlocks.h"
#import "NSDate+timeSince.h"
#import "NSString+VParseHelp.h"
#import "NSURL+MediaType.h"

#import "VSequence+Fetcher.h"
#import "VNode+Fetcher.h"
#import "VComment+Fetcher.h"
#import "VAsset.h"

#import "UIImageView+Blurring.h"

#import "UIImage+ImageCreation.h"

#import "VNoContentView.h"

@import Social;

@interface VCommentsTableViewController ()

@property (nonatomic, strong) UIImageView* backgroundImageView;
@property (nonatomic, assign) BOOL hasComments;
@property (nonatomic, assign) BOOL needsRefresh;

@end

@implementation VCommentsTableViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:kVCommentCellNibName bundle:nil]
         forCellReuseIdentifier:kVCommentCellNibName];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //This hides the seperators for empty cells
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.needsRefresh = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[VAnalyticsRecorder sharedAnalyticsRecorder] startAppView:@"Comments"];
    [self.tableView reloadData];
    
    if (self.needsRefresh)
    {
        [self.refreshControl beginRefreshing];
        
        [UIView animateWithDuration:0.5f
                              delay:0.0f
             usingSpringWithDamping:0.8f
              initialSpringVelocity:1.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^
        {
            self.tableView.contentOffset = CGPointMake(0, -self.refreshControl.bounds.size.height);
        } completion:nil];
    }
}

#pragma mark - Property Accessors

- (void)setSequence:(VSequence *)sequence
{
    _sequence = sequence;

    [self setHasComments:self.sequence.commentCount.integerValue];
    
    self.title = sequence.name;
    
    [self.tableView reloadData];
    
    if (self.hasComments) //If we don't have comments, try to pull more.
    {
        self.needsRefresh = YES;
        [self refresh:self.refreshControl];
    }
    else
    {
        self.needsRefresh = NO;
    }
}

- (void)setHasComments:(BOOL)hasComments
{
    _hasComments = hasComments;
    if (!hasComments)
    {
        VNoContentView* noCommentsView = [VNoContentView noContentViewWithFrame:self.tableView.frame];
        self.tableView.backgroundView = noCommentsView;
        noCommentsView.titleLabel.text = NSLocalizedString(@"NoCommentsTitle", @"");
        noCommentsView.messageLabel.text = NSLocalizedString(@"NoCommentsMessage", @"");
        noCommentsView.iconImageView.image = [UIImage imageNamed:@"noCommentIcon"];
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    else
    {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = nil;
    }
}

#pragma mark - Public Mehtods

- (void)addedNewComment:(VComment *)comment
{
    [self setHasComments:YES];
    [self.tableView reloadData];
    NSIndexPath* pathForComment = [NSIndexPath indexPathForRow:[self.sequence.comments indexOfObject:comment] inSection:0];
    [self.tableView scrollToRowAtIndexPath:pathForComment atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - IBActions

- (IBAction)refresh:(UIRefreshControl *)sender
{
    RKManagedObjectRequestOperation* operation = [[VObjectManager sharedManager] loadCommentsOnSequence:self.sequence
                                                                                              isRefresh:YES
                                                                                           successBlock:^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
                                                  {
                                                      self.needsRefresh = NO;
                                                      [self.tableView reloadData];
                                                      [self.refreshControl endRefreshing];
                                                  } failBlock:^(NSOperation* operation, NSError* error)
                                                  {
                                                      self.needsRefresh = NO;
                                                      [self.refreshControl endRefreshing];
                                                  }];
    if (!operation)
    {
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - Pagination

- (void)loadNextPageAction
{
    [[VObjectManager sharedManager] loadCommentsOnSequence:self.sequence
                                                 isRefresh:YES
                                              successBlock:^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
     {
         [self.tableView reloadData];
     }
                                                 failBlock:nil];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sequence.comments count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VComment* comment = (VComment *)[self.sequence.comments objectAtIndex:indexPath.row];
    return [VCommentCell estimatedHeightWithWidth:CGRectGetWidth(tableView.bounds) text:comment.text withMedia:comment.hasMedia];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:kVCommentCellNibName forIndexPath:indexPath];
    VComment *comment = [self.sequence.comments objectAtIndex:indexPath.row];
    
    cell.timeLabel.text = [comment.postedAt timeSince];
    if ([comment.sequence.category isEqualToString:@"ugc_image"] ||
        [comment.sequence.category isEqualToString:@"ugc_poll"] ||
        [comment.sequence.category isEqualToString:@"ugc_image_repost"] ||
        [comment.sequence.category isEqualToString:@"ugc_image_secret"] ||
        [comment.sequence.category isEqualToString:@"ugc_image_meme"] ||
        [comment.sequence.category isEqualToString:@"owner_image_secret"] ||
        [comment.sequence.category isEqualToString:@"owner_image"] ||
        [comment.sequence.category isEqualToString:@"owner_image_meme"] ||
        [comment.sequence.category isEqualToString:@"owner_image_repost"] ||
        [comment.sequence.category isEqualToString:@"owner_poll"]
        )
    {
        
        cell.usernameLabel.attributedText = [VRTCUserPostedAtFormatter formatRTCUserName:comment.user.name];
    }
    else
    {
        cell.usernameLabel.attributedText = [VRTCUserPostedAtFormatter formattedRTCUserPostedAtStringWithUserName:comment.user.name
                                                                                      andPostedTime:comment.realtime];
    }
    cell.commentTextView.text = comment.text;
    if (comment.hasMedia)
    {
        cell.commentTextView.hasMedia = YES;
        cell.commentTextView.mediaThumbnailView.hidden = NO;
        [cell.commentTextView.mediaThumbnailView setImageWithURL:comment.previewImageURL];
        if ([comment.mediaUrl isKindOfClass:[NSString class]] && [comment.mediaUrl v_hasVideoExtension])
        {
            cell.commentTextView.onMediaTapped = [cell.commentTextView standardMediaTapHandlerWithMediaURL:[NSURL URLWithString:comment.mediaUrl] presentingViewController:self];
            cell.commentTextView.playIcon.hidden = NO;
        }
    }
    else
    {
        cell.commentTextView.mediaThumbnailView.hidden = YES;
    }
    
    NSURL *pictureURL = [NSURL URLWithString:comment.user.profileImagePathSmall ?: comment.user.pictureUrl];
    if (pictureURL)
    {
        [cell.profileImageView setImageWithURL:pictureURL];
    }
    cell.onProfileImageTapped = ^(void)
    {
        VUserProfileViewController* profileViewController = [VUserProfileViewController userProfileWithUser:comment.user];
        [self.navigationController pushViewController:profileViewController animated:YES];
    };
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y > scrollView.contentSize.height * .75)
    {
        [self loadNextPageAction];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    VComment *comment = [self.sequence.comments objectAtIndex:indexPath.row];
    NSString *reportTitle = NSLocalizedString(@"Report Inappropriate", @"Comment report inappropriate button");
    NSString *reply = NSLocalizedString(@"Reply", @"Comment reply button");
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button")
                                                       onCancelButton:nil
                                               destructiveButtonTitle:reportTitle
                                                  onDestructiveButton:^(void)
    {
        [[VObjectManager sharedManager] flagComment:comment
                                       successBlock:^(NSOperation* operation, id fullResponse, NSArray* resultObjects)
         {
             VLog(@"resultObjects: %@", resultObjects);
             
             UIAlertView*    alert   =   [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ReportedTitle", @"")
                                                                    message:NSLocalizedString(@"ReportCommentMessage", @"")
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OKButton", @"")
                                                          otherButtonTitles:nil];
             [alert show];

         }
                                          failBlock:^(NSOperation* operation, NSError* error)
         {
             VLog(@"Failed to flag comment %@", comment);
            
             UIAlertView*    alert   =   [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WereSorry", @"")
                                                                    message:NSLocalizedString(@"ErrorOccured", @"")
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OKButton", @"")
                                                          otherButtonTitles:nil];
             [alert show];
         }];
    }
                                           otherButtonTitlesAndBlocks:
                                  reply, ^(void)
    {
        [self.delegate streamsCommentsController:self shouldReplyToUser:comment.user];
    },
                                  nil];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    [actionSheet showInView:window];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[VAnalyticsRecorder sharedAnalyticsRecorder] finishAppView];
}

@end