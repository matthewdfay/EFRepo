//
//  NSString+EFExtensions.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/25/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (EFExtensions)

- (NSString *)ab_RFC3986EncodedString;
- (NSString *)shaHash;
- (NSString *)urlEncode;
- (NSString *)urlDecode;

- (NSDictionary *)parseIntoDictionary;

@end
