//
//  EFWebViewController.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFWebViewController.h"
#import "Flurry.h"
#import "EFExtensions.h"

static NSString * const EFTermsAndConditionsURL = @"http://tapclips.com/legal/termsofservice";
static NSString * const EFPrivacyPolicyURL = @"http://tapclips.com/legal/privacy";

@interface EFWebViewController () <UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView * activityIndicator;
@property (nonatomic, strong) NSURLRequest * initialRequest;

@end

@implementation EFWebViewController

+ (id)instantiateFromStoryboard
{
    return [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"webViewController"];
}

+ (id)instantiateWithNavFromStoryboard
{
    return [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"webNavViewController"];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    _allowRedirect = YES;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - setters
////////////////////////////////////////////////////////////////////////////////
- (void)setUrl:(NSString *)url
{
    if (_url != url) {
        _url = url;
        [self loadWebView];
    }
}

- (void)setTitleString:(NSString *)titleString
{
    if (_titleString != titleString) {
        _titleString = titleString;
        [self updateTitleString];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - View Cycle
//////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadWebView];
}

//////////////////////////////////////////////////////////////
#pragma mark - Setup
//////////////////////////////////////////////////////////////
- (void)loadWebView
{
    self.initialRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.url]];
    [self.webView loadRequest:self.initialRequest];
}

- (void)updateTitleString
{
    self.navigationItem.title = _titleString;
}

//////////////////////////////////////////////////////////////
#pragma mark - UIWebViewDelegate
//////////////////////////////////////////////////////////////
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (self.closeURL.length > 0 && [self.closeURL isEqualToString:request.URL.absoluteString])
        [self dismissViewControllerAnimated:YES completion:nil];
    
    return self.allowRedirect || ([request.URL isEqual:self.initialRequest.URL]);
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [Flurry logError:@"Error Loading WebView" message:error.localizedDescription error:error];
    [self.activityIndicator stopAnimating];
}

//////////////////////////////////////////////////////////////
#pragma mark - Actions
//////////////////////////////////////////////////////////////
- (IBAction)donePressed:(id)sender
{
    if (self.completionBlock) {
        self.completionBlock();
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end


@implementation EFWebViewController (EFCommon)

+ (id)termsAndConditionsViewController
{
    UINavigationController *webVC = [EFWebViewController instantiateWithNavFromStoryboard];
    [(EFWebViewController *)webVC.topViewController setUrl:EFTermsAndConditionsURL];
    [(EFWebViewController *)webVC.topViewController setTitleString:@"Terms of Service"];
    return webVC;
}

+ (id)privacyPolicyViewController
{
    UINavigationController *webVC = [EFWebViewController instantiateWithNavFromStoryboard];
    [(EFWebViewController *)webVC.topViewController setUrl:EFPrivacyPolicyURL];
    [(EFWebViewController *)webVC.topViewController setTitleString:@"Privacy"];
    return webVC;
}

@end