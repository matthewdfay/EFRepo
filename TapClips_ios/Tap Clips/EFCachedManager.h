//
//  EFCachedManager.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/31/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EFCachedManager : NSObject

+ (id)managerFromDisk;

+ (void)writeToDisk;
+ (void)removeFromDisk;

- (void)preDecodeSetup;
- (void)commonInit;

/**
 Must be overwritten.
 */
+ (id)sharedManager;
+ (NSString *)cacheLocation;
- (void)encodeData:(NSCoder *)aCoder;
- (void)decodeData:(NSCoder *)aDecoder;

@end
