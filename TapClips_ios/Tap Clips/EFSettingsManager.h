//
//  EFSettingsManager.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/31/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EFCachedManager.h"

extern NSString * const EFSettingsUpdatedNotification;

@interface EFSettingsManager : EFCachedManager

@property (nonatomic, strong, readonly) NSDictionary *typeAhead;

@property (nonatomic, strong, readonly) NSString *postingTeamId;
@property (nonatomic, strong, readonly) NSString *appRatingURL;
@property (nonatomic, strong, readonly) NSString *exploreURL;
@property (nonatomic, strong, readonly) NSString *sprioInstallURL;

@property (nonatomic, strong, readonly) NSNumber *minRecordingSeconds;
@property (nonatomic, strong, readonly) NSNumber *maxRecordingSeconds;
@property (nonatomic, strong, readonly) NSNumber *defaultRecordingSeconds;

- (void)updateSettings;

- (NSString *)replacementStringForKey:(NSString *)replacementKey;

@end
