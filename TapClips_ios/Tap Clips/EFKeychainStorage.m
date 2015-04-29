//
//  EFKeychainStorage.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/21/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFKeychainStorage.h"

static NSString * const EFKeychainStringSalt = @"com.elementalfoundry.tapclips";

@implementation EFKeychainStorage

+ (NSString *)stringForKey:(NSString *)key
{
    if (!key) return nil;
    
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    CFDataRef dataRef = NULL;
    NSString *string = nil;
    
    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:[NSString stringWithFormat:@"%@%@", EFKeychainStringSalt, key] forKey:(__bridge id)kSecAttrAccount];
    [query setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    
    OSStatus errCheck = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&dataRef);
    if (errCheck == noErr && dataRef) {
        NSData *stringData = CFBridgingRelease(dataRef);
        string = [[NSString alloc] initWithBytes:[stringData bytes] length:[stringData length] encoding:NSUTF8StringEncoding];
        if (![string isKindOfClass:[NSString class]])
            string = nil;
    }
    
    return string;
}

+ (void)setString:(NSString *)string forKey:(NSString *)key
{
    if (!key) return;
    
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:[NSString stringWithFormat:@"%@%@", EFKeychainStringSalt, key] forKey:(__bridge id)kSecAttrAccount];
    
    if ([string length] == 0) {
        SecItemDelete((__bridge CFDictionaryRef)query);
    } else {
        NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
        OSStatus errCheck = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
        if (errCheck == noErr) {
            //Updating the string for key
            NSDictionary *updateDict = @{(__bridge id)kSecValueData: stringData};
            SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)updateDict);
        } else {
            //adding the string for key
            [query setObject:stringData forKey:(__bridge id)kSecValueData];
            SecItemAdd((__bridge CFDictionaryRef)query, NULL);
        }
    }
}

@end
