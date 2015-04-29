//
//  EFExploreViewController.m
//  TapClips
//
//  Created by Matthew Fay on 5/27/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFExploreViewController.h"
#import "EFSettingsManager.h"
#import "EFAPIClient.h"
#import "EFUser.h"
#import "EFExtensions.h"
#import "Flurry.h"

@interface EFAPIClient (EFExploreViewController)
- (NSString *)sessionToken;
@end

@interface EFExploreViewController () <UIWebViewDelegate>
@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView * activityIndicator;
@property (nonatomic, strong) NSURLRequest * initialRequest;
@end

@implementation EFExploreViewController

+ (EFExploreViewController *)exploreViewControllerWithDelegate:(id<EFDrawerViewControllerDelegate>)delegate
{
    EFExploreViewController *vc = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"exploreViewController"];
    vc.url = [[EFSettingsManager sharedManager] exploreURL];
    vc.delegate = delegate;
    return vc;
}

- (void)setUrl:(NSString *)url
{
    if (_url != url) {
        _url = [NSString stringWithFormat:@"%@?id=%@&t=%@", url, [[[EFUser currentUser] userId] urlEncode], [[[EFAPIClient sharedClient] sessionToken] urlEncode]];
        [self loadWebView];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadWebView];
    self.webView.alpha = 0.0;
}

- (void)loadWebView
{
    self.initialRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.url]];
    [self.webView loadRequest:self.initialRequest];
}

- (void)reloadExplore
{
    self.webView.alpha = 0.0;
    [self.webView reload];
}

//////////////////////////////////////////////////////////////
#pragma mark - UIWebViewDelegate
//////////////////////////////////////////////////////////////
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityIndicator stopAnimating];
    [UIView animateWithDuration:0.2 animations:^{
        self.webView.alpha = 1.0;
    }];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.activityIndicator stopAnimating];
}

//////////////////////////////////////////////////////////////
#pragma mark - Actions
//////////////////////////////////////////////////////////////
- (IBAction)cameraPressed:(id)sender
{
    [Flurry logEvent:@"Drawer Closed By Camera Button Explore"];
    if (self.delegate) {
        [self.delegate dismissDrawer];
    }
}

@end
