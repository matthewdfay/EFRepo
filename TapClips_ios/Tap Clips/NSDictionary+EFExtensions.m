//
//  NSDictionary+EFExtensions.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "NSDictionary+EFExtensions.h"

@implementation NSDictionary (EFExtensions)

- (id)objectForKey:(id)aKey defaultValue:(id)defaultValue
{
    id value = [self objectForKey:aKey];
    if (!value || value ==  [NSNull null]) {
        return defaultValue;
    }
    return value;
}

@end
