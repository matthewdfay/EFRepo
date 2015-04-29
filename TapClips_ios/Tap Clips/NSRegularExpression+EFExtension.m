//
//  NSRegularExpression+EFExtension.m
//  TapClips
//
//  Created by Matthew Fay on 6/23/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "NSRegularExpression+EFExtension.h"

@implementation NSRegularExpression (EFExtension)

+ (NSRegularExpression *)twitterHandleRegularExpression
{
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"\\@\\S+ " options:NSRegularExpressionCaseInsensitive error:nil];
    });
    return regex;
}

@end
