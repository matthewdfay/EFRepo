//
//  EFTwitterRequest.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/25/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFTwitterRequest.h"
#import "EFTwitterManager.h"
#import "EFExtensions.h"
#import <CommonCrypto/CommonHMAC.h>

static NSInteger SortParameter(NSString *key1, NSString *key2, void *context) {
    NSComparisonResult r = [key1 compare:key2];
    if(r == NSOrderedSame) { // compare by value in this case
        NSDictionary *dict = (__bridge NSDictionary *)context;
        NSString *value1 = dict[key1];
        NSString *value2 = dict[key2];
        return [value1 compare:value2];
    }
    return r;
}

static NSString * const EFTwitterRequestTokenURLString = @"https://api.twitter.com/oauth/request_token";

@implementation EFTwitterRequest

+ (void)performRequestTokenFetchWithCallback:(EFTwittherSignedRequestHandler)callback
{
    EFTwitterRequest *twitterRequest = [[EFTwitterRequest alloc] init];
    NSURLRequest *request = [twitterRequest buildRequestForRequestToken];
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (callback) {
            callback (data, response, connectionError);
        }
    }];
}

- (NSURLRequest *)buildRequestForRequestToken
{
    NSData *bodyData = [@"x_auth_mode=reverse_auth&" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authorizationHeader = [self authorizationHeaderWithBodyData:bodyData];
    NSURLRequest *requestTokenRequest = [self requestTokenRequestWithBodyData:bodyData authorizationHeader:authorizationHeader];
    return requestTokenRequest;
}

- (NSString *)authorizationHeaderWithBodyData:(NSData *)bodyData
{
    NSMutableDictionary *authorizationParameters = [NSMutableDictionary dictionary];
    [authorizationParameters setObject:[UIApplication createUniqueIdentifier] forKey:@"oauth_nonce"];
    [authorizationParameters setObject:[NSString stringWithFormat:@"%d", (int)[[NSDate date] timeIntervalSince1970]] forKey:@"oauth_timestamp"];
    [authorizationParameters setObject:@"HMAC-SHA1" forKey:@"oauth_signature_method"];
    [authorizationParameters setObject:@"1.0" forKey:@"oauth_version"];
    [authorizationParameters setObject:[[EFTwitterManager sharedManager] consumerKey] forKey:@"oauth_consumer_key"];
    
    NSString *base64Signature = [self createSignatureFromAuthorizationParams:authorizationParameters andBodyData:bodyData];
    [authorizationParameters setObject:base64Signature forKey:@"oauth_signature"];
    
    NSMutableArray *authorizationHeaderItems = [NSMutableArray array];
    for(NSString *key in authorizationParameters) {
        NSString *value = authorizationParameters[key];
        [authorizationHeaderItems addObject:[NSString stringWithFormat:@"%@=\"%@\"",
                                             [key ab_RFC3986EncodedString],
                                             [value ab_RFC3986EncodedString]]];
    }
    
    NSString *authorizationHeaderString = [authorizationHeaderItems componentsJoinedByString:@", "];
    
    authorizationHeaderString = [NSString stringWithFormat:@"OAuth %@", authorizationHeaderString];
    
    return authorizationHeaderString;
}

- (NSString *)createSignatureFromAuthorizationParams:(NSDictionary *)authParams andBodyData:(NSData *)bodyData
{
    NSURL *url = [NSURL URLWithString:EFTwitterRequestTokenURLString];
    NSDictionary *additionalBodyParameters = nil;
    NSMutableDictionary *allParamters = [authParams mutableCopy];
    if(bodyData) {
        NSString *string = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
        if(string) {
            additionalBodyParameters = [string parseIntoDictionary];
        }
    }
    if(additionalBodyParameters) [allParamters addEntriesFromDictionary:additionalBodyParameters];
    
    // -> UTF-8 -> RFC3986
    NSMutableDictionary *encodedParameters = [NSMutableDictionary dictionary];
    for(NSString *key in allParamters) {
        NSString *value = [allParamters objectForKey:key];
        [encodedParameters setObject:value forKey:key];
        encodedParameters[[key ab_RFC3986EncodedString]] = [value ab_RFC3986EncodedString];
    }
    
    //Must be ordered
    NSArray *sortedKeys = [[encodedParameters allKeys] sortedArrayUsingFunction:SortParameter context:(__bridge void *)(encodedParameters)];
    NSMutableArray *parameterArray = [NSMutableArray array];
    for(NSString *key in sortedKeys) {
        [parameterArray addObject:[NSString stringWithFormat:@"%@=%@", key, encodedParameters[key]]];
    }
    
    //Put it into a single string
    NSString *normalizedParameterString = [parameterArray componentsJoinedByString:@"&"];
    NSString *normalizedURLString = [NSString stringWithFormat:@"%@://%@%@", [url scheme], [url host], [url path]];
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",
                                     [@"POST" ab_RFC3986EncodedString],
                                     [normalizedURLString ab_RFC3986EncodedString],
                                     [normalizedParameterString ab_RFC3986EncodedString]];
    NSString *key = [NSString stringWithFormat:@"%@&", [[[EFTwitterManager sharedManager] consumerSecret] ab_RFC3986EncodedString]];
    
    return [self base64SignatureFromKey:key baseString:signatureBaseString];
}

- (NSString *)base64SignatureFromKey:(NSString *)key baseString:(NSString *)baseString
{
    unsigned char buf[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, [key UTF8String], [key length], [baseString UTF8String], [baseString length], buf);
    NSData *signature =  [NSData dataWithBytes:buf length:CC_SHA1_DIGEST_LENGTH];
    return [signature base64EncodedString];
}

- (NSURLRequest *)requestTokenRequestWithBodyData:(NSData *)bodyData authorizationHeader:(NSString *)authorizationHeader
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:EFTwitterRequestTokenURLString]];
    [request setTimeoutInterval:8];
    [request setHTTPMethod:@"POST"];
    [request setValue:authorizationHeader forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:bodyData];
    return request;
}

@end
