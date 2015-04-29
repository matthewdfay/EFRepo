//
//  NSFileManager+EFExtensions.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/21/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "NSFileManager+EFExtensions.h"

@implementation NSFileManager (EFExtensions)

- (NSString *)applicationDocumentsDirectory
{
    NSString *bundleID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    return [self findOrCreateDirectoryInUserMask:NSDocumentDirectory appendingComponent:bundleID error:nil];
}

- (NSString *)findOrCreateDirectoryInUserMask:(NSSearchPathDirectory)directory appendingComponent:(NSString *)component error:(NSError **)error
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
    NSString *path = nil;
    
    if ([paths count] ==0) {
        if (error) {
            *error = [NSError errorWithDomain:@"EFUnknownDirectoryDomain" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"unknown directory found"}];
        }
    } else {
        path = [paths objectAtIndex:0];
        if (component) {
            path = [path stringByAppendingPathComponent:component];
        }
    }
    
    if (path) {
        if (![self createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:error]) {
            path = nil;
        }
    }
    
    return path;
}

@end
