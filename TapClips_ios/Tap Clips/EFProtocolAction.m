//
//  EFProtocolAction.m
//  TapClips
//
//  Created by Matthew Fay on 5/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFProtocolAction.h"

@interface EFProtocolAction ()

@property (nonatomic, copy, readwrite) NSString *path;
@property (nonatomic, copy, readwrite) NSDictionary *options;

@end

@implementation EFProtocolAction

- (id)initWithPath:(NSString *)path options:(NSDictionary *)options
{
    self = [super init];
    if (self) {
        _path = [path copy];
        _options = [options copy];
    }
    return self;
}

- (void)perform
{
    [self doesNotRecognizeSelector:_cmd];
}

+ (BOOL)allowsActionFromReferringApplication:(NSString *)referringApplication
{
    return YES;
}

@end
