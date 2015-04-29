//
//  EFAPIClient.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^EFAPICallbackBlock)(BOOL wasSuccessful, id response, id cache);
typedef void(^EFAPIFailureBlock)(NSError *error);

@interface EFAPIClient : NSObject

+ (instancetype)sharedClient;

/**
 returns if a valid session toekn is stored.
 */
- (BOOL)hasValidSession;

/**
 reports the push token if returned
 */
- (void)trackDevicePushToken:(NSString *)pushToken success:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure;

/**
 Makes a request to the API to attach social media info to the user.
 */
- (id)attachAccount:(NSDictionary *)accountInfo forType:(NSString *)accountType success:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure;

/**
 Creates a post
 */
- (id)createPostWithDescription:(NSString *)description attachments:(NSDictionary *)attachmentURLs shareDict:(NSDictionary *)share andVideoInfo:(NSDictionary *)videoInfo success:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure;
- (id)createPostWithAttachments:(NSDictionary *)attachments toShareURL:(NSDictionary *)shareData withVideoInfo:(NSDictionary *)videoInfo success:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure;

/**
 Fetches the settings for the app.
 */
- (void)fetchSettingsWithSuccess:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure;

/**
 Fetches a url to be used for private sharing.
 */
- (void)fetchShareURLWithSuccess:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure;

/**
 Cancels the given request.
 */
- (void)cancelAPIRequest:(id)request;

@end
