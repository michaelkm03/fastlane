//
//  VPurchaseActionCell.h
//  victorious
//
//  Created by Patrick Lynch on 12/9/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VPurchaseActionCell : UITableViewCell

- (void)setAction:(void(^)(VPurchaseActionCell *))actionCallback;

- (void)setIsActionEnabled:(BOOL)isActionEnabled withTitle:(NSString *)labelTitle;

@end