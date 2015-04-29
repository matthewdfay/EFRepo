//
//  EFCachedManager.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/31/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFCachedManager.h"
#import "EFExtensions.h"

@implementation EFCachedManager

+ (id)sharedManager
{
    [NSException raise:NSGenericException format:@"Must override sharedManager"];
    return nil;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self preDecodeSetup];
        [self decodeData:aDecoder];
        [self commonInit];
    }
    return self;
}

- (void)preDecodeSetup
{
    //Intentionally Blank
}

- (void)commonInit
{
    //Intentionally Blank
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [self encodeData:aCoder];
}

- (void)encodeData:(NSCoder *)aCoder
{
    [NSException raise:NSGenericException format:@"Must override encodeData"];
}

- (void)decodeData:(NSCoder *)aDecoder
{
    [NSException raise:NSGenericException format:@"Must override decodeData"];
}

//////////////////////////////////////////////////////////////
#pragma mark - Cache
//////////////////////////////////////////////////////////////
+ (id)managerFromDisk
{
    NSData *data = [self readDataFromDisk];
    if (data) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } else {
        return [[[self class] alloc] init];
    }
}

+ (NSData *)readDataFromDisk
{
    return [NSData dataWithContentsOfFile:[self dataPath]];
}

+ (void)writeToDisk
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[[self class] sharedManager]];
    [data writeToFile:[self dataPath] atomically:YES];
}

+ (void)removeFromDisk
{
    [[NSFileManager defaultManager] removeItemAtPath:[self dataPath] error:nil];
}

+ (NSString *)dataPath
{
    NSString *appSupport = [[NSFileManager defaultManager] applicationDocumentsDirectory];
    NSString *path = [appSupport stringByAppendingPathComponent:[[self class] cacheLocation]];
    return path;
}

+ (NSString *)cacheLocation
{
    [NSException raise:NSGenericException format:@"Must override cacheLocation"];
    return nil;
}

@end
