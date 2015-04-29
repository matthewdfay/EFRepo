//
//  EFTwitterManager.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/25/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACAccount;

typedef void(^EFTwitterReverseAuthCallback)(NSDictionary *responseParams, NSError *error);
typedef void(^EFTwitterHandlesCallback)(NSArray *handles, NSError *error);

@interface EFTwitterManager : NSObject

/**
 Returns the single instance of this manager.
 */
+ (id)sharedManager;

/**
 *  Obtains the access token and secret for |account|.
 *
 *  There are two steps required for Reverse Auth:
 *
 *  The first sends a signed request that *you* must sign to Twitter to obtain
 *      an Authorization: header. You sign the request with your own OAuth keys.
 *      All apps have access to Reverse Auth by default, so there are no special
 *      permissions required.
 *
 *  The second step uses SLRequest to sign and send the response to step 1 back
 *      to Twitter. The response to this request, if everything worked, will
 *      include an user's access token and secret which can then
 *      be used in conjunction with your consumer key and secret to make
 *      authenticated calls to Twitter.
 */
- (void)performReverseAuthForAccount:(ACAccount *)account withCallback:(EFTwitterReverseAuthCallback)callback;

/**
 * Returns true if there are local Twitter accounts available.
 */
+ (BOOL)isLocalTwitterAccountAvailable;

/**
 * Returns true if the Info.plist is configured properly.
 */
- (BOOL)hasAppKeys;
- (NSString *)consumerKey;
- (NSString *)consumerSecret;

/**
 Searches for twitter handles based on search term.
 */
- (void)findTwitterHandlesWithSearch:(NSString *)searchTerm forAccount:(ACAccount *)account callback:(EFTwitterHandlesCallback)callback;

@end
