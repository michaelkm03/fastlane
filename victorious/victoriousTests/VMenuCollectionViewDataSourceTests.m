//
//  VMenuCollectionViewDataSourceTests.m
//  victorious
//
//  Created by Josh Hinman on 11/15/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VMenuCollectionViewDataSource.h"
#import "VNavigationMenuItem.h"
#import "VNavigationMenuItemCell.h"

#import <OCMock/OCMock.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

static NSString * const kCellReuseID = @"CellReuseID";
static NSString * const kHeaderReuseID = @"SectionHeaderView";
static NSString * const kFooterReuseID = @"SectionFooterView";

@interface VMockMenuItemCell : UICollectionViewCell <VNavigationMenuItemCell>

@property (nonatomic, strong) VNavigationMenuItem *navigationMenuItem;

@end

@implementation VMockMenuItemCell

@end

@interface VMenuCollectionViewDataSourceTests : XCTestCase

@property (nonatomic, strong) VMenuCollectionViewDataSource *dataSource;
@property (nonatomic, strong) NSArray *menuItemSections;
@property (nonatomic, strong) id collectionViewMock;
@property (nonatomic, strong) VNavigationMenuItem *sectionOneItem;
@property (nonatomic, strong) VNavigationMenuItem *sectionTwoItem;

@end

@implementation VMenuCollectionViewDataSourceTests

- (void)setUp
{
    [super setUp];
    
    id sectionOneVC = [OCMockObject niceMockForClass:[UIViewController class]];
    id sectionTwoVC = [OCMockObject niceMockForClass:[UIViewController class]];
    self.collectionViewMock = [OCMockObject niceMockForClass:[UICollectionView class]];
    
    self.sectionOneItem = [[VNavigationMenuItem alloc] initWithTitle:@"One" icon:nil destination:sectionOneVC];
    self.sectionTwoItem = [[VNavigationMenuItem alloc] initWithTitle:@"Two" icon:nil destination:sectionTwoVC];
    
    self.menuItemSections = @[
        @[
            self.sectionOneItem
        ],
        @[
            self.sectionTwoItem
        ]
    ];

    self.dataSource = [[VMenuCollectionViewDataSource alloc] initWithCellReuseID:kCellReuseID sectionsOfMenuItems:self.menuItemSections];
    self.dataSource.sectionHeaderReuseID = kHeaderReuseID;
    self.dataSource.sectionFooterReuseID = kFooterReuseID;
}

- (void)testMenuItemAtIndexPath
{
    VNavigationMenuItem *expected = self.sectionOneItem;
    VNavigationMenuItem *actual = [self.dataSource menuItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    XCTAssertEqualObjects(expected, actual);
}

- (void)testNumberOfSections
{
    NSInteger expected = 2;
    NSInteger actual = [self.dataSource numberOfSectionsInCollectionView:self.collectionViewMock];
    XCTAssertEqual(expected, actual);
}

- (void)testNumberOfItemsInSection
{
    NSInteger expected = 1;
    NSInteger actual = [self.dataSource collectionView:self.collectionViewMock numberOfItemsInSection:0];
    XCTAssertEqual(expected, actual);
}

- (void)testCell
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [[[self.collectionViewMock stub] andReturn:[[VMockMenuItemCell alloc] init]] dequeueReusableCellWithReuseIdentifier:kCellReuseID forIndexPath:indexPath];
    VMockMenuItemCell *menuItemCell = (VMockMenuItemCell *)[self.dataSource collectionView:self.collectionViewMock cellForItemAtIndexPath:indexPath];
    XCTAssertEqualObjects(menuItemCell.navigationMenuItem, self.menuItemSections[0][0]);
}

- (void)testHeaderView
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    id expected = [OCMockObject niceMockForClass:[UICollectionReusableView class]];
    [[[self.collectionViewMock stub] andReturn:expected] dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kHeaderReuseID forIndexPath:indexPath];
    
    id actual = [self.dataSource collectionView:self.collectionViewMock viewForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
    XCTAssertEqualObjects(expected, actual);
}

- (void)testFooterView
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    id expected = [OCMockObject niceMockForClass:[UICollectionReusableView class]];
    [[[self.collectionViewMock stub] andReturn:expected] dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:kFooterReuseID forIndexPath:indexPath];
    
    id actual = [self.dataSource collectionView:self.collectionViewMock viewForSupplementaryElementOfKind:UICollectionElementKindSectionFooter atIndexPath:indexPath];
    XCTAssertEqualObjects(expected, actual);
}

@end