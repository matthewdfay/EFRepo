//
//  EFReturnAction.m
//  TapClips
//
//  Created by Matthew Fay on 6/2/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFReturnAction.h"
#import "EFUser.h"
#import "EFExtensions.h"

@interface EFUser (EFReturnAction)
- (void)returnedFromSprio:(NSDictionary *)params;
@end

@implementation EFReturnAction

+ (BOOL)allowsActionFromReferringApplication:(NSString *)referringApplication
{
    if ([referringApplication isEqualToString:@"com.elementalfoundry.Sprio"] ||
        [referringApplication isEqualToString:@"com.elementalfoundry.Sprio.debug"]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)perform
{
    if ([self.path isEqualToString:@"/sprio"]) {
        [self returnFromSprio];
    }
}

- (void)returnFromSprio
{
    [[EFUser currentUser] returnedFromSprio:[self.options copy]];
}

@end
