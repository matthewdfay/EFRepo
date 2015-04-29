//
//  EFAppDelegate.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/19/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFAppDelegate.h"
#import "EFRootViewController.h"
#import "TestFlight.h"
#import "EFUser.h"
#import "EFMediaManager.h"
#import "EFSettingsManager.h"
#import "EFCachingManager.h"
#import "EFLocationManager.h"
#import "EFCameraManager.h"
#import "EFAPIClient.h"
#import "EFProtocolLauncher.h"
#import "EFExtensions.h"
#import "Flurry.h"
#import <FacebookSDK/FacebookSDK.h>

NSString * const EFPushTokenKey = @"com.elementalfoundry.tap-clips.push-token";

@interface EFAppDelegate ()
@property (nonatomic, strong) NSString *pushToken;
@end

@implementation EFAppDelegate

+ (EFRootViewController *)rootViewController
{
    return (EFRootViewController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [UIApplication setApplicationLaunchDate:[NSDate date]];
    [UIApplication setApplicationForegroundDate:[NSDate date]];
    [[UITableViewCell appearance] setBackgroundColor:[UIColor clearColor]];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if DEBUG
    [TestFlight takeOff:@"f8acbcf2-921c-43e3-a4ee-bf6bd83d71a0"];
#else
    [Flurry setCrashReportingEnabled:YES];
    [Flurry startSession:@"4RK8T9HNV9RCQ836HX2F"];
#endif
    
    [self checkIfApplicationWasLaunchedFromNotification:launchOptions];
    [EFMediaManager sharedManager];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    [EFCachingManager writeCacheToDisk];
    if ([EFLocationManager locationServicesHasBeenApproved]) {
        [[EFLocationManager sharedManager] stopUpdatingCurrentLocation];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[EFCameraManager sharedManager] resetCamera];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [UIApplication setApplicationForegroundDate:[NSDate date]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[UIApplication sharedApplication ] setIdleTimerDisabled:YES];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    if (![EFLocationManager locationServicesHasBeenApproved]) {
        [[EFLocationManager sharedManager] updateCurrentLocationIfPossible:nil];
    }
    
    if (![[EFUser currentUser] shareURL].length) {
        [[EFUser currentUser] fetchNewShareDictionaryWithCallback:nil];
    }
    
    [[EFSettingsManager sharedManager] updateSettings];
    [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    [FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [FBSession.activeSession close];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    EFProtocolLauncher *launcher = [[EFProtocolLauncher alloc] initWithProtocol:url referringApplication:sourceApplication];
    if ([launcher isValidProtocol]) {
        [launcher performProtocolAction];
        return YES;
    } else {
        return [FBSession.activeSession handleOpenURL:url];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Notifications
//////////////////////////////////////////////////////////////
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *deviceTokenString = [deviceToken description];
    [[NSUserDefaults standardUserDefaults] setObject:deviceTokenString forKey:EFPushTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (!self.pushToken.length || ![self.pushToken isEqualToString:deviceTokenString]) {
        self.pushToken = deviceTokenString;
        [[EFAPIClient sharedClient] trackDevicePushToken:deviceTokenString success:^(BOOL wasSuccessful, id response, id cache) {
            if (wasSuccessful) {
                [[NSUserDefaults standardUserDefaults] setObject:deviceTokenString forKey:EFPushTokenKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        } failure:^(NSError *error) {
            self.pushToken = nil;
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:EFPushTokenKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [Flurry logError:@"Failed to Track Push Token" message:error.localizedDescription error:error];
        }];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [Flurry logError:@"Application Failed to Register Remote Notification" message:error.localizedDescription error:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if (application.applicationState == UIApplicationStateActive) {
        //TODO: display notification
    } else {
        [self launchApplicationWithRemoteNotificationOptions:userInfo];
    }
}

- (void)checkIfApplicationWasLaunchedFromNotification:(NSDictionary *)launchOptions
{
    NSDictionary *notifications = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notifications) {
        [self launchApplicationWithRemoteNotificationOptions:notifications];
    }
}

- (void)launchApplicationWithRemoteNotificationOptions:(NSDictionary *)options
{
    NSDictionary *notificationDictionary = [options objectForKey:@"payload"];
    NSString *protocol = [notificationDictionary objectForKey:@"url" defaultValue:nil];
    if (protocol.length > 0) {
        EFProtocolLauncher *launcher = [[EFProtocolLauncher alloc] initWithProtocol:[NSURL URLWithString:protocol]];
        if ([launcher isValidProtocol] && [[EFAppDelegate rootViewController] isViewLoaded]) {
            [launcher performProtocolAction];
        } else if ([launcher isValidProtocol] && [[EFAppDelegate rootViewController] isKindOfClass:[EFRootViewController class]]) {
            
        }
    }
}

@end
