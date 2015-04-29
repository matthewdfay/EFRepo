//
//  UIColor+EFExtensions.m
//  TapClips
//
//  Created by Matthew Fay on 5/19/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "UIColor+EFExtensions.h"

@implementation UIColor (EFExtensions)

+ (UIColor *)successColor
{
    return [self successColorWithAlpha:1.0];
}

+ (UIColor *)successColorWithAlpha:(CGFloat)alpha
{
    return [UIColor colorWithRed:0.0 green:171/255.0 blue:93/255.0 alpha:alpha];
}

+ (UIColor *)overlayColor
{
    return [self overlayColorWithAlpha:1.0];
}

+ (UIColor *)overlayColorWithAlpha:(CGFloat)alpha
{
    return [UIColor colorWithWhite:0.0 alpha:alpha];
}

@end
