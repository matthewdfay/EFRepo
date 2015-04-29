//
//  EFProtocolAction.h
//  TapClips
//
//  Created by Matthew Fay on 5/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EFProtocolAction : NSObject

@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, copy, readonly) NSDictionary *options;

- (id)initWithPath:(NSString *)path options:(NSDictionary *)options;

/**
 Performs the action.
 */
- (void)perform;

/**
 Gives the ability to have action only work from a given application.
 */
+ (BOOL)allowsActionFromReferringApplication:(NSString *)referringApplication;

@end
