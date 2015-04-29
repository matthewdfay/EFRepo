//
//  EFReachability.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/20/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger
{
    EFNetworkTypeWireless = 0,
    EFNetworkTypeCell,
    EFNetworkTypeUnknown
} EFNetworkType;

typedef void(^EFNetworkDidChangeBlock)(EFNetworkType fromType, EFNetworkType toType);

@interface EFReachability : NSObject

+ (instancetype)reachabilityWithNetworkDidChangeBlock:(EFNetworkDidChangeBlock)block;
+ (instancetype)reachabilityWithNetworkDidResumeBlock:(dispatch_block_t)block;

- (id)initWithNetworkDidChangeBlock:(EFNetworkDidChangeBlock)block;
- (id)initWithNetworkDidResumeBlock:(dispatch_block_t)block;

/**
 All callbacks will be called back on queue.  The default queue is the main queue.
 */
- (id)initWithNetworkDidChangeBlock:(EFNetworkDidChangeBlock)changeBlock networkDidResumeBlock:(dispatch_block_t)didResumeBlock;
- (id)initWithQueue:(dispatch_queue_t)queue networkDidChangeBlock:(EFNetworkDidChangeBlock)changeBlock networkDidResumeBlock:(dispatch_block_t)didResumeBlock;

/**
 Returns a string to display for the given networking type
 */
+ (NSString *)displayStringForNetworkType:(EFNetworkType)type;

/**
 Returns a display string for the current state of the network.
 This method should not be used for anything other than displaying
 information.
 */
- (NSString *)currentNetworkTypeDisplayString;

/**
 A general check to see if the user has network.
 */
+ (BOOL)isNetworkReachable;

@end
