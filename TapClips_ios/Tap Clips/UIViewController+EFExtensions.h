//
//  UIViewController+EFExtensions.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/2/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (EFExtensions)

/**
 This removes the passed in view cotroller from its
 parent. (should be self) Then adds the new view
 controller as a child of self.
 */
- (void)replaceViewController:(UIViewController *)controllerToReplace withViewController:(UIViewController *)replacingViewController;

@end
