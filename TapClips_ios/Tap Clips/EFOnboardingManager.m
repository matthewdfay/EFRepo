//
//  EFOnboardingManager.m
//  TapClips
//
//  Created by Matthew Fay on 5/16/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFOnboardingManager.h"
#import "EFExtensions.h"

static NSString * const EFOnboardingStorageClipCreatedKey = @"com.elementalfoundry.tap-clips.onboarding.clip-created";
static NSString * const EFOnboardingStorageDurationChangedKey = @"com.elementalfoundry.tap-clips.onboarding.duration-changed";

@interface EFOnboardingManager ()
@property (nonatomic, assign) BOOL clipCreatedBacking;
@property (nonatomic, strong) NSTimer *onboardingTimer;
@property (nonatomic, strong) id<EFOnboardingManagerDelegate> delegate;
@end

@implementation EFOnboardingManager

- (void)setOnboardingTimer:(NSTimer *)onboardingTimer
{
    if (_onboardingTimer != onboardingTimer) {
        [_onboardingTimer invalidate];
        _onboardingTimer = onboardingTimer;
    }
}

+ (id)sharedManager
{
    static EFOnboardingManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [EFOnboardingManager managerFromDisk];
    });
    return manager;
}

- (void)decodeData:(NSCoder *)aDecoder
{
    _clipCreatedBacking = [aDecoder decodeBoolForKey:EFOnboardingStorageClipCreatedKey];
}

- (void)encodeData:(NSCoder *)aCoder
{
    [aCoder encodeBool:self.clipCreatedBacking forKey:EFOnboardingStorageClipCreatedKey];
}

//////////////////////////////////////////////////////////////
#pragma mark - Onboarding
//////////////////////////////////////////////////////////////
- (BOOL)shouldStartOnboarding
{
    return !(self.clipCreatedBacking);
}

- (void)startOnboardingWithDelegate:(id<EFOnboardingManagerDelegate>)delegate
{
    self.delegate = delegate;
    if ([self shouldStartOnboarding]) {
        self.onboardingTimer = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(onboardingTimerHit) userInfo:nil repeats:NO];
    }
}

- (void)onboardingTimerHit
{
    if (!self.clipCreatedBacking) {
        if (self.delegate) {
            [self.delegate displayCreateClipOnboardingText:@"Tap anywhere to capture a clip" withIcon:[UIImage imageNamed:@"icon-pointer-down"] andBackgroundColor:[UIColor overlayColorWithAlpha:0.7]];
        }
    }
}

- (void)clipCreatedWithDuration:(NSNumber *)duration
{
    if (!self.clipCreatedBacking) {
        self.clipCreatedBacking = YES;
        [EFOnboardingManager writeToDisk];
        if (self.delegate) {
            [self.delegate displayCreateClipSucceededOnboardingText:[NSString stringWithFormat:@"Nice! You just captured the last %@ seconds", duration] withIcon:[UIImage imageNamed:@"icon-success-check"] andBackgroundColor:[UIColor successColorWithAlpha:0.7]];
        }
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Cache
//////////////////////////////////////////////////////////////
+ (NSString *)cacheLocation
{
    return [NSString stringWithFormat:@"onboardingdata%@.dat", [UIApplication bundleSuffix]];
}

@end
