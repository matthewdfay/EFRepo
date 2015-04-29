//
//  UIApplication+EFExtensions.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/20/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (EFExtensions)

/**
 returns the current version of the application.
 */
+ (NSString *)applicationVersion;

/**
 returns the unique identifier for the device.
 
 NOTE: This is done using coreFoundation not the depricated uuid
 */
+ (NSString *)applicationUniqueIdentifier;

/**
 Creates a unique string.
 */
+ (NSString *)createUniqueIdentifier;

/**
 Facebook app id from info.plist
 */
+ (NSString *)facebookAppId;

/**
 bundle suffix from info.plist
 */
+ (NSString *)bundleSuffix;

/**
 takes the date given and stores it as the foregrounded date.
 */
+ (void)setApplicationForegroundDate:(NSDate *)foregroundDate;

/**
 returns the foregrounded date as a string containing the
 seconds since 1970.
 */
+ (NSString *)applicationForegroundDateInSecondsSince1970;

/**
 takes the date given and stores it as the launch date.
 */
+ (void)setApplicationLaunchDate:(NSDate *)launchDate;

/**
 returns the launch date as a string containing the
 seconds since 1970.
 */
+ (NSString *)applicationLaunchDateInSecondsSince1970;

@end
