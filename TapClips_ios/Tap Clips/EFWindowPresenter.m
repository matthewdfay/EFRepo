//
//  EFWindowPresenter.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/11/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFWindowPresenter.h"

static UIWindow *controllerPresentationWindow = nil;

@implementation EFWindowPresenter

+ (void)presentViewControllerInWindow:(UIViewController *)controller
{
    controllerPresentationWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    controllerPresentationWindow.windowLevel = UIWindowLevelStatusBar;
    controllerPresentationWindow.rootViewController = controller;
    controllerPresentationWindow.backgroundColor = [UIColor clearColor];
    [controllerPresentationWindow makeKeyAndVisible];
}

+ (void)presentViewControllerInWindow:(UIViewController *)controller withAnimationBlock:(void (^)(void))animationBlock completion:(void (^)(BOOL finished))completion
{
    controllerPresentationWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    controllerPresentationWindow.windowLevel = UIWindowLevelStatusBar;
    controllerPresentationWindow.rootViewController = controller;
    controllerPresentationWindow.rootViewController.view.alpha = 0.0;
    controllerPresentationWindow.backgroundColor = [UIColor clearColor];
    [controllerPresentationWindow makeKeyAndVisible];
    
    [UIView animateWithDuration:0.5 animations:^{
        controllerPresentationWindow.rootViewController.view.alpha = 1.0;
        if (animationBlock) {
            animationBlock();
        }
    } completion:completion];
}

+ (void)dismissWithAnimationBlock:(void (^)(void))animationBlock completion:(void (^)(BOOL finished))completion
{
    if (controllerPresentationWindow) {
        [UIView animateWithDuration:0.2 animations:^{
            controllerPresentationWindow.rootViewController.view.alpha = 0.0;
            if (animationBlock) {
                animationBlock();
            }
        } completion:^(BOOL finished) {
            if (completion) {
                completion(finished);
            }
            [self dismiss];
        }];
    }
}

+ (void)dismiss
{
    if (controllerPresentationWindow) {
        [controllerPresentationWindow.rootViewController.view endEditing:YES];
         controllerPresentationWindow = nil;
    }
}

@end
