//
//  VModernLoginAndRegistrationFlowViewController.m
//  victorious
//
//  Created by Michael Sena on 5/21/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VModernLoginAndRegistrationFlowViewController.h"

// Dependencies
#import "VDependencyManager.h"

// Responder Chain
#import "VLoginFlowControllerResponder.h"

static NSString *kRegistrationScreens = @"registrationScreens";
static NSString *kLoginScreens = @"loginScreens";

@interface VModernLoginAndRegistrationFlowViewController () <VLoginFlowControllerResponder>

@property (nonatomic, assign) VAuthorizationContext authorizationContext;
@property (nonatomic, strong) VLoginFlowCompletionBlock completionBlock;
@property (nonatomic, strong) VDependencyManager *dependencyManager;

@property (nonatomic, strong) NSArray *registrationScreens;
@property (nonatomic, strong) NSArray *loginScreens;


@end

@implementation VModernLoginAndRegistrationFlowViewController

- (instancetype)initWithDependencyManager:(VDependencyManager *)dependencyManager
{
    self = [super init];
    if (self)
    {
        _dependencyManager = dependencyManager;
        _registrationScreens = [dependencyManager arrayOfValuesOfType:[UIViewController class]
                                                               forKey:kRegistrationScreens];
        _loginScreens = [dependencyManager arrayOfValuesOfType:[UIViewController class]
                                                        forKey:kLoginScreens];
        [self setViewControllers:@[[_registrationScreens firstObject]]];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Setup login
    self.view.backgroundColor = [UIColor lightGrayColor];
}

#pragma mark - VLoginFlowControllerResponder

- (void)cancelLoginAndRegistration
{
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:nil];
}

- (void)selectedLogin
{
    [self pushViewController:[self.loginScreens firstObject]
                    animated:YES];
}

- (void)selectedRegister
{
    [self pushViewController:[self nextScreenAfterCurrentInArray:self.registrationScreens]
                    animated:YES];
}

#pragma mark - Internal Methods

- (UIViewController *)nextScreenAfterCurrentInArray:(NSArray *)array
{
    NSUInteger currentIndex = [array indexOfObject:self.topViewController];
    if ((currentIndex+1) <= array.count)
    {
        return [array objectAtIndex:currentIndex+1];
    }
    return [array objectAtIndex:currentIndex];
}

@end
