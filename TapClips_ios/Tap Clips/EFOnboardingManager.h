//
//  EFOnboardingManager.h
//  TapClips
//
//  Created by Matthew Fay on 5/16/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFCachedManager.h"

@protocol EFOnboardingManagerDelegate;

@interface EFOnboardingManager : EFCachedManager

- (void)startOnboardingWithDelegate:(id<EFOnboardingManagerDelegate>)delegate;
- (void)clipCreatedWithDuration:(NSNumber *)duration;
//- (void)durationChanged; Removed duration

@end

@protocol EFOnboardingManagerDelegate <NSObject>

@required
- (void)displayCreateClipOnboardingText:(NSString *)text withIcon:(UIImage *)icon andBackgroundColor:(UIColor *)color;
- (void)displayCreateClipSucceededOnboardingText:(NSString *)text withIcon:(UIImage *)icon andBackgroundColor:(UIColor *)color;

//Removed Duration
//- (void)displayChangeDurationOnboardingText:(NSString *)text withIcon:(UIImage *)icon andBackgroundColor:(UIColor *)color;
//- (void)displayChangeDurationSucceededOnboardingText:(NSString *)text withIcon:(UIImage *)icon andBackgroundColor:(UIColor *)color;

@end