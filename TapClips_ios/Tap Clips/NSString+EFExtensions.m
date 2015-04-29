//
//  NSString+EFExtensions.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/25/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "NSString+EFExtensions.h"
#import "NSData+EFExtensions.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (EFExtensions)

- (NSString *)ab_RFC3986EncodedString // UTF-8 encodes prior to URL encoding
{
    NSMutableString *result = [NSMutableString string];
    const char *p = [self UTF8String];
    unsigned char c;
    
    for(; (c = *p); p++)
    {
        switch(c)
        {
            case '0' ... '9':
            case 'A' ... 'Z':
            case 'a' ... 'z':
            case '.':
            case '-':
            case '~':
            case '_':
                [result appendFormat:@"%c", c];
                break;
            default:
                [result appendFormat:@"%%%02X", c];
        }
    }
    return result;
}

- (NSString *)shaHash
{
    if (!self.length)
        return nil;
    
    NSData *data = [self dataUsingEncoding:NSASCIIStringEncoding];
    NSMutableData *sha256Out = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (uint)data.length, sha256Out.mutableBytes);
    return [sha256Out hexString];
}

- (NSString *)urlEncode
{
    CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, (CFStringRef)@"@&=+$,/?%#[]!*'();:", kCFStringEncodingUTF8);
    return CFBridgingRelease(escaped);
}

- (NSString *)urlDecode
{
    return [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSDictionary *)parseIntoDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *pairs = [self componentsSeparatedByString:@"&"];
    for(NSString *pair in pairs) {
        NSArray *keyValue = [pair componentsSeparatedByString:@"="];
        if([keyValue count] == 2) {
            NSString *key = keyValue[0];
            NSString *value = keyValue[1];
            value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            if(key && value)
                dict[key] = value;
        }
    }
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
