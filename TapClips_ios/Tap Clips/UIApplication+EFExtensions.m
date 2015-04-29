//
//  UIApplication+EFExtensions.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/20/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "UIApplication+EFExtensions.h"
#import "NSDate+EFExtensions.h"

static NSString * const EFUniqueDeviceKey = @"EFUniqueDeviceKey";
static NSString * const EFLaunchDateKey = @"EFLaunchDateKey";
static NSString * const EFForegroundDateKey = @"EFForegroundDateKey";
static NSString * _applicationIdentifier;

@implementation UIApplication (EFExtensions)

+ (NSString *)applicationVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

+ (NSString *)applicationUniqueIdentifier
{
    if (_applicationIdentifier.length == 0) {
        _applicationIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:EFUniqueDeviceKey];
    }
    
    if (_applicationIdentifier.length == 0) {
        _applicationIdentifier = [self createUniqueIdentifier];
        
        [[NSUserDefaults standardUserDefaults] setObject:_applicationIdentifier forKey:EFUniqueDeviceKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return _applicationIdentifier;
}

+ (NSString *)createUniqueIdentifier
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *key = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
    CFRelease(uuid);
    
    return key;
}

+ (NSString *)facebookAppId
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookAppID"];
}

+ (NSString *)bundleSuffix
{
    NSString *bundleSuffix = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"BundleSuffix"];
    return (bundleSuffix.length ? bundleSuffix : @"");
}

//////////////////////////////////////////////////////////////
#pragma mark - User Sessions
//////////////////////////////////////////////////////////////
+ (void)setApplicationForegroundDate:(NSDate *)foregroundDate
{
    NSTimeInterval sec = [foregroundDate timeIntervalSince1970InMS];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%f", sec] forKey:EFForegroundDateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)applicationForegroundDateInSecondsSince1970
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:EFForegroundDateKey];
}

+ (void)setApplicationLaunchDate:(NSDate *)launchDate
{
    NSTimeInterval sec = [launchDate timeIntervalSince1970InMS];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%f", sec] forKey:EFLaunchDateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)applicationLaunchDateInSecondsSince1970
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:EFLaunchDateKey];
}

@end
