//
//  EFUser.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/21/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFUser.h"
#import "EFTwitterManager.h"
#import "EFSettingsManager.h"
#import "EFKeychainStorage.h"
#import "EFImage.h"
#import "EFAPIClient.h"
#import "EFExtensions.h"
#import <FacebookSDK/FacebookSDK.h>
#import <Social/Social.h>
#import "Flurry.h"

static NSString * const EFTwitterConsumerKey = @"5oMu7jcAJec7Fr7zFkkwA";
static NSString * const EFTwitterAPIToken = @"FEL7HWoLZR1cUhlvDKrIbq6YEno3SJ8wEfsGMQ5FRc";

static NSString * const EFUserIdKeyChainKey = @"tapClipsUserIdKey";

static NSString * const EFUserIdKey = @"com.elementalfoundry.tap-clips.user-id";
static NSString * const EFServerUserIdKey = @"com.elementalfoundry.tap-clips.server-user-id";
static NSString * const EFFacebookIdKey = @"com.elementalfoundry.tap-clips.facebook-id";
static NSString * const EFFacebookDefaultKey = @"com.elementalfoundry.tap-clips.facebook-default";
static NSString * const EFTwitterAuthKey = @"com.elementalfoundry.tap-clips.twitter-id";
static NSString * const EFTwitterHandleKey = @"com.elementalfoundry.tap-clips.twitter-handle";
static NSString * const EFTwitterDefaultKey = @"com.elementalfoundry.tap-clips.twitter-default";
static NSString * const EFSprioDefaultKey = @"com.elementalfoundry.tap-clips.sprio.default";
static NSString * const EFSprioTeamIdKey = @"com.elementalfoundry.tap-clips.sprio.team-id";
static NSString * const EFSprioTeamNameKey = @"com.elementalfoundry.tap-clips.sprio.team-name";
static NSString * const EFSprioTeamImageURLKey = @"com.elementalfoundry.tap-clips.sprio.team-image-url";
static NSString * const EFSprioAuthDictKey = @"com.elementalfoundry.tap-clips.sprio.auth-dict";
static NSString * const EFShareURLKey = @"com.elementalfoundry.tap-clips.share-url";

@interface EFAPIClient (EFUser)
- (void)destroySession;
@end

@interface EFUser ()

@property (nonatomic, strong) ACAccountStore *store;
@property (nonatomic, strong) NSArray *twitterAccounts;

@property (nonatomic, strong, readwrite) NSString *backingUserId;
@property (nonatomic, strong, readwrite) NSString *backingServerUserId;
@property (nonatomic, strong, readwrite) NSMutableDictionary *twitterAuthDict;
@property (nonatomic, strong, readwrite) NSString *currentTwitterHandle;

@property (nonatomic, strong, readwrite) NSString *currentSprioTeamId;
@property (nonatomic, strong, readwrite) NSString *currentSprioTeamName;
@property (nonatomic, strong, readwrite) NSString *currentSprioTeamImageURL;
@property (nonatomic, strong) UIImage *currentSprioTeamImage;
@property (nonatomic, strong, readwrite) NSMutableDictionary *sprioAuthDict;
@property (nonatomic, strong) EFUserCallbackBlock sprioCallback;

@property (nonatomic, strong, readwrite) NSDictionary *backingShareDict;

@property (nonatomic, assign) BOOL facebookDefaultBacking;
@property (nonatomic, assign) BOOL twitterDefaultBacking;
@property (nonatomic, assign) BOOL sprioDefaultBacking;

@end


@implementation EFUser

+ (void)logout
{
    [[EFUser currentUser] setCurrentSprioTeamId:nil];
    [[EFUser currentUser] setShareDictionary:nil];
    [[EFUser currentUser] setTwitterAuthDict:nil];
    [[EFUser currentUser] setSprioAuthDict:nil];
    [[EFUser currentUser] setServerUserId:nil];
    [[EFAPIClient sharedClient] destroySession];
}

- (ACAccountStore *)store
{
    if (!_store) {
        _store = [[ACAccountStore alloc] init];
    }
    return _store;
}

- (void)setShareDictionary:(NSDictionary *)share
{
    if (_backingShareDict != share) {
        _backingShareDict = share;
        [EFUser writeUserToDisk];
    }
}

- (NSString *)shareURL
{
    return [self.backingShareDict objectForKey:@"url" defaultValue:nil];
}

- (void)setCurrentSprioTeamId:(NSString *)currentSprioTeamId
{
    if (_currentSprioTeamId != currentSprioTeamId) {
        _currentSprioTeamId = currentSprioTeamId;
        _currentSprioTeamName = nil;
        _currentSprioTeamImage = nil;
        _currentSprioTeamImageURL = nil;
    }
}

- (void)setCurrentTwitterHandle:(NSString *)currentTwitterHandle
{
    if (_currentTwitterHandle != currentTwitterHandle) {
        _currentTwitterHandle = currentTwitterHandle;
        [EFUser writeUserToDisk];
    }
}

- (void)setServerUserId:(NSString *)serverUserId
{
    if (_backingServerUserId != serverUserId) {
        _backingServerUserId = serverUserId;
        [EFUser writeUserToDisk];
    }
}

- (NSString *)serverUserId
{
    return [_backingServerUserId copy];
}

- (NSString *)userId
{
    if (!_backingUserId) {
        _backingUserId = [EFKeychainStorage stringForKey:EFUserIdKeyChainKey];
        if (!_backingUserId.length) {
            _backingUserId = [UIApplication createUniqueIdentifier];
            [EFKeychainStorage setString:_backingUserId forKey:EFUserIdKeyChainKey];
        }
    }
    return _backingUserId;
}

- (NSString *)facebookToken
{
    NSString *token = nil;
    if ([[FBSession activeSession] isOpen]) {
        token = [FBSession activeSession].accessTokenData.accessToken;
    }
    return token;
}

+ (EFUser *)currentUser
{
    static EFUser *theUser = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        theUser = [self userFromDisk];
        if (!theUser) {
            theUser = [[EFUser alloc] init];
        }
        [self activiateUsersFacebookSession];
    });
    return theUser;
}

- (id)init
{
    self = [super init];
    if (self) {
        _twitterAuthDict = [NSMutableDictionary dictionary];
        _sprioAuthDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _backingUserId = [aDecoder decodeObjectForKey:EFUserIdKey];
        _backingServerUserId = [aDecoder decodeObjectForKey:EFServerUserIdKey];
        _twitterAuthDict = [[aDecoder decodeObjectForKey:EFTwitterAuthKey] mutableCopy];
        if (!_twitterAuthDict) {
            _twitterAuthDict = [NSMutableDictionary dictionary];
        }
        _sprioAuthDict = [[aDecoder decodeObjectForKey:EFSprioAuthDictKey] mutableCopy];
        if (!_sprioAuthDict) {
            _sprioAuthDict = [NSMutableDictionary dictionary];
        }
        _currentTwitterHandle = [aDecoder decodeObjectForKey:EFTwitterHandleKey];
        _facebookDefaultBacking = [aDecoder decodeBoolForKey:EFFacebookDefaultKey];
        _twitterDefaultBacking = [aDecoder decodeBoolForKey:EFTwitterDefaultKey];
        _sprioDefaultBacking = [aDecoder decodeBoolForKey:EFSprioDefaultKey];
        _currentSprioTeamId = [aDecoder decodeObjectForKey:EFSprioTeamIdKey];
        _currentSprioTeamName = [aDecoder decodeObjectForKey:EFSprioTeamNameKey];
        _currentSprioTeamImageURL = [aDecoder decodeObjectForKey:EFSprioTeamImageURLKey];
        _backingShareDict = [aDecoder decodeObjectForKey:EFShareURLKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.userId forKey:EFUserIdKey];
    [aCoder encodeObject:self.serverUserId forKey:EFServerUserIdKey];
    [aCoder encodeObject:self.twitterAuthDict forKey:EFTwitterAuthKey];
    [aCoder encodeObject:self.sprioAuthDict forKey:EFSprioAuthDictKey];
    [aCoder encodeObject:self.currentTwitterHandle forKey:EFTwitterHandleKey];
    [aCoder encodeBool:self.facebookDefaultBacking forKey:EFFacebookDefaultKey];
    [aCoder encodeBool:self.twitterDefaultBacking forKey:EFTwitterDefaultKey];
    [aCoder encodeBool:self.sprioDefaultBacking forKey:EFSprioDefaultKey];
    [aCoder encodeObject:self.currentSprioTeamId forKey:EFSprioTeamIdKey];
    [aCoder encodeObject:self.currentSprioTeamName forKey:EFSprioTeamNameKey];
    [aCoder encodeObject:self.currentSprioTeamImageURL forKey:EFSprioTeamImageURLKey];
    [aCoder encodeObject:self.backingShareDict forKey:EFShareURLKey];
}

+ (BOOL)isUserLoggedIn
{
    return [[EFAPIClient sharedClient] hasValidSession];
}

//////////////////////////////////////////////////////////////
#pragma mark - Connect
//////////////////////////////////////////////////////////////
+ (void)activiateUsersFacebookSession
{
    [FBSession openActiveSessionWithAllowLoginUI:NO];
}

- (void)connectUserWithFacebookCallback:(EFUserCallbackBlock)callback
{
    if ([[FBSession activeSession] isOpen] && [[[FBSession activeSession] permissions] containsObject:@"email"]) {
        if (callback) {
            callback (YES, nil);
        }
    } else {
        [FBSession openActiveSessionWithReadPermissions:@[@"email"] allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            [EFUser facebookSessionStateChanged:session state:status];
            if (status == FBSessionStateOpen || status == FBSessionStateOpenTokenExtended) {
                NSString *token = [self facebookToken];
                [[EFAPIClient sharedClient] attachAccount:@{@"token": token.length ? token : @""} forType:@"fb" success:^(BOOL wasSuccessful, id response, id cache) {
                    if (callback)
                        callback(wasSuccessful, nil);
                } failure:^(NSError *error) {
                    if (callback)
                        callback(NO, error.localizedDescription);
                }];
            } else if (callback) {
                callback (NO, error.localizedDescription);
            }
        }];
    }
}

- (void)connectUserWithFacebookShareCallback:(EFUserCallbackBlock)callback
{
    if ([[FBSession activeSession] isOpen] && [[[FBSession activeSession] permissions] containsObject:@"publish_actions"]) {
        if (callback)
            callback(YES, nil);
    } else {
        [[FBSession activeSession] requestNewPublishPermissions:@[@"publish_actions"] defaultAudience:FBSessionDefaultAudienceEveryone completionHandler:^(FBSession *session, NSError *error) {
            if (callback)
                callback((error ? NO : YES), nil);
        }];
    }
}

- (void)connectUserWithTwitterCallback:(EFTwitterAccountsCallbackBlock)callback
{
    ACAccountType *twitterType = [self.store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [self.store requestAccessToAccountsWithType:twitterType options:nil completion:^(BOOL granted, NSError *error) {
        if (granted) {
            self.twitterAccounts = [self.store accountsWithAccountType:twitterType];
            if ([self.twitterAccounts count] == 1) {
                ACAccount *selectedAccount = [self.twitterAccounts objectAtIndex:0];
                [self fetchTwitterAuthTokenForAccount:selectedAccount callback:callback];
            } else if (callback) {
                BOOL wasSuccessful = [self.twitterAccounts count] > 1;
                callback (wasSuccessful, [self twitterAccountHandles], (wasSuccessful ? nil : @"Please go to Settings and add the Twitter account you would like to use."));
            }
        } else if (callback) {
            callback (NO, nil, error.localizedDescription);
        }
    }];
}

//////////////////////////////////////////////////////////////
#pragma mark - Facebook
//////////////////////////////////////////////////////////////
+ (void)facebookSessionStateChanged:(FBSession *)session state:(FBSessionState)state
{
    switch (state) {
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
            
        default:
            break;
    }
}

+ (BOOL)isFacebookConnected
{
    return [[FBSession activeSession] isOpen];
}

- (BOOL)isFacebookDefault
{
    return self.facebookDefaultBacking;
}

- (void)setFacebookAsDefault:(BOOL)defaultValue
{
    self.facebookDefaultBacking = defaultValue;
    [EFUser writeUserToDisk];
}

//////////////////////////////////////////////////////////////
#pragma mark - Twitter
//////////////////////////////////////////////////////////////
- (void)fetchTwitterAuthTokenForAccount:(ACAccount *)selectedAccount callback:(EFTwitterAccountsCallbackBlock)callback
{
    if ([selectedAccount.accountType.identifier isEqualToString:ACAccountTypeIdentifierTwitter] &&
        selectedAccount.username.length && [self twitterAuthDictForHandle:selectedAccount.username]) {
        self.currentTwitterHandle = selectedAccount.username;
        if (callback) {
            callback (YES, @[selectedAccount.username], nil);
        }
    } else {
        [[EFTwitterManager sharedManager] performReverseAuthForAccount:selectedAccount withCallback:^(NSDictionary *responseParams, NSError *error) {
            if (!error && responseParams) {
                NSString *currentTwitterHandle = [responseParams objectForKey:@"screen_name" defaultValue:nil];
                if (currentTwitterHandle.length) {
                    [self.twitterAuthDict setObject:responseParams forKey:currentTwitterHandle];
                    self.currentTwitterHandle = currentTwitterHandle;
                    [[EFAPIClient sharedClient] attachAccount:responseParams forType:@"twitter" success:^(BOOL wasSuccessful, id response, id cache) {
                        NSArray *accounts = nil;
                        if ([selectedAccount.accountType.identifier isEqualToString:ACAccountTypeIdentifierTwitter] &&
                            selectedAccount.username.length) {
                            accounts = @[selectedAccount.username];
                        }
                        
                        NSString *message = nil;
                        if (!wasSuccessful) {
                            message = [response objectForKey:@"message" defaultValue:nil];
                        }
                        
                        if (callback) {
                            callback (wasSuccessful, accounts, message);
                        }
                    } failure:^(NSError *error) {
                        if (callback) {
                            callback (NO, nil, error.localizedDescription);
                        }
                    }];
                }
            } else if (callback) {
                callback (NO, nil, error.localizedDescription);
            }
        }];
    }
}

- (void)connectUserWithTwitterHandle:(NSString *)handle callback:(EFTwitterAccountsCallbackBlock)callback
{
    ACAccount *selectedAccount = [self twitterAccountFromHandle:handle];
    [self fetchTwitterAuthTokenForAccount:selectedAccount callback:callback];
}

- (NSArray *)twitterAccountHandles
{
    NSMutableArray *handles = [NSMutableArray array];
    for (ACAccount *account in self.twitterAccounts) {
        if ([account.accountType.identifier isEqualToString:ACAccountTypeIdentifierTwitter]) {
            [handles addObject:account.username];
        }
    }
    return handles;
}

- (ACAccount *)twitterAccountFromHandle:(NSString *)handle
{
    ACAccount *selectedAccount = nil;
    for (ACAccount *account in self.twitterAccounts) {
        if ([account.accountType.identifier isEqualToString:ACAccountTypeIdentifierTwitter] &&
            [account.username isEqualToString:handle]) {
            selectedAccount = account;
            break;
        }
    }
    return selectedAccount;
}

- (BOOL)isTwitterDefault
{
    return self.twitterDefaultBacking;
}

- (void)setTwitterAsDefault:(BOOL)defaultValue
{
    self.twitterDefaultBacking = defaultValue;
    [EFUser writeUserToDisk];
}

- (NSDictionary *)twitterAuthDictForHandle:(NSString *)handle
{
    return [self.twitterAuthDict objectForKey:handle defaultValue:nil];
}

- (void)searchForTwitterHandle:(NSString *)searchTerm callback:(EFTwitterSearchCallbackBlock)callback
{
    [[EFTwitterManager sharedManager] findTwitterHandlesWithSearch:searchTerm forAccount:[self twitterAccountFromHandle:self.currentTwitterHandle] callback:^(NSArray *handles, NSError *error) {
        if (callback) {
            callback (handles, error);
        }
    }];
}

//////////////////////////////////////////////////////////////
#pragma mark - Sprio
//////////////////////////////////////////////////////////////
- (BOOL)isSprioAvailable
{
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"sprio://"]];
}

- (BOOL)isSprioDefault
{
    return self.sprioDefaultBacking;
}

- (void)setSprioAsDefault:(BOOL)defaultValue
{
    self.sprioDefaultBacking = defaultValue;
    if (!self.sprioDefaultBacking) {
        self.currentSprioTeamId = nil;
    }
    [EFUser writeUserToDisk];
}

- (void)connectUserWithSprioCallback:(EFUserCallbackBlock)callback
{
    if ([self isSprioAvailable]) {
        self.sprioCallback = callback;
        NSURL *connectURL = [NSURL URLWithString:@"sprio://action.select/team?ret=tapclips://action.return"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] openURL:connectURL];
        });
    } else if ([[EFSettingsManager sharedManager] sprioInstallURL].length) {
        if (callback) {
            callback (NO, @"Sprio not installed");
        }
        NSURL *connectURL = [NSURL URLWithString:[[EFSettingsManager sharedManager] sprioInstallURL]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] openURL:connectURL];
        });
    } else if (callback) {
        callback (NO, @"No Sprio URL");
    }
}

- (void)returnedFromSprio:(NSDictionary *)params
{
    [self updateSprioDataWithParams:params];
    if (self.sprioCallback) {
        self.sprioCallback (([params.allKeys count] ? YES : NO), @"");
    }
}

- (void)updateSprioDataWithParams:(NSDictionary *)params
{
    self.currentSprioTeamId = [params objectForKey:@"teamId" defaultValue:nil];
    self.currentSprioTeamName = [params objectForKey:@"teamName" defaultValue:@""];
    self.currentSprioTeamImageURL = [params objectForKey:@"teamIconURL" defaultValue:nil];
    if (self.currentSprioTeamId.length) {
        [self.sprioAuthDict setObject:params forKey:self.currentSprioTeamId];
    }
    NSString *sessionToken = [params objectForKey:@"sessionToken" defaultValue:nil];
    if (sessionToken.length) {
        [[EFAPIClient sharedClient] attachAccount:@{@"token": sessionToken} forType:@"sprio" success:nil failure:nil];
    }
}

- (NSDictionary *)sprioAuthDictForTeam:(NSString *)teamId
{
    return [self.sprioAuthDict objectForKey:teamId defaultValue:nil];
}

- (id)fetchSprioTeamImage:(EFUserImageCallback)callback
{
    if (self.currentSprioTeamImage) {
        if (callback)
            callback (self.currentSprioTeamImage, YES);
        return nil;
    } else if (self.currentSprioTeamImageURL.length) {
        return [EFImage fetchImageWithString:self.currentSprioTeamImageURL size:EFImageSizeThumbnail callback:^(UIImage *image, BOOL wasCached) {
            self.currentSprioTeamImage = [image roundedImageWithBorder:YES];
            if (callback)
                callback(self.currentSprioTeamImage, wasCached);
        }];
    } else {
        if (callback)
            callback (nil, NO);
        return nil;
    }
    return nil;
}

//////////////////////////////////////////////////////////////
#pragma mark - Sharing
//////////////////////////////////////////////////////////////
- (void)fetchNewShareDictionaryWithCallback:(EFUserCallbackBlock)callback
{
    [[EFAPIClient sharedClient] fetchShareURLWithSuccess:^(BOOL wasSuccessful, id response, id cache) {
        if (wasSuccessful) {
            [self setShareDictionary:response];
        }
        if (callback) {
            callback (wasSuccessful, nil);
        }
    } failure:^(NSError *error) {
        if (callback) {
            callback (NO, error.localizedDescription);
        }
    }];
}

- (NSDictionary *)getShareDictionary
{
    NSDictionary *shareDict = self.backingShareDict;
    [self setShareDictionary:nil];
    return shareDict;
}

//////////////////////////////////////////////////////////////
#pragma mark - User Storage / Retrieval
//////////////////////////////////////////////////////////////
+ (id)userFromDisk
{
    NSData *userData = [self readUserDataFromDisk];
    if (userData) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:userData];
    } else {
        return nil;
    }
}

+ (NSData *)readUserDataFromDisk
{
    return [NSData dataWithContentsOfFile:[self userDataPath]];
}

+ (void)writeUserToDisk
{
    NSData *userData = [NSKeyedArchiver archivedDataWithRootObject:[EFUser currentUser]];
    [userData writeToFile:[self userDataPath] atomically:YES];
}

+ (void)removeUserFromDisk
{
    [[NSFileManager defaultManager] removeItemAtPath:[self userDataPath] error:nil];
}

+ (NSString *)userDataPath
{
    NSString *appSupport = [[NSFileManager defaultManager] applicationDocumentsDirectory];
    return [appSupport stringByAppendingPathComponent:[NSString stringWithFormat:@"userdata%@.dat", [UIApplication bundleSuffix]]];
}

@end
