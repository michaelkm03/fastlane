//
//  VDependencyManager.h
//  victorious
//
//  Created by Josh Hinman on 10/31/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Keys for colors
extern NSString * const VDependencyManagerBackgroundColorKey;
extern NSString * const VDependencyManagerSecondaryBackgroundColorKey;
extern NSString * const VDependencyManagerMainTextColorKey;
extern NSString * const VDependencyManagerContentTextColorKey;
extern NSString * const VDependencyManagerAccentColorKey;
extern NSString * const VDependencyManagerSecondaryAccentColorKey;
extern NSString * const VDependencyManagerLinkColorKey;
extern NSString * const VDependencyManagerSecondaryLinkColorKey;

// Keys for fonts
extern NSString * const VDependencyManagerHeaderFontKey;
extern NSString * const VDependencyManagerHeading1FontKey;
extern NSString * const VDependencyManagerHeading2FontKey;
extern NSString * const VDependencyManagerHeading3FontKey;
extern NSString * const VDependencyManagerHeading4FontKey;
extern NSString * const VDependencyManagerParagraphFontKey;
extern NSString * const VDependencyManagerLabel1FontKey;
extern NSString * const VDependencyManagerLabel2FontKey;
extern NSString * const VDependencyManagerLabel3FontKey;
extern NSString * const VDependencyManagerLabel4FontKey;
extern NSString * const VDependencyManagerButton1FontKey;
extern NSString * const VDependencyManagerButton2FontKey;

// Keys for experiments (these should be retrieved with -numberForKey:, as a bool wrapped in an NSNumber)
extern NSString * const VDependencyManagerHistogramEnabledKey;
extern NSString * const VDependencyManagerProfileImageRequiredKey;

// Keys for view controllers
extern NSString * const VDependencyManagerScaffoldViewControllerKey; ///< The "scaffold" is the view controller that sits at the root of the view controller heirarchy

/**
 Provides loose coupling between components.
 Acts as both repository of shared objects
 and a factory of new objects.
 */
@interface VDependencyManager : NSObject

/**
 Creates the root of the dependency manager.
 
 @param parentManager The next dependency manager up in the hierarchy
 @param configuration A dictionary that graphs the dependencies between objects returned by this manager
 @param classesByTemplatename A [string:string] dictionary where the keys are names
                              that may appear in template files, and the values are
                              class names. If nil, it will be read from TemplateClasses.plist.
 */
- (instancetype)initWithParentManager:(VDependencyManager *)parentManager
                        configuration:(NSDictionary *)configuration
    dictionaryOfClassesByTemplateName:(NSDictionary *)classesByTemplateName NS_DESIGNATED_INITIALIZER;

/**
 Returns the color with the specified key
 */
- (UIColor *)colorForKey:(NSString *)key;

/**
 Returns the font with the specified key
 */
- (UIFont *)fontForKey:(NSString *)key;

/**
 Returns the string with the specified key
 */
- (NSString *)stringForKey:(NSString *)key;

/**
 Returns the NSNumber with the specified key
 */
- (NSNumber *)numberForKey:(NSString *)key;

/**
 Returns a new instance of a view controller with the specified key
 */
- (UIViewController *)viewControllerForKey:(NSString *)key;

/**
 Returns the NSArray with the specified key. If the array
 elements contain configuration dictionaries for dependant
 objects, those configuration dictionaries can be passed
 into -objectFromDictionary to instantiate a new object.
 */
- (NSArray *)arrayForKey:(NSString *)key;

/**
 Returns a new object defined by the given configuration dictionary
 */
- (NSObject *)objectFromDictionary:(NSDictionary *)configurationDictionary;

@end
