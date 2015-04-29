//
//  EFWebViewController.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^EFWebViewCallback)(void);

@interface EFWebViewController : UIViewController

/**
 Returns an instance of EFWebViewController.
 
 NOTE: instantiateWithNavFromStoryboard returns a UINavigationController
 with EFWebViewController as it's topViewController.
 */
+ (id)instantiateFromStoryboard;
+ (id)instantiateWithNavFromStoryboard;

/**
 the url for the webview
 when set, automatically starts loading the webview
 */
@property (nonatomic, weak) NSString * url;

/**
 the url that, if redirected to, should attempt to close the modal
 when set, attempts to close the modal containing the EFWebViewController
 */
@property (nonatomic, strong) NSString * closeURL;

/**
 the title of the webview
 when set, automatically displays the title in the navBar
 */
@property (nonatomic, strong) NSString *titleString;

/**
 specifies if the webview allows redirecting
 
 Note: default value is YES
 */
@property (nonatomic) BOOL allowRedirect;

/**
 access to the webView being displayed.
 */
@property (nonatomic, weak, readonly) UIWebView *webView;

/**
 Callback that gets called when the webview is Dismissed.
 */
@property (nonatomic, strong) EFWebViewCallback completionBlock;

@end

@interface EFWebViewController (EFCommon)

+ (id)termsAndConditionsViewController;

+ (id)privacyPolicyViewController;

@end
