//
//  EFUser.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/21/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^EFUserImageCallback)(UIImage *image, BOOL wasCached);
typedef void (^EFUserCallbackBlock)(BOOL wasSuccessful, NSString * message);
typedef void (^EFTwitterAccountsCallbackBlock)(BOOL wasSuccessful, NSArray *twitterHandles, NSString *errorMessage);
typedef void (^EFTwitterSearchCallbackBlock)(NSArray *handles, NSError *error);
@interface EFUser : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSString *userId;
@property (nonatomic, strong, readonly) NSString *serverUserId;
@property (nonatomic, strong, readonly) NSString *facebookToken;
@property (nonatomic, strong, readonly) NSString *currentTwitterHandle;
@property (nonatomic, strong, readonly) NSString *currentSprioTeamId;
@property (nonatomic, strong, readonly) NSString *currentSprioTeamName;
@property (nonatomic, strong, readonly) NSString *shareURL;

+ (EFUser *)currentUser;
+ (BOOL)isUserLoggedIn;

+ (BOOL)isFacebookConnected;
- (BOOL)isFacebookDefault;
- (void)setFacebookAsDefault:(BOOL)defaultValue;
- (void)connectUserWithFacebookCallback:(EFUserCallbackBlock)callback;
- (void)connectUserWithFacebookShareCallback:(EFUserCallbackBlock)callback;

- (BOOL)isTwitterDefault;
- (void)setTwitterAsDefault:(BOOL)defaultValue;
- (void)connectUserWithTwitterCallback:(EFTwitterAccountsCallbackBlock)callback;
- (void)connectUserWithTwitterHandle:(NSString *)handle callback:(EFTwitterAccountsCallbackBlock)callback;
- (void)searchForTwitterHandle:(NSString *)searchTerm callback:(EFTwitterSearchCallbackBlock)callback;
- (NSDictionary *)twitterAuthDictForHandle:(NSString *)handle;

- (BOOL)isSprioAvailable;
- (BOOL)isSprioDefault;
- (void)setSprioAsDefault:(BOOL)defaultValue;
- (void)connectUserWithSprioCallback:(EFUserCallbackBlock)callback;
- (NSDictionary *)sprioAuthDictForTeam:(NSString *)teamId;
- (id)fetchSprioTeamImage:(EFUserImageCallback)callback;

- (void)fetchNewShareDictionaryWithCallback:(EFUserCallbackBlock)callback;
- (NSDictionary *)getShareDictionary;

+ (void)logout;

@end
