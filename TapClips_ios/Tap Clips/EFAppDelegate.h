//
//  EFAppDelegate.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/19/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const EFPushTokenKey;

@class EFRootViewController;

@interface EFAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (EFRootViewController *)rootViewController;

@end
