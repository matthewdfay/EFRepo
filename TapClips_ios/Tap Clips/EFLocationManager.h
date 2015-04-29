//
//  EFLocationManager.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/8/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

//If successful, the response is a CLLocation object
//Else, the response is a NSString explaining what failed
typedef void(^EFLocationCallbackBlock)(BOOL wasSuccessful, id response);

@interface EFLocationManager : NSObject

+ (instancetype)sharedManager;

/**
 Returns YES if location services has already been approved for this app.
 */
+ (BOOL)locationServicesHasBeenApproved;

/**
 Returns the last know location.
 If no location returns nil;
 */
- (CLLocation *)lastKnownLocation;

/**
 Calls back with the current location if sucessful.
 Otherwise an error message is returned.
 */
- (void)updateCurrentLocationIfPossible:(EFLocationCallbackBlock)callback;
- (void)stopUpdatingCurrentLocation;

@end
