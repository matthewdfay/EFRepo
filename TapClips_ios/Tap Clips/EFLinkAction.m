//
//  EFLinkAction.m
//  TapClips
//
//  Created by Matthew Fay on 6/18/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFLinkAction.h"
#import "EFUser.h"
#import "EFAppDelegate.h"
#import "EFRootViewController.h"

@implementation EFLinkAction

- (void)perform
{
    if ([self.path isEqualToString:@"/sprio"]) {
        [self linkSprioAccount];
    }
}

- (void)linkSprioAccount
{
    [[EFUser currentUser] connectUserWithSprioCallback:^(BOOL wasSuccessful, NSString *message) {
        if (wasSuccessful) {
            NSError *error;
            NSDictionary *sprioDict = [[EFUser currentUser] sprioAuthDictForTeam:[[EFUser currentUser] currentSprioTeamId]];
            if ([[sprioDict allKeys] count]) {
                NSData *dictionaryData = [NSJSONSerialization dataWithJSONObject:@{@"linkedInfo": sprioDict} options:0 error:&error];
                NSString *dictionaryString = [[NSString alloc] initWithData:dictionaryData encoding:NSUTF8StringEncoding];
                NSString *jsCode = [NSString stringWithFormat:@"window.tcCall(%@);", dictionaryString];
                [[[EFAppDelegate rootViewController] activeWebView] stringByEvaluatingJavaScriptFromString:jsCode];
            }
        }
    }];
}

@end
