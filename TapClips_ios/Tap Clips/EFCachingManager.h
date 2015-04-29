//
//  EFCachingManager.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/31/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EFCachingManager : NSObject

+ (void)writeCacheToDisk;
+ (void)removeCacheFromDisk;

@end
