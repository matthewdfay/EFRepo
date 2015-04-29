//
//  NSData+EFExtensions.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/25/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (EFExtensions)

- (NSString *)base64EncodedString;
- (NSString *)hexString;

@end
