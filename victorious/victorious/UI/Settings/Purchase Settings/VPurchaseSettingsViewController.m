//
//  VPurchaseSettingsViewController.m
//  victorious
//
//  Created by Patrick Lynch on 12/8/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VPurchaseSettingsViewController.h"
#import "UIViewController+VNavMenu.h"
#import "VPurchaseManager.h"
#import "VPurchaseCell.h"
#import "VPurchaseActionCell.h"
#import "VFileCache.h"
#import "VFileCache+VVoteType.h"
#import "VSettingManager.h"
#import "VAlertController.h"
#import "VNoContentTableViewCell.h"
#import "VPurchaseStringMaker.h"

typedef NS_ENUM( NSInteger, VPurchaseSettingsTableViewSections )
{
    VPurchaseSettingsTableViewSectionPurchases,
    VPurchaseSettingsTableViewSectionActions,
    VPurchaseSettingsTableViewSectionCount
};

typedef NS_ENUM( NSInteger, VPurchaseSettingsAction )
{
    VPurchaseSettingsActionRestore,
#ifndef V_NO_RESET_PURCHASES
    VPurchaseSettingsActionReset,
#endif
    VPurchaseSettingsActionCount
};

static const CGFloat kNoPurchasesCelRowlHeight      = 85.0f;
static const CGFloat kActionCellRowHeight           = 60.0f;
static const CGFloat kPurchasedItemCellRowHeight    = 60.0f;

@interface VPurchaseSettingsViewController()

@property (nonatomic, readonly) NSString *purchaseActionCellTitle;
@property (nonatomic, strong) VFileCache *fileCache;
@property (nonatomic, strong) VPurchaseManager *purchaseManager;
@property (nonatomic, assign) BOOL isRestoringPurchases;
@property (strong, nonatomic) VPurchaseStringMaker *stringMaker;

@end

@implementation VPurchaseSettingsViewController

#pragma mark - View controller life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.stringMaker = [[VPurchaseStringMaker alloc] init];
    self.fileCache = [[VFileCache alloc] init];
    self.purchaseManager = [VPurchaseManager sharedInstance];
    
    self.parentViewController.title = NSLocalizedString( @"SettingsPurchasesTitle", nil);
    
    [VNoContentTableViewCell registerNibWithTableView:self.tableView];
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    
    [self.parentViewController v_addNewNavHeaderWithTitles:nil];
    self.parentViewController.navHeaderView.delegate = (UIViewController<VNavigationHeaderDelegate> *)self.parentViewController;
}

#pragma mark - Helpers

- (void)restorePurchases
{
    if ( self.purchaseManager.isPurchaseRequestActive )
    {
        NSString *title = NSLocalizedString( @"RestorePurchasesErrorTitle", nil );
        NSError *error = [NSError errorWithDomain:@"" code:-1 userInfo:nil];
        [self showError:error withTitle:title];
        return;
    }
    
    self.isRestoringPurchases = YES;
    [self.tableView reloadData];
    
    [self.purchaseManager restorePurchasesSuccess:^(NSSet *restoreProductIdentifiers)
     {
         self.isRestoringPurchases = NO;
         
         if ( restoreProductIdentifiers.count == 0 )
         {
             [self showAlertWithTitle:[self.stringMaker localizedSuccessTitleWithProductsCount:0]
                              message:[self.stringMaker localizedSuccessMessageWithProductsCount:0]];
             [self.tableView reloadData];
         }
         else
         {
             NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:VPurchaseSettingsTableViewSectionPurchases];
             [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
             
             NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:VPurchaseSettingsTableViewSectionActions];
             VPurchaseActionCell *cell = (VPurchaseActionCell *)[self.tableView cellForRowAtIndexPath:indexPath];
             [cell setIsActionEnabled:!self.isRestoringPurchases withTitle:self.purchaseActionCellTitle];
         }
     }
                                          failure:^(NSError *error)
     {
         NSString *title = NSLocalizedString( @"RestorePurchasesErrorTitle", nil );
         [self showError:error withTitle:title];
         self.isRestoringPurchases = NO;
         [self.tableView reloadData];
     }];
}

- (void)showError:(NSError *)error withTitle:(NSString *)title
{
    NSString *message = error.localizedDescription;
    [self showAlertWithTitle:title message:message];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    VAlertController *alertConroller = [VAlertController alertWithTitle:title message:message];
    [alertConroller addAction:[VAlertAction cancelButtonWithTitle:NSLocalizedString( @"OKButton", nil ) handler:nil]];
    [alertConroller presentInViewController:self animated:YES completion:nil];
}

- (NSString *)purchaseActionCellTitle
{
    if ( self.isRestoringPurchases )
    {
        return NSLocalizedString( @"ActivityRestoring", nil);
    }
    else
    {
        return NSLocalizedString( @"SettingsRestorePurchases", nil);
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.section == VPurchaseSettingsTableViewSectionPurchases )
    {
        if ( self.purchaseManager.purchasedProductIdentifiers.count > 0 )
        {
            NSString *identifier = NSStringFromClass( [VPurchaseCell class] );
            VPurchaseCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
            NSString *productIdentifier = [self.purchaseManager.purchasedProductIdentifiers.allObjects objectAtIndex:indexPath.row];
            VProduct *product = [self.purchaseManager purchaseableProductForProductIdentifier:productIdentifier];
            VVoteType *voteType = [[VSettingManager sharedManager].voteSettings voteTypeWithProductIdentifier:productIdentifier];
            UIImage *image = [self.fileCache getImageWithName:VVoteTypeIconName forVoteType:voteType];
            [cell setProductImage:image withTitle:product.localizedTitle];
            return cell;
        }
        else
        {
            VNoContentTableViewCell *cell = [VNoContentTableViewCell createCellFromTableView:tableView];
            cell.isCentered = YES;
            [cell setMessage:NSLocalizedString( @"SettingsRestorePurchasesPrompt", nil)];
            return cell;
        }
    }
    else if ( indexPath.section == VPurchaseSettingsTableViewSectionActions )
    {
        NSString *identifier = NSStringFromClass( [VPurchaseActionCell class] );
        VPurchaseActionCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        [cell setIsActionEnabled:!self.isRestoringPurchases withTitle:self.purchaseActionCellTitle];
        if ( indexPath.row == VPurchaseSettingsActionRestore )
        {
            [cell setAction:^(VPurchaseActionCell *actionCell)
             {
                 [self restorePurchases];
             }];
        }
#ifndef V_NO_RESET_PURCHASES
        else if ( indexPath.row == VPurchaseSettingsActionReset )
        {
            NSString *title = @"Reset Purchases";
            [cell setIsActionEnabled:YES withTitle:title];
            [cell setAction:^(VPurchaseActionCell *actionCell)
             {
                 [self.purchaseManager resetPurchases];
                 NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:VPurchaseSettingsTableViewSectionPurchases];
                 [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
             }];
        }
#endif
        return cell;
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ( section == VPurchaseSettingsTableViewSectionPurchases )
    {
        return MAX( self.purchaseManager.purchasedProductIdentifiers.count, (NSUInteger)1 );
    }
    else if ( section == VPurchaseSettingsTableViewSectionActions )
    {
        return VPurchaseSettingsActionCount;
    }
    
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return VPurchaseSettingsTableViewSectionCount;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isNoPurchasesCell = indexPath.section == VPurchaseSettingsTableViewSectionPurchases
                                && self.purchaseManager.purchasedProductIdentifiers.count == 0;
    
    BOOL isActionCell = indexPath.section == VPurchaseSettingsTableViewSectionActions;
    
    if ( isNoPurchasesCell )
    {
        return kNoPurchasesCelRowlHeight;
    }
    else if ( isActionCell )
    {
        return kActionCellRowHeight;
    }
    else
    {
        return kPurchasedItemCellRowHeight;
    }
}

@end