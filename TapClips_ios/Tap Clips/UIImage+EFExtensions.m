//
//  UIImage+EFExtensions.m
//  TapClips
//
//  Created by Matthew Fay on 6/4/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "UIImage+EFExtensions.h"

@implementation UIImage (EFExtensions)

- (UIImage *)roundedImageWithBorder:(BOOL)border
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [UIScreen mainScreen].scale);
    CGRect imageRect = CGRectMake(0, 0, self.size.width, self.size.height);
    [[UIBezierPath bezierPathWithOvalInRect:imageRect] addClip];
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0, self.size.height);
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), imageRect, self.CGImage);
    
    if (border) {
        UIImage *borderImage = [UIImage imageNamed:@"icon-round-border"];
        CGContextDrawImage(UIGraphicsGetCurrentContext(), imageRect, borderImage.CGImage);
    }
    
    UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return returnImage;
}

@end
