//
//  EFCachingManager.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/31/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFCachingManager.h"
#import "EFSettingsManager.h"

@implementation EFCachingManager

+ (void)writeCacheToDisk
{
    [EFSettingsManager writeToDisk];
}

+ (void)removeCacheFromDisk
{
    [EFSettingsManager removeFromDisk];
}

@end
