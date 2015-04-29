//
//  EFNetworkRequest.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>

//////////////////////////////////////////////////////////////
//  Block Definitions
//////////////////////////////////////////////////////////////
typedef void (^EFNetworkRequestSuccessBlock)(NSHTTPURLResponse *response, id responseObject);
typedef void (^EFNetworkRequestFailureBlock)(NSError *error);

@interface EFNetworkRequest : NSObject

/**
 The origional request and URL
 */
@property (nonatomic, copy, readonly) NSURL *URL;
@property (nonatomic, strong, readonly) NSURLRequest *request;

/**
 Creates the request object and calls start immediately.
 The API request object is returned.
 */
+ (id)sendRequest:(NSURLRequest *)request;
+ (id)sendRequest:(NSURLRequest *)request success:(EFNetworkRequestSuccessBlock)success;
+ (id)sendRequest:(NSURLRequest *)request success:(EFNetworkRequestSuccessBlock)success failure:(EFNetworkRequestFailureBlock)failure;

/**
 Initializes the object with the given parameters.
 When initialized, you must call start before the request will begin
 
 NOTE: The request is not automatically started.
 */
- (id)initWithRequest:(NSURLRequest *)request;
- (id)initWithRequest:(NSURLRequest *)request success:(EFNetworkRequestSuccessBlock)success;
- (id)initWithRequest:(NSURLRequest *)request success:(EFNetworkRequestSuccessBlock)success failure:(EFNetworkRequestFailureBlock)failure;

/**
 Starts the request.
 
 NOTE: This class is a one off class, meaning once it has been started
 it cannot be started again.
 */
- (void)start;

/**
 Cancels the request.
 
 NOTE: Calling cancel will make it so no callback blocks are executed.
 */
- (void)cancel;

/**
 Allows subclasses the ability to transform the data before returning it to the user.
 
 NOTE: The default implementation returns the data object.
 */
- (id)processData:(NSData *)data;

@end


@interface EFJSONRequest : EFNetworkRequest

/**
 The EFJSONRequest is a subclass of EFNetworkRequest that prosesses the downloaded
 data as if it was JSON. It has no other functionality.
 */

@end

@interface EFImageRequest : EFNetworkRequest

/**
 The EFJSONRequest is a subclass of EFNetworkRequest that prosesses the downloaded
 data as if it was an Image. It has no other functionality.
 */

@end