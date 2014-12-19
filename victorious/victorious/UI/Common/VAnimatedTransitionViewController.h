//
//  VAnimatedTransitionViewController.h
//  victorious
//
//  Created by Patrick Lynch on 12/5/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VAnimatedTransitionViewController <NSObject>

@property (nonatomic, readonly) NSTimeInterval transitionInDuration;

@property (nonatomic, readonly) NSTimeInterval transitionOutDuration;

- (void)prepareForTransitionIn:(UIView *)snapshotOfOriginView;

- (void)performTransitionIn:(NSTimeInterval)duration completion:(void(^)(BOOL))completion;

- (void)prepareForTransitionOut:(UIView *)snapshotOfOriginView;

- (void)performTransitionOut:(NSTimeInterval)duration completion:(void(^)(BOOL))completion;

@optional

- (BOOL)requiresImageViewFromOriginViewController;

@end