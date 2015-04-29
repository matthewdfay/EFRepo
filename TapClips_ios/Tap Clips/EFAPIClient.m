//
//  EFAPIClient.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFAPIClient.h"
#import "EFNetworkRequest.h"
#import "EFUser.h"
#import "EFKeychainStorage.h"
#import "EFAppDelegate.h"
#import "EFSettingsManager.h"
#import "EFUploadManager.h"
#import "EFExtensions.h"
#import "Flurry.h"

#define EF_USE_TEST_URL (0)
#define EF_LOG_ALL_REQUESTS (0)

#if !DEBUG && EF_USE_TEST_URL
#error "YOU ARE TRYING TO BUILD TO PRODUCTION BUT POINTING TO THE TESTING ENVIRONMENT!"
#endif

//////////////////////////////////////////////////////////////
// External Constants
//////////////////////////////////////////////////////////////
NSString * const EFRequiredRequestFailedNotification = @"EFRequiredRequestFailed";
NSString * const EFAPIDidRecoverFromFailedRequestNotification = @"EFAPIDidRecoverFromFailedRequest";

//////////////////////////////////////////////////////////////
// Static Constants
//////////////////////////////////////////////////////////////
static NSString * const EFTestBaseAPIURL = @"https://milodev.herokuapp.com"; //192.168.1.8:5000";
static NSInteger const EFFatalResponseRetrySeconds = 15;
static NSString * const EFAPIVersion = @"2.0";
static NSString * const EFSessionTokenKey = @"sessionToken";
static NSString * const EFAppSecretKey = @"38VHPwTTmT1ugYQ45jsVs9HM1ojFWdWH";

/////////////////////// DO NOT CHANGE ////////////////////
static NSString * const EFBaseAPIURL = @"https://api.tapclips.com";
//////////////////////////////////////////////////////////

@interface EFUser (Login)
@property (nonatomic, strong, readwrite) NSString *serverUserId;
@end


@interface EFAPIClient ()
@property (nonatomic, strong) NSMutableSet *requiredPaths;
@property (nonatomic, strong) NSTimer *fatalResponseRetryTimer;
@property (assign) BOOL hasNotRecoveredFromFatalResponse;
@property (nonatomic, copy) NSURL *baseURL;
@end

@implementation EFAPIClient {
    dispatch_queue_t _concurrentRequiredPathsQueue;
    dispatch_queue_t _concurrentSessionTokenQueue;
    NSString *_sessionToken;
}

+ (instancetype)sharedClient
{
    static EFAPIClient *client = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[EFAPIClient alloc] init];
    });
    return client;
}

- (NSString *)defaultBaseURL
{
#if EF_USE_TEST_URL
    return EFTestBaseAPIURL;
#else
    return EFBaseAPIURL;
#endif
}

- (void)warnIfUsingTestURL
{
#if EF_USE_TEST_URL
    NSLog(@"********************************************");
    NSLog(@"        APP IS RUNNING ON A TEST URL        ");
    NSLog(@"        %@", self.baseURL);
    NSLog(@"********************************************");
#endif
}

//////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
//////////////////////////////////////////////////////////////
- (id)init
{
    self = [super init];
    if (self) {
        _baseURL = [NSURL URLWithString:[self defaultBaseURL]];
        _hasNotRecoveredFromFatalResponse = NO;
        _concurrentRequiredPathsQueue = dispatch_queue_create("com.elementalfoundry.ios.required-paths-queue", DISPATCH_QUEUE_CONCURRENT);
        _concurrentSessionTokenQueue = dispatch_queue_create("com.elementalfoundry.ios.session-token-queue", DISPATCH_QUEUE_CONCURRENT);
        _requiredPaths = [NSMutableSet set];
        [self restoreSessionToken];
        [self warnIfUsingTestURL];
    }
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark - Properties
//////////////////////////////////////////////////////////////
- (void)setBaseURL:(NSURL *)baseURL
{
    if (!baseURL)
        [NSException raise:NSInvalidArgumentException format:@"baseURL must not be nil"];
    
    static NSString * const HTTPSScheme = @"https";
    
    if (_baseURL != baseURL) {
        if (baseURL.scheme == nil) {
            _baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", HTTPSScheme, baseURL.path]];
        } else if (![baseURL.scheme isEqualToString:HTTPSScheme]) {
            _baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", HTTPSScheme, baseURL.host]];
        } else {
            _baseURL = [baseURL copy];
        }
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Request Creation
//////////////////////////////////////////////////////////////
- (NSURLRequest *)requestWithPath:(NSString *)path
{
    return [self requestWithPath:path method:@"POST"];
}

- (NSURLRequest *)requestWithPath:(NSString *)path method:(NSString *)method
{
    return [self requestWithPath:path method:method parameters:nil];
}

- (NSURLRequest *)requestWithPath:(NSString *)path method:(NSString *)method parameters:(NSDictionary *)parameters
{
    NSURL *URL = [NSURL URLWithString:path relativeToURL:self.baseURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    [request setHTTPMethod:method];
    [self updateRequestWithDefaultHeaders:request];
    
    if (parameters && [method isEqualToString:@"POST"]) {
        NSData *bodyData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
        [request setHTTPBody:bodyData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[bodyData length]] forHTTPHeaderField:@"Content-Length"];
    }
    
    return request;
}

- (void)updateRequestWithDefaultHeaders:(NSMutableURLRequest *)request
{
    //Device Info
    [request setValue:[[UIDevice currentDevice] model] forHTTPHeaderField:@"device-model"];
    [request setValue:[[UIDevice currentDevice] systemVersion] forHTTPHeaderField:@"system-version"];
    
    //App Data
    [request setValue:[UIApplication applicationVersion] forHTTPHeaderField:@"app-version"];
    [request setValue:[UIApplication applicationUniqueIdentifier] forHTTPHeaderField:@"device-identifier"];
    [request setValue:[UIApplication applicationForegroundDateInSecondsSince1970] forHTTPHeaderField:@"foreground-date"];
    [request setValue:[UIApplication applicationLaunchDateInSecondsSince1970] forHTTPHeaderField:@"launch-date"];
    
    if (self.sessionToken.length > 0)
        [request setValue:self.sessionToken forHTTPHeaderField:@"session-token"];
}

//////////////////////////////////////////////////////////////
#pragma mark - Path Creation
//////////////////////////////////////////////////////////////
- (NSString *)buildUnauthenticatedPath:(NSArray *)params
{
    NSMutableArray *unauthParams = [params mutableCopy];
    [unauthParams insertObject:@"unauth" atIndex:0];
    return [self buildPath:[unauthParams copy]];
}

- (NSString *)buildAuthenticatedPath:(NSArray *)params
{
    return [self buildPath:params];
}

- (NSString *)buildAuthenticatedPathIfLoggedIn:(NSArray *)params
{
    if (self.sessionToken.length > 0) {
        return [self buildAuthenticatedPath:params];
    } else {
        return [self buildUnauthenticatedPath:params];
    }
}

- (NSString *)buildPath:(NSArray *)params
{
    NSMutableString *path = [NSMutableString stringWithFormat:@"%@/api/%@", self.baseURL, EFAPIVersion];
    for (NSString *component in params) {
        [path appendFormat:@"/%@", component];
    }
    if (![path hasSuffix:@"/"]) {
        [path appendString:@"/"];
    }
    
    return [path copy];
}

//////////////////////////////////////////////////////////////
#pragma mark - Request Sending
//////////////////////////////////////////////////////////////
- (id)sendAPIRequest:(NSURLRequest *)request success:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure
{
    return [self sendAPIRequest:request success:success failure:failure retry:^{
        [[EFAPIClient sharedClient] loginUser:[[EFUser currentUser] userId] withPushToken:[[NSUserDefaults standardUserDefaults] objectForKey:EFPushTokenKey] success:^(BOOL wasSuccessful, id response, id loginCache) {
            if (wasSuccessful) {
                NSMutableURLRequest *mutRequest = [request mutableCopy];
                [self updateRequestWithDefaultHeaders:mutRequest];
                [self sendAPIRequest:mutRequest success:success failure:failure retry:nil];
            } else if (success) {
                success(NO, nil, nil);
            }
        } failure:^(NSError *error) {
            if (failure) {
                failure (error);
            }
        }];
    }];
}

- (id)sendAPIRequest:(NSURLRequest *)request success:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure retry:(void(^)())retry
{
    return [EFJSONRequest sendRequest:request success:^(NSHTTPURLResponse *response, id APIResponse) {
        BOOL wasSucessful = [[APIResponse objectForKey:@"success"] boolValue];
        id responseObject = nil;
        id cache = nil;
        BOOL shouldCallback = YES;
        
        if (wasSucessful) {
            responseObject = [APIResponse objectForKey:@"response"];
            cache = [APIResponse objectForKey:@"cache"];
        } else {
            responseObject = [APIResponse objectForKey:@"error"];
            [Flurry logError:[NSString stringWithFormat:@"API Not Successful For URL = %@", request.URL.absoluteString] message:[responseObject objectForKey:@"name" defaultValue:@""] error:nil];
            if ([[responseObject objectForKey:@"name"] isEqualToString:@"invalidSessionToken"]) {
                shouldCallback = NO;
                if (retry) {
                    retry ();
                }
            }
        }
        
        [self updateSessionTokenFromResponse:response];
        
        [self logRequest:request andResponse:responseObject];
        
        if (!wasSucessful && [self shouldDisplayFailureError:responseObject])
            [UIAlertView showAlertWithMessage:[responseObject objectForKey:@"message"]];
        
        if (success && shouldCallback) {
            success(wasSucessful, responseObject, cache);
        }
        
        [self checkIfResponse:response wasFatal:(!wasSucessful && !APIResponse) || (!NSLocationInRange([response statusCode], NSMakeRange(200, 100)))];
        
    } failure:^(NSError *error) {
        [Flurry logError:[NSString stringWithFormat:@"API Failure For URL = %@", request.URL.absoluteString] message:[error localizedDescription] error:error];
        if (failure) {
            failure(error);
        }
    }];
}

- (void)updateSessionTokenFromResponse:(NSHTTPURLResponse *)response
{
    NSDictionary *headers = [response allHeaderFields];
    NSString *sessionToken = [headers objectForKey:@"Session-Token" defaultValue:nil];
    if (sessionToken && self.sessionToken.length > 0) {
        self.sessionToken = sessionToken;
    }
}

- (BOOL)shouldDisplayFailureError:(NSDictionary *)failureDict
{
    NSString *nameKey = [failureDict objectForKey:@"name"];
    return ([nameKey isEqualToString:@"notVerified"] ||
            [nameKey isEqualToString:@"userExsists"] ||
            [nameKey isEqualToString:@"loginFailed"]);
}

- (void)logRequest:(NSURLRequest *)request andResponse:(id)responseObject
{
#if EF_LOG_ALL_REQUESTS
    NSLog(@"request = %@", request.URL);
    NSLog(@"response = %@", responseObject);
    NSLog(@"********************************");
#endif
}

- (void)checkIfResponse:(NSHTTPURLResponse *)response wasFatal:(BOOL)wasFatal
{
    if (wasFatal) {
        [self fatalResponseOccurred:response];
    } else {
        [self attemptToRecoverFromFatalResponseIfNecessary];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Required Paths
//////////////////////////////////////////////////////////////
- (BOOL)isPathRequired:(NSString *)path
{
    __block BOOL isRequired = NO;
    dispatch_sync(_concurrentRequiredPathsQueue, ^{
        isRequired = [self.requiredPaths containsObject:path];
    });
    
    return isRequired;
}

- (void)requirePath:(NSString *)path
{
    if (![self isPathRequired:path]) {
        [self addRequiredPath:path];
    }
}

- (void)addRequiredPath:(NSString *)requiredPath
{
    dispatch_barrier_async(_concurrentRequiredPathsQueue, ^{
        [self.requiredPaths addObject:requiredPath];
    });
}

//////////////////////////////////////////////////////////////
#pragma mark - API Failure / Recovery
//////////////////////////////////////////////////////////////
- (void)fatalResponseOccurred:(NSHTTPURLResponse *)response
{
    NSString *path = [response.URL absoluteString];
    if (!self.hasNotRecoveredFromFatalResponse && [self isPathRequired:path]) {
        self.hasNotRecoveredFromFatalResponse = YES;
        NSLog(@"request for path <%@> failed", path);
        [self postRequiredPathFailedNotification];
        [self beginTryingToReconnectToAPI];
    }
}

- (void)attemptToRecoverFromFatalResponseIfNecessary
{
    if (self.hasNotRecoveredFromFatalResponse) {
        self.hasNotRecoveredFromFatalResponse = NO;
        [self postRecoveryNotification];
        [self stopTryingToReconnectToAPI];
    }
}

- (void)beginTryingToReconnectToAPI
{
    if (!self.fatalResponseRetryTimer) {
        self.fatalResponseRetryTimer = [NSTimer scheduledTimerWithTimeInterval:EFFatalResponseRetrySeconds target:self selector:@selector(reconnectTimerFired:) userInfo:nil repeats:YES];
    }
}

- (void)stopTryingToReconnectToAPI
{
    [self.fatalResponseRetryTimer invalidate];
    self.fatalResponseRetryTimer = nil;
}

- (void)postRequiredPathFailedNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:EFRequiredRequestFailedNotification object:self];
}

- (void)postRecoveryNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:EFAPIDidRecoverFromFailedRequestNotification object:self];
}

- (void)reconnectTimerFired:(NSTimer *)timer
{
    [self pingAPI];
}

- (void)pingAPI
{
    NSString *path = [self buildUnauthenticatedPath:@[@"ping"]];
    NSURLRequest *request = [self requestWithPath:path];
    [self sendAPIRequest:request success:^(BOOL wasSuccessful, id response, id cache) {
        if (wasSuccessful) {
            [self attemptToRecoverFromFatalResponseIfNecessary];
        }
    } failure:nil];
}

//////////////////////////////////////////////////////////////
#pragma mark - Session Token
//////////////////////////////////////////////////////////////
- (void)setSessionToken:(NSString *)sessionToken
{
    dispatch_barrier_async(_concurrentSessionTokenQueue, ^{
        if (![_sessionToken isEqualToString:sessionToken]) {
            _sessionToken = sessionToken;
            [self writeSessionTokenToKeychain:_sessionToken];
        }
    });
}

- (NSString *)sessionToken
{
    __block NSString *token = nil;
    dispatch_sync(_concurrentSessionTokenQueue, ^{
        token = _sessionToken;
    });
    return token;
}

- (void)writeSessionTokenToKeychain:(NSString *)sessionToken
{
    [EFKeychainStorage setString:sessionToken forKey:EFSessionTokenKey];
}

- (void)restoreSessionToken
{
    self.sessionToken = [EFKeychainStorage stringForKey:EFSessionTokenKey];
}

- (void)destroySession
{
    self.sessionToken = nil;
}

- (BOOL)hasValidSession
{
    return self.sessionToken.length > 0;
}

//////////////////////////////////////////////////////////////
#pragma mark - Push
//////////////////////////////////////////////////////////////
- (void)trackDevicePushToken:(NSString *)pushToken success:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure
{
    NSString *path = [self buildAuthenticatedPath:@[@"registerPushToken"]];
    [self requirePath:path];
    NSDictionary *params = @{@"token": pushToken ?:@"", @"serviceType": @"apple", @"environment": @"production"};
    NSURLRequest *request = [self requestWithPath:path method:@"POST" parameters:params];
    [self sendAPIRequest:request success:success failure:failure];
}

//////////////////////////////////////////////////////////////
#pragma mark - Login
//////////////////////////////////////////////////////////////
- (id)loginUser:(NSString *)userId withPushToken:(NSString *)pushToken success:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure
{
    NSString *path = [self buildUnauthenticatedPath:@[@"loginUser"]];
    [self requirePath:path];
    NSDictionary *params = [self loginParametersWithUserId:userId pushToken:pushToken];
    NSURLRequest *request = [self requestWithPath:path method:@"POST" parameters:params];
    return [self sendAPIRequest:request success:^(BOOL wasSuccessful, id response, id cache) {
        if (wasSuccessful) {
            self.sessionToken = [response objectForKey:@"sessionToken"];
            [[EFUser currentUser] setServerUserId:[response objectForKey:@"userId" defaultValue:nil]];
            if (!pushToken.length && [[NSUserDefaults standardUserDefaults] objectForKey:EFPushTokenKey]) {
                [[EFAPIClient sharedClient] trackDevicePushToken:[[NSUserDefaults standardUserDefaults] objectForKey:EFPushTokenKey] success:nil failure:nil];
            }
        } else {
            self.sessionToken = nil;
        }
        
        if (success) {
            success (wasSuccessful, response, cache);
        }
    } failure:failure];
}

- (NSDictionary *)loginParametersWithUserId:(NSString *)userId pushToken:(NSString *)pushToken
{
    NSMutableDictionary *allParameters = [NSMutableDictionary dictionary];
    [allParameters setObject:@"iOS TC" forKey:@"appId"];
    [allParameters setObject:[[NSTimeZone localTimeZone] name] forKey:@"timeZone"];
    [allParameters setObject:userId forKey:@"userId"];
    [allParameters setObject:@"tc" forKey:@"userIdType"];
    
    if (pushToken.length > 0) {
        [allParameters setObject:pushToken forKey:@"token"];
        [allParameters setObject:@"apple" forKey:@"serviceType"];
    }
    
    [allParameters setObject:[self createHashForParams:allParameters] forKey:@"requestSignature"];
    
    return [allParameters copy];
}

- (NSString *)createHashForParams:(NSDictionary *)params
{
    NSString *stringToHash = @"";
    NSArray *keys = [[params allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for (NSString *key in keys) {
        NSString *value = [params objectForKey:key defaultValue:nil];
        if ([value isKindOfClass:[NSString class]]) {
            stringToHash = [stringToHash stringByAppendingString:value];
        }
    }
    stringToHash = [stringToHash stringByAppendingString:EFAppSecretKey];
    return [stringToHash.lowercaseString shaHash];
}

- (id)attachAccount:(NSDictionary *)accountInfo forType:(NSString *)accountType success:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure
{
    NSString *path = [self buildAuthenticatedPath:@[@"linkService"]];
    NSDictionary *params = @{@"value": [[accountInfo allKeys] count] ? accountInfo : @{}, @"type": accountType};
    NSURLRequest *request = [self requestWithPath:path method:@"POST" parameters:params];
    return [self sendAPIRequest:request success:success failure:failure];
}

//////////////////////////////////////////////////////////////
#pragma mark - Create Post
//////////////////////////////////////////////////////////////
- (id)createPostWithAttachments:(NSDictionary *)attachments toShareURL:(NSDictionary *)shareData withVideoInfo:(NSDictionary *)videoInfo success:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure
{
    NSDictionary *params = [self postParamsForAttachments:attachments toShareURL:shareData withVideoInfo:videoInfo];
    return [self createFeedPostWithParams:params success:success failure:failure];
}

- (id)createPostWithDescription:(NSString *)description attachments:(NSDictionary *)attachmentURLs shareDict:(NSDictionary *)share andVideoInfo:(NSDictionary *)videoInfo success:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure
{
    NSDictionary *params = [self postParamsFromDescription:description attachments:attachmentURLs shareDict:share andVideoInfo:videoInfo];
    return [self createFeedPostWithParams:params success:success failure:failure];
}

- (id)createFeedPostWithParams:(NSDictionary *)params success:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure
{
    NSString *path = [self buildAuthenticatedPath:@[@"createFeedPost"]];
    NSURLRequest *request = [self requestWithPath:path method:@"POST" parameters:params];
    return [self sendAPIRequest:request success:success failure:failure];
}

- (NSDictionary *)postParamsFromDescription:(NSString *)description attachments:(NSDictionary *)attachmentURLs shareDict:(NSDictionary *)shareDict andVideoInfo:(NSDictionary *)videoInfo
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:@"TapClips" forKey:@"appId"];
    [params setObject:@"42" forKey:@"requestSignature"];
    [params setObject:@"public" forKey:@"privacy"];
    
    //Team Id
    NSString *postingTeamId = [[EFSettingsManager sharedManager] postingTeamId];
    if (!postingTeamId.length) {
        postingTeamId = @"";
    }
    [params setObject:postingTeamId forKey:@"teamId"];
    
    //Description
    if (!description.length) {
        description = @"";
    }
    [params setObject:description forKey:@"description"];
    
    //Attachments
    if ([attachmentURLs.allKeys count]) {
        NSMutableDictionary *attachmentData = [NSMutableDictionary dictionary];
        [attachmentData setObject:@"video" forKey:@"type"];
        [attachmentData setObject:EFAWSVideoContentType forKey:@"videoType"];
        [attachmentData addEntriesFromDictionary:attachmentURLs];
        [attachmentData addEntriesFromDictionary:videoInfo];
        [params setObject:@[attachmentData] forKey:@"attachments"];
    }
    
    //Share
    if ([[shareDict allKeys] count]) {
        [params setObject:shareDict forKey:@"share"];
    }
    
    return params;
}

- (NSDictionary *)postParamsForAttachments:(NSDictionary *)attachments toShareURL:(NSDictionary *)shareDict withVideoInfo:(NSDictionary *)videoInfo
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:@"TapClips" forKey:@"appId"];
    [params setObject:@"42" forKey:@"requestSignature"];
    [params setObject:@"public" forKey:@"privacy"];
    
    //Team Id
    NSString *postingTeamId = [[EFSettingsManager sharedManager] postingTeamId];
    if (!postingTeamId.length) {
        postingTeamId = @"";
    }
    [params setObject:postingTeamId forKey:@"teamId"];
    
    //Attachments
    if ([attachments.allKeys count]) {
        NSMutableDictionary *attachmentData = [NSMutableDictionary dictionary];
        [attachmentData setObject:@"video" forKey:@"type"];
        [attachmentData setObject:EFAWSVideoContentType forKey:@"videoType"];
        [attachmentData addEntriesFromDictionary:attachments];
        [attachmentData addEntriesFromDictionary:videoInfo];
        [params setObject:@[attachmentData] forKey:@"attachments"];
    }
    
    //url
    if ([[shareDict allKeys] count]) {
        [params setObject:shareDict forKey:@"shortUrlInfo"];
    }
    
    return params;
}

//////////////////////////////////////////////////////////////
#pragma mark - Settings
//////////////////////////////////////////////////////////////
- (void)fetchSettingsWithSuccess:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure
{
    NSString *path = [self buildAuthenticatedPath:@[@"getAllInfo"]];
    [self requirePath:path];
    NSDictionary *params = @{@"include": @[@"settings"]};
    NSURLRequest *request = [self requestWithPath:path method:@"POST" parameters:params];
    [self sendAPIRequest:request success:success failure:failure];
}

//////////////////////////////////////////////////////////////
#pragma mark - ShareURL
//////////////////////////////////////////////////////////////
- (void)fetchShareURLWithSuccess:(EFAPICallbackBlock)success failure:(EFAPIFailureBlock)failure
{
    NSString *path = [self buildAuthenticatedPath:@[@"getTapClipsUrl"]];
    NSURLRequest *request = [self requestWithPath:path];
    [self sendAPIRequest:request success:success failure:failure];
}

//////////////////////////////////////////////////////////////
#pragma mark - Cancel
//////////////////////////////////////////////////////////////
- (void)cancelAPIRequest:(id)request
{
    if ([request respondsToSelector:@selector(cancel)]) {
        [request cancel];
    }
}

@end
