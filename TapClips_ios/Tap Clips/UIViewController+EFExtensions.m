//
//  UIViewController+EFExtensions.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/2/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "UIViewController+EFExtensions.h"

@implementation UIViewController (EFExtensions)

- (void)replaceViewController:(UIViewController *)controllerToReplace withViewController:(UIViewController *)replacingViewController
{
    [self removeViewControllerWithNoTransition:controllerToReplace];
    [self addViewControllerWithNoTransition:replacingViewController];
}

- (void)removeViewControllerWithNoTransition:(UIViewController *)viewController;
{
    if (viewController) {
        [viewController willMoveToParentViewController:nil];
        [viewController beginAppearanceTransition:NO animated:NO];
        if (viewController.isViewLoaded) {
            [viewController.view removeFromSuperview];
        }
        [viewController endAppearanceTransition];
        [viewController removeFromParentViewController];
    }
}

- (void)addViewControllerWithNoTransition:(UIViewController *)viewController
{
    if (viewController) {
        [self addChildViewController:viewController];
        [viewController didMoveToParentViewController:self];
    }
}

@end
