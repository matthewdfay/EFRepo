//
//  EFLocationManager.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/8/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFLocationManager.h"

static NSString * const EFLastKnownLocationKey = @"lastLocation";

@interface EFLocationManager () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, copy) EFLocationCallbackBlock callbackBlock;
@end

@implementation EFLocationManager

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    return _locationManager;
}

+ (instancetype)sharedManager
{
    static EFLocationManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EFLocationManager alloc] init];
    });
    return manager;
}

- (CLLocation *)lastKnownLocation
{
    return [self.locationManager location];
}

- (void)updateCurrentLocationIfPossible:(EFLocationCallbackBlock)callback
{
    self.callbackBlock = callback;
    
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager setDelegate:self];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        self.locationManager.activityType = CLActivityTypeOther;
        self.locationManager.distanceFilter = 5;
        [self.locationManager startUpdatingLocation];
    } else {
        [self handleFailureWithResponse:@"location services disabled"];
    }
}

- (void)stopUpdatingCurrentLocation
{
    [self.locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (locations.count) {
        [self handleSuccessfulResponseWithLocation:[locations objectAtIndex:0]];
    } else {
        [self handleFailureWithResponse:@"no location returned"];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self handleFailureWithResponse:[error localizedDescription]];
}

//////////////////////////////////////////////////////////////
#pragma mark - Response Handlers
//////////////////////////////////////////////////////////////
- (void)handleSuccessfulResponseWithLocation:(CLLocation *)location
{
    if (self.callbackBlock) {
        self.callbackBlock (YES, location);
        self.callbackBlock = nil;
    }
}

- (void)handleFailureWithResponse:(NSString *)failureResponse
{
    if (self.callbackBlock) {
        self.callbackBlock (NO, failureResponse);
        self.callbackBlock = nil;
    }
}

+ (BOOL)locationServicesHasBeenApproved
{
    return ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized);
}

@end
