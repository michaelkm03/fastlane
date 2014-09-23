//
//  VDropdownTitleView.h
//  victorious
//
//  Created by Michael Sena on 9/9/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VBaseSupplementaryView.h"

/**
 *  A title view for content view that should exist below the content view (in z index).
 */
@interface VDropdownTitleView : VBaseSupplementaryView

@property (nonatomic, strong) NSString *titleText;

@property (weak, nonatomic, readonly) IBOutlet UILabel *label;

@end
