//
//  EFViewController.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/19/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const EFDisplaySettingsNotification;
extern NSString * const EFDisplayVideosNotification;
extern NSString * const EFDisplayExploreNotification;
extern NSString * const EFDisplayWebViewNotification;
extern NSString * const EFWebViewUrlKey;
extern NSString * const EFWebViewTitleKey;
extern NSString * const EFWebViewTokenKey;
extern NSString * const EFWebViewExternalKey;

@interface EFRootViewController : UIViewController

@property (nonatomic, weak, readonly) UIWebView *activeWebView;
- (void)dismissKeyboard;

@end
