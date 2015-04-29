//
//  EFWindowPresenter.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/11/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EFWindowPresenter : NSObject

+ (void)presentViewControllerInWindow:(UIViewController *)controller;
+ (void)dismiss;

+ (void)presentViewControllerInWindow:(UIViewController *)controller withAnimationBlock:(void (^)(void))animationBlock completion:(void (^)(BOOL finished))completion;
+ (void)dismissWithAnimationBlock:(void (^)(void))animationBlock completion:(void (^)(BOOL finished))completion;

@end
