//
//  EFLaunchPageAction.m
//  TapClips
//
//  Created by Matthew Fay on 5/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFLaunchPageAction.h"
#import "EFRootViewController.h"
#import "EFExtensions.h"
#import "Flurry.h"

@implementation EFLaunchPageAction

- (void)perform
{
    if ([self.path isEqualToString:@"/videos"]) {
        [self performVideosLaunchAction];
    } else if ([self.path isEqualToString:@"/settings"]) {
        [self performSettingsLaunchAction];
    } else if ([self.path isEqualToString:@"/explore"]) {
        [self performExploreLaunchAction];
    } else if ([self.path isEqualToString:@"/web"]) {
        [self performWebLaunchAction];
    }
}

- (void)performVideosLaunchAction
{
    [Flurry logEvent:@"Launch Videos"];
    [[NSNotificationCenter defaultCenter] postNotificationName:EFDisplayVideosNotification object:nil];
}

- (void)performSettingsLaunchAction
{
    [Flurry logEvent:@"Launch Settings"];
    [[NSNotificationCenter defaultCenter] postNotificationName:EFDisplaySettingsNotification object:nil];
}

- (void)performExploreLaunchAction
{
    [Flurry logEvent:@"Launch Explore"];
    [[NSNotificationCenter defaultCenter] postNotificationName:EFDisplayExploreNotification object:nil userInfo:self.options];
}

- (void)performWebLaunchAction
{
    NSString *webURL = [self.options objectForKey:EFWebViewUrlKey defaultValue:nil];
    if (webURL.length) {
        [Flurry logEvent:@"Launch Web View"];
        [[NSNotificationCenter defaultCenter] postNotificationName:EFDisplayWebViewNotification object:nil userInfo:self.options];
    }
}

@end
