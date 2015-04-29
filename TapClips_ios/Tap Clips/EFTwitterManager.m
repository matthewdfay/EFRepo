//
//  EFTwitterManager.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/25/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFTwitterManager.h"
#import "EFTwitterRequest.h"
#import "EFExtensions.h"
#import <Social/Social.h>

typedef void(^EFTwitterCallback)(NSData *data, NSError *error);

static NSString * const EFTwitterAccessTokenURLString = @"https://api.twitter.com/oauth/access_token";
static NSString * const EFTwitterSearchURLString = @"https://api.twitter.com/1.1/users/search.json";

@interface EFTwitterManager ()
@property (nonatomic, strong) NSString *backingConsumerKey;
@property (nonatomic, strong) NSString *backingConsumerSecret;
@end

@implementation EFTwitterManager

+ (id)sharedManager
{
    static EFTwitterManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EFTwitterManager alloc] init];
    });
    return manager;
}

//////////////////////////////////////////////////////////////
#pragma mark - App Keys
//////////////////////////////////////////////////////////////
- (BOOL)hasAppKeys
{
    return ([[self consumerKey] length] && [[self consumerSecret] length]);
}

- (NSString *)consumerKey
{
    if (!_backingConsumerKey) {
        _backingConsumerKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"TWITTER_CONSUMER_KEY"];
    }
    return _backingConsumerKey;
}

- (NSString *)consumerSecret
{
    if (!_backingConsumerSecret) {
        _backingConsumerSecret = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"TWITTER_CONSUMER_SECRET"];
    }
    return _backingConsumerSecret;
}

//////////////////////////////////////////////////////////////
#pragma mark - Local Twitter
//////////////////////////////////////////////////////////////
+ (BOOL)isLocalTwitterAccountAvailable
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

//////////////////////////////////////////////////////////////
#pragma mark - Reverse Auth
//////////////////////////////////////////////////////////////
- (void)performReverseAuthForAccount:(ACAccount *)account withCallback:(EFTwitterReverseAuthCallback)callback
{
    NSParameterAssert(account);
    [self fetchRequestTokenCallback:^(NSData *data, NSError *error) {
        if (data && !error) {
            NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [self fetchAccessTokenForAccount:account signature:response callback:^(NSData *data, NSError *error) {
                if (callback) {
                    NSDictionary *params = nil;
                    if (!error) {
                        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        params = [responseString parseIntoDictionary];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback (params, error);
                    });
                }
            }];
        } else if (callback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback (nil, error);
            });
        }
    }];
}

- (void)fetchRequestTokenCallback:(EFTwitterCallback)callback
{
    [EFTwitterRequest performRequestTokenFetchWithCallback:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (callback) {
            callback (data, error);
        }
    }];
}

- (void)fetchAccessTokenForAccount:(ACAccount *)account signature:(NSString *)signature callback:(EFTwitterCallback)callback
{
    NSParameterAssert(account);
    NSParameterAssert(signature);
    
    SLRequest *accessTokenRequest = [self accessTokenRequestWithSignature:signature];
    [accessTokenRequest setAccount:account];
    [accessTokenRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (callback) {
            callback(responseData, error);
        }
    }];
}

- (SLRequest *)accessTokenRequestWithSignature:(NSString *)signature
{
    NSDictionary *params = @{@"x_reverse_auth_target": [self consumerKey], @"x_reverse_auth_parameters": signature};
    NSURL *authTokenURL = [NSURL URLWithString:EFTwitterAccessTokenURLString];
    return [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:authTokenURL parameters:params];
}

//////////////////////////////////////////////////////////////
#pragma mark - Search
//////////////////////////////////////////////////////////////
- (void)findTwitterHandlesWithSearch:(NSString *)searchTerm forAccount:(ACAccount *)account callback:(EFTwitterHandlesCallback)callback
{
    SLRequest *request = [self twitterSearchRequestWithTerm:searchTerm];
    [request setAccount:account];
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (callback) {
            NSArray *handles = nil;
            if (!error) {
                id obj = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
                if (!error) {
                    handles = [self handlesFromParameterArray:obj];
                }
            }
            callback (handles, error);
        }
    }];
}

- (SLRequest *)twitterSearchRequestWithTerm:(NSString *)term
{
    NSURL *searchURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?q=%@", EFTwitterSearchURLString, [term urlEncode]]];
    return [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:searchURL parameters:nil];
}

- (NSArray *)handlesFromParameterArray:(NSArray *)largeHandles
{
    NSMutableArray *handles = [NSMutableArray array];
    for (NSDictionary *user in largeHandles) {
        NSString *name = [user objectForKey:@"name" defaultValue:nil];
        NSString *handle = [user objectForKey:@"screen_name" defaultValue:nil];
        NSString *imageUrl = [user objectForKey:@"profile_image_url" defaultValue:nil];
        NSNumber *following = [user objectForKey:@"following" defaultValue:@NO];
        
        if (handle.length && following.boolValue) {
            NSMutableDictionary *userDict = [NSMutableDictionary dictionary];
            [userDict setObject:handle forKey:@"handle"];
            if (name.length) {
                [userDict setObject:name forKey:@"name"];
            }
            if (imageUrl.length) {
                [userDict setObject:imageUrl forKey:@"imageURL"];
            }
            if ([[userDict allKeys] count]) {
                [handles addObject:userDict];
            }
        }
    }
    return handles;
}

@end
