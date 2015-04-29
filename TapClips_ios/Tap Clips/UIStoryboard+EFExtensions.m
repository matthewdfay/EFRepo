//
//  UIStoryboard+EFExtensions.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/26/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "UIStoryboard+EFExtensions.h"

@implementation UIStoryboard (EFExtensions)


+ (UIStoryboard *)mainStoryboard
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    } else {
        return [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    }
}

@end
