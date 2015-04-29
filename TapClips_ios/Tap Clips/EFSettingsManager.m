//
//  EFSettingsManager.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/31/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFSettingsManager.h"
#import "EFAPIClient.h"
#import "Flurry.h"
#import "EFExtensions.h"

NSString * const EFSettingsUpdatedNotification = @"EFSettingsUpdated";

static NSString * const EFSettingsStorageTypeAheadKey = @"com.elementalfoundry.tap-clips.settings.type-ahead";
static NSString * const EFSettingsStoragePostingTeamIdKey = @"com.elementalfoundry.tap-clips.settings.posting-team-id";
static NSString * const EFSettingsStorageAppRatingURLKey = @"com.elementalfoundry.tap-clips.settings.app-rating-url";
static NSString * const EFSettingsStorageExploreURLKey = @"com.elementalfoundry.tap-clips.settings.explore-url";
static NSString * const EFSettingsStorageSprioInstallURLKey = @"com.elementalfoundry.tap-clips.settings.sprio-install-url";
static NSString * const EFSettingsStorageMinRecordingSecondsKey = @"com.elementalfoundry.tap-clips.settings.min-recording-seconds";
static NSString * const EFSettingsStorageMaxRecordingSecondsKey = @"com.elementalfoundry.tap-clips.settings.max-recording-seconds";
static NSString * const EFSettingsStorageDefaultRecordingSecondsKey = @"com.elementalfoundry.tap-clips.settings.default-recording-seconds";

@interface EFSettingsManager ()
@property (nonatomic, strong, readwrite) NSDictionary *typeAhead;
@property (nonatomic, strong, readwrite) NSString *postingTeamId;
@property (nonatomic, strong, readwrite) NSString *appRatingURL;
@property (nonatomic, strong, readwrite) NSString *exploreURL;
@property (nonatomic, strong, readwrite) NSString *sprioInstallURL;
@property (nonatomic, strong, readwrite) NSNumber *minRecordingSeconds;
@property (nonatomic, strong, readwrite) NSNumber *maxRecordingSeconds;
@property (nonatomic, strong, readwrite) NSNumber *defaultRecordingSeconds;
@end

@implementation EFSettingsManager

+ (id)sharedManager
{
    static EFSettingsManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [EFSettingsManager managerFromDisk];
    });
    return manager;
}

- (id)init
{
    self = [super init];
    if (self) {
        _minRecordingSeconds = @3;
        _maxRecordingSeconds = @15;
        _defaultRecordingSeconds = @10;
    }
    return self;
}

- (void)decodeData:(NSCoder *)aDecoder
{
    _typeAhead = [aDecoder decodeObjectForKey:EFSettingsStorageTypeAheadKey];
    _postingTeamId = [aDecoder decodeObjectForKey:EFSettingsStoragePostingTeamIdKey];
    _appRatingURL = [aDecoder decodeObjectForKey:EFSettingsStorageAppRatingURLKey];
    _exploreURL = [aDecoder decodeObjectForKey:EFSettingsStorageExploreURLKey];
    _sprioInstallURL = [aDecoder decodeObjectForKey:EFSettingsStorageSprioInstallURLKey];
    _minRecordingSeconds = [aDecoder decodeObjectForKey:EFSettingsStorageMinRecordingSecondsKey];
    _maxRecordingSeconds = [aDecoder decodeObjectForKey:EFSettingsStorageMaxRecordingSecondsKey];
    _defaultRecordingSeconds = [aDecoder decodeObjectForKey:EFSettingsStorageDefaultRecordingSecondsKey];
    
    //TODO: remove duration (max min def) from settings
    _defaultRecordingSeconds = @10;
}

- (void)encodeData:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.typeAhead forKey:EFSettingsStorageTypeAheadKey];
    [aCoder encodeObject:self.postingTeamId forKey:EFSettingsStoragePostingTeamIdKey];
    [aCoder encodeObject:self.appRatingURL forKey:EFSettingsStorageAppRatingURLKey];
    [aCoder encodeObject:self.exploreURL forKey:EFSettingsStorageExploreURLKey];
    [aCoder encodeObject:self.sprioInstallURL forKey:EFSettingsStorageSprioInstallURLKey];
    [aCoder encodeObject:self.minRecordingSeconds forKey:EFSettingsStorageMinRecordingSecondsKey];
    [aCoder encodeObject:self.maxRecordingSeconds forKey:EFSettingsStorageMaxRecordingSecondsKey];
    [aCoder encodeObject:self.defaultRecordingSeconds forKey:EFSettingsStorageDefaultRecordingSecondsKey];
}

//////////////////////////////////////////////////////////////
#pragma mark - Update
//////////////////////////////////////////////////////////////
- (void)updateSettings
{
    [[EFAPIClient sharedClient] fetchSettingsWithSuccess:^(BOOL wasSuccessful, id response, id cache) {
        if (wasSuccessful) {
            NSDictionary *settings = [response objectForKey:@"settings" defaultValue:nil];
            [self importSettings:[settings objectForKey:@"tapClips" defaultValue:nil]];
            [self importTypeAheads:[settings objectForKey:@"tapClipsTypeaheads" defaultValue:nil]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:EFSettingsUpdatedNotification object:nil];
            });
        }
    } failure:^(NSError *error) {
        [Flurry logError:@"Error Fetching Settings" message:error.localizedDescription error:error];
    }];
}

- (void)importSettings:(NSArray *)settingsArray
{
    for (NSDictionary *settingsDict in settingsArray) {
        NSString *key = [settingsDict objectForKey:@"id" defaultValue:nil];
        id value = [settingsDict objectForKey:@"value" defaultValue:nil];
        if ([key isEqualToString:@"teamid"] && value) {
            self.postingTeamId = value;
        } else if ([key isEqualToString:@"minLengthSeconds"] && value) {
            self.minRecordingSeconds = value;
        } else if ([key isEqualToString:@"maxLengthSeconds"] && value) {
            self.maxRecordingSeconds = value;
        } else if ([key isEqualToString:@"appstoreURL"] && value) {
            self.appRatingURL = value;
        } else if ([key isEqualToString:@"iosExploreUrl"] && value) {
            self.exploreURL = value;
        } else if ([key isEqualToString:@"sprioInstallURL"] && value) {
            self.sprioInstallURL = value;
        }
    }
}

- (void)importTypeAheads:(NSDictionary *)settings
{
    if (settings && [settings isKindOfClass:[NSDictionary class]]) {
        self.typeAhead = settings;
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Lookup
//////////////////////////////////////////////////////////////
- (NSString *)replacementStringForKey:(NSString *)replacementKey
{
    NSDictionary *replacementDict = [self.typeAhead objectForKey:replacementKey defaultValue:nil];
    return [replacementDict objectForKey:@"replace" defaultValue:nil];
}

//////////////////////////////////////////////////////////////
#pragma mark - Cache
//////////////////////////////////////////////////////////////
+ (NSString *)cacheLocation
{
    return [NSString stringWithFormat:@"settingsdata%@.dat", [UIApplication bundleSuffix]];
}

@end
