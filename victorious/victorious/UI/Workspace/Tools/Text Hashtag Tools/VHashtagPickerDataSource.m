//
//  VHashtagPickerDataSource.m
//  victorious
//
//  Created by Patrick Lynch on 3/16/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VHashtagPickerDataSource.h"
#import "VHashtagOptionCell.h"
#import "VWorkspaceTool.h"
#import "VTextTypeTool.h"
#import "VHashtagOptionTool.h"
#import "VDependencyManager.h"

@interface VHashtagPickerDataSource ()

@property (nonatomic, strong) NSArray *tools;
@property (nonatomic, strong) VDependencyManager *dependencyManager;

@end

@implementation VHashtagPickerDataSource

- (instancetype)initWithDependencyManager:(VDependencyManager *)dependencyManager tools:(NSArray *)tools
{
    self = [super init];
    if (self)
    {
        _tools = tools;
        _dependencyManager = dependencyManager;
    }
    return self;
}

- (void)registerCellsWithCollectionView:(UICollectionView *)collectionView
{
    NSString *identifier = [VHashtagOptionCell suggestedReuseIdentifier];
    NSBundle *bundle = [NSBundle bundleForClass:[VHashtagOptionCell class]];
    [collectionView registerNib:[UINib nibWithNibName:identifier bundle:bundle] forCellWithReuseIdentifier:identifier];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (NSInteger)self.tools.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [VHashtagOptionCell suggestedReuseIdentifier];
    VHashtagOptionCell *hashtagCell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    VHashtagOptionTool *option = (VHashtagOptionTool *)self.tools[ indexPath.row ];
    hashtagCell.font = [self.dependencyManager fontForKey:@"font.button"];
    hashtagCell.title = option.title;
    
    return hashtagCell;
}

@end
