//
//  UIAlertView+EFExtensions.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (EFExtensions)

+ (void)showNotImplementedAlert;
+ (void)showAlertWithMessage:(NSString *)message;
+ (void)showAlertWithError:(NSError *)error;

@end
