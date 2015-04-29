//
//  EFReachability.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/20/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFReachability.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

@interface EFReachability ()

@property (nonatomic, readonly) SCNetworkReachabilityRef reachabilityRef;
@property (nonatomic, readonly) dispatch_queue_t callbackQueue;
@property (nonatomic, readonly) dispatch_queue_t serialQueue;
@property (nonatomic) EFNetworkType currentType;
@property (nonatomic, copy) EFNetworkDidChangeBlock didChangeBlock;
@property (nonatomic, copy) EFNetworkDidChangeBlock didResumeBlock;

- (EFNetworkType)networkTypeFromFlags:(SCNetworkReachabilityFlags)flags;

@end

static void EFReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
    // We need to be careful here because we are altering our state in a method that potentially can be
    // called from multiple threads.  However, we are dispatching our notifications on our private queue
    // so we don't need to worry.
    
    EFReachability *reachability = (__bridge EFReachability *)info;
    
    // Figure out what we are moving to
    EFNetworkType toType = [reachability networkTypeFromFlags:flags];
    EFNetworkType fromType = reachability.currentType;
    
    dispatch_async(reachability.serialQueue, ^{
        if (reachability.didChangeBlock)
            reachability.didChangeBlock(fromType, toType);
        
        if (reachability.didResumeBlock)
            reachability.didResumeBlock(fromType, toType);
    });
    
    reachability.currentType = toType;
}

@implementation EFReachability{
    SCNetworkReachabilityRef _reachabilityRef;
    dispatch_queue_t _callbackQueue;
    dispatch_queue_t _serialQueue;
}

- (SCNetworkReachabilityRef)reachabilityRef;
{
    if (!_reachabilityRef) {
        // We only support general reachability
        struct sockaddr_in zeroAddress;
        bzero(&zeroAddress, sizeof(zeroAddress));
        zeroAddress.sin_len = sizeof(zeroAddress);
        zeroAddress.sin_family = AF_INET;
        
        _reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);
        
        if (_reachabilityRef) {
            // Set our initial type
            SCNetworkReachabilityFlags flags;
            SCNetworkReachabilityGetFlags(_reachabilityRef, &flags);
            self.currentType = [self networkTypeFromFlags:flags];
            if (self.didChangeBlock)
                self.didChangeBlock(EFNetworkTypeUnknown, self.currentType);
        }
    }
    return _reachabilityRef;
}

//////////////////////////////////////////////////////////////
#pragma mark - Initialization
//////////////////////////////////////////////////////////////
+ (instancetype)reachabilityWithNetworkDidChangeBlock:(EFNetworkDidChangeBlock)block;
{
    return [[self alloc] initWithNetworkDidChangeBlock:block];
}

+ (instancetype)reachabilityWithNetworkDidResumeBlock:(dispatch_block_t)block;
{
    return [[self alloc] initWithNetworkDidResumeBlock:block];
}

- (id)initWithNetworkDidChangeBlock:(EFNetworkDidChangeBlock)block;
{
    return [self initWithNetworkDidChangeBlock:block networkDidResumeBlock:nil];
}

- (id)initWithNetworkDidResumeBlock:(dispatch_block_t)block;
{
    return [self initWithNetworkDidChangeBlock:nil networkDidResumeBlock:block];
}

- (id)initWithNetworkDidChangeBlock:(EFNetworkDidChangeBlock)changeBlock networkDidResumeBlock:(dispatch_block_t)didResumeBlock;
{
    return [self initWithQueue:NULL networkDidChangeBlock:changeBlock networkDidResumeBlock:didResumeBlock];
}

- (id)initWithQueue:(dispatch_queue_t)queue networkDidChangeBlock:(EFNetworkDidChangeBlock)changeBlock networkDidResumeBlock:(dispatch_block_t)didResumeBlock;
{
    self = [super init];
    if (self) {
        _didChangeBlock = [changeBlock copy];
        _didResumeBlock = ^(EFNetworkType fromType, EFNetworkType toType) {
            if (fromType == EFNetworkTypeUnknown && didResumeBlock)
                didResumeBlock();
        };
        
        if (!queue)
            queue = dispatch_get_main_queue();
        _callbackQueue = queue;
        
        _serialQueue = dispatch_queue_create("com.elementalfoundry.ios.reachability-serial-queue", 0);
        dispatch_set_target_queue(_serialQueue, _callbackQueue);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupReachability];
        });
    }
    return self;
}

- (void)dealloc;
{
    if (_reachabilityRef) {
        SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, NULL);
        CFRelease(_reachabilityRef);
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Setup
//////////////////////////////////////////////////////////////
- (void)setupReachability
{
    SCNetworkReachabilityContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
    if (SCNetworkReachabilitySetCallback(self.reachabilityRef, EFReachabilityCallback, &context)) {
        SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, self.callbackQueue);
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Helper Methods
//////////////////////////////////////////////////////////////
+ (NSString *)displayStringForNetworkType:(EFNetworkType)type;
{
    NSString *displayString = @"";
    switch (type) {
        case EFNetworkTypeWireless:
            displayString = NSLocalizedString(@"Wireless", @"wireless network display string");
            break;
        case EFNetworkTypeCell:
            displayString = NSLocalizedString(@"Cell", @"cell network display string");
            break;
        case EFNetworkTypeUnknown:
            displayString = NSLocalizedString(@"Unknown", @"unknown network display string");
            break;
    }
    return displayString;
}

- (NSString *)currentNetworkTypeDisplayString;
{
    return [[self class] displayStringForNetworkType:self.currentType];
}

- (EFNetworkType)networkTypeFromFlags:(SCNetworkReachabilityFlags)flags;
{
    if (!(flags & kSCNetworkReachabilityFlagsReachable))
        return EFNetworkTypeUnknown;
    
    
    EFNetworkType type = EFNetworkTypeUnknown;
    
    if (!(flags & kSCNetworkReachabilityFlagsConnectionRequired))
        type = EFNetworkTypeWireless;
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) ||
        (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)) {
        if (!(flags & kSCNetworkReachabilityFlagsInterventionRequired))
            type = EFNetworkTypeWireless;
    }
    
	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
        type = EFNetworkTypeCell;
    
    return type;
}

+ (BOOL)isNetworkReachable
{
    BOOL reachable = NO;
    struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);
	SCNetworkReachabilityFlags flags;
    
    if (SCNetworkReachabilityGetFlags(reachability, &flags)) {
        reachable = [self networkAvailableFromFlags:flags];
    }
    
    return reachable;
}

+ (BOOL)networkAvailableFromFlags:(SCNetworkReachabilityFlags)flags
{
    BOOL returnValue = NO;
	if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
		// The target host is not reachable.
		return returnValue;
	}
    
	if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
	{
		/*
         If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
         */
		returnValue = YES;
	}
    
	if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
	{
        /*
         ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
         */
        
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
        {
            /*
             ... and no [user] intervention is needed...
             */
            returnValue = YES;
        }
    }
    
	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
	{
		/*
         ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
         */
		returnValue = YES;
	}
    
	return returnValue;
}

@end
