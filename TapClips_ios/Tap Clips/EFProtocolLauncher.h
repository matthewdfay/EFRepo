//
//  EFProtocolLauncher.h
//  TapClips
//
//  Created by Matthew Fay on 5/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Format = tapclips://action.<#action#>/path/
 */
@interface EFProtocolLauncher : NSObject

/**
 The protocol that was passed on initialization.
 */
@property (nonatomic, copy, readonly) NSURL *protocol;
@property (nonatomic, copy, readonly) NSString *action;
@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, copy, readonly) NSDictionary *options;
@property (nonatomic, copy, readonly) NSString *referringApplication;

- (NSArray *)parseErrors;

- (BOOL)isValidProtocol;

- (id)initWithProtocol:(NSURL *)url;
- (id)initWithProtocol:(NSURL *)url referringApplication:(NSString *)referringApplication;

/**
 Causes the Launcher to perform the action specified by the protocol.
 */
- (void)performProtocolAction;

@end
