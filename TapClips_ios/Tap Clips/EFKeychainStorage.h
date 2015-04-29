//
//  EFKeychainStorage.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/21/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EFKeychainStorage : NSObject

/**
 Searches the keychain for a string with the given key.
 If it finds the key and attached string it will return it.
 If the keychain finds an object that is not a key, it will not retun it.
 */
+ (NSString *)stringForKey:(NSString *)key;

/**
 Adds the given string to the keychain identified by the given key.
 */
+ (void)setString:(NSString *)string forKey:(NSString *)key;

@end
