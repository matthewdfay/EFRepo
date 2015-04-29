//
//  UIAlertView+EFExtensions.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "UIAlertView+EFExtensions.h"

@implementation UIAlertView (EFExtensions)

+ (void)showNotImplementedAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry this feature in not implemented yet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

+ (void)showAlertWithError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

+ (void)showAlertWithMessage:(NSString *)message
{
    if (message && [message isKindOfClass:[NSString class]]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

@end
