//
//  EFNetworkRequest.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFNetworkRequest.h"
#import "EFAPIClient.h"
#import "EFExtensions.h"

static dispatch_queue_t _EFNetworkRequestCounterQueue(void)
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.elementalfoundry.ios.network-request-counter-queue", 0);
    });
    return queue;
}

static NSMutableSet *_EFActiveNetworkRequests(void)
{
    static NSMutableSet *set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSMutableSet set];
    });
    return set;
}

static void _EFNetworkRequestIncrement(id request)
{
    dispatch_async(_EFNetworkRequestCounterQueue(), ^{
        if (request) {
            if ([_EFActiveNetworkRequests() count] == 0) {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            }
            [_EFActiveNetworkRequests() addObject:request];
        }
    });
}

static void _EFNetworkRequestDecrement(id request)
{
    dispatch_async(_EFNetworkRequestCounterQueue(), ^{
        if (request && [_EFActiveNetworkRequests() containsObject:request]) {
            [_EFActiveNetworkRequests() removeObject:request];
            if ([_EFActiveNetworkRequests() count] == 0) {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            }
        }
    });
}

@interface EFNetworkRequest () <NSURLConnectionDelegate>
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *downloadedData;
@property (nonatomic, strong) NSHTTPURLResponse *lastResponse;
@property (nonatomic, copy) EFNetworkRequestSuccessBlock success;
@property (nonatomic, copy) EFNetworkRequestFailureBlock failure;

@property (nonatomic, readonly) NSArray *EFAllowedHosts;
@end

@implementation EFNetworkRequest {
    BOOL _hasCleanedUp;
    BOOL _hasStarted;
}

//////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
//////////////////////////////////////////////////////////////
- (id)init
{
    return [self initWithRequest:nil];
}

- (id)initWithRequest:(NSURLRequest *)request
{
    return [self initWithRequest:request success:nil];
}

- (id)initWithRequest:(NSURLRequest *)request success:(EFNetworkRequestSuccessBlock)success
{
    return [self initWithRequest:request success:success failure:nil];
}

- (id)initWithRequest:(NSURLRequest *)request success:(EFNetworkRequestSuccessBlock)success failure:(EFNetworkRequestFailureBlock)failure
{
    if (!request) {
        [NSException raise:NSInvalidArgumentException format:@"EFNetworkRequest must be initialized with a valid request"];
    }
    
    self = [super init];
    if (self) {
        _request = request;
        _URL = [request.URL copy];
        _success = [success copy];
        _failure = [failure copy];
    }
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark - Class Methods
//////////////////////////////////////////////////////////////
+ (id)sendRequest:(NSURLRequest *)request
{
    return [self sendRequest:request success:nil];
}

+ (id)sendRequest:(NSURLRequest *)request success:(EFNetworkRequestSuccessBlock)success
{
    return [self sendRequest:request success:success failure:nil];
}

+ (id)sendRequest:(NSURLRequest *)request success:(EFNetworkRequestSuccessBlock)success failure:(EFNetworkRequestFailureBlock)failure
{
    EFNetworkRequest *newRequest = [[self alloc] initWithRequest:request success:success failure:failure];
    [newRequest start];
    return newRequest;
}

//////////////////////////////////////////////////////////////
#pragma mark - Start/Cancel
//////////////////////////////////////////////////////////////
- (void)start
{
    if (_hasStarted) return;
    
    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
    [self.connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [self.connection start];
    _EFNetworkRequestIncrement(self.connection);
    _hasStarted = YES;
}

- (void)cancel
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self cancelSynchronized];
    });
}

- (void)cancelSynchronized
{
    if (!_hasCleanedUp) {
        [self.connection cancel];
        [self cleanup];
        _hasCleanedUp = YES;
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Subclass Override
//////////////////////////////////////////////////////////////
- (id)processData:(NSData *)data;
{
    return data;
}

//////////////////////////////////////////////////////////////
#pragma mark - Convenience Methods
//////////////////////////////////////////////////////////////
- (void)cleanup
{
    _EFNetworkRequestDecrement(self.connection);
    self.connection = nil;
}

- (void)executeBlockOnMain:(dispatch_block_t)block
{
    if (!block) return;
    
    dispatch_async(dispatch_get_main_queue(), block);
    [self cleanup];
}

- (void)callbackWithSuccess:(id)object
{
    [self executeBlockOnMain:^{
        if (self.success)
            self.success(self.lastResponse, object);
    }];
}

- (void)callbackWithFailure:(NSError *)error
{
    [self executeBlockOnMain:^{
        if (self.failure)
            self.failure(error);
    }];
}

//////////////////////////////////////////////////////////////
#pragma mark - NSURLConnection Delegate
//////////////////////////////////////////////////////////////
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self callbackWithFailure:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.downloadedData = [NSMutableData data];
    self.lastResponse = (NSHTTPURLResponse *)response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.downloadedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        id processedObject = [self processData:self.downloadedData];
        [self callbackWithSuccess:processedObject];
    });
}

@end

//////////////////////////////////////////////////////////////
#pragma mark - EFJSONRequest
//////////////////////////////////////////////////////////////
@implementation EFJSONRequest

- (id)processData:(NSData *)data
{
    if (!data) return nil;
    
    NSError *error;
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error) {
        NSLog(@"Unable to process JSON data at URL: %@ error<%@>", self.URL, error);
    }
    return obj;
}

@end

//////////////////////////////////////////////////////////////
#pragma mark - EFImageRequest
//////////////////////////////////////////////////////////////
@implementation EFImageRequest

- (id)processData:(NSData *)data
{
    if (!data) return nil;
    
    return [UIImage imageWithData:data];
}

@end