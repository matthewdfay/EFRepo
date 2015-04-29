//
//  EFViewController.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/19/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFRootViewController.h"
#import "EFSettingsViewController.h"
#import "EFVideosViewController.h"
#import "EFExploreViewController.h"
#import "EFDrawerViewController.h"
#import "EFVideoDetailViewController.h"
#import "EFTermsAndConditionsViewController.h"
#import "EFWebViewController.h"
#import "EFPostingCompleteView.h"
#import "EFVideoPreviewView.h"
#import "EFSemiTransparentModalViewController.h"
#import "EFTimeSliderView.h"
#import "EFTimeTrackingView.h"
#import "EFZoomView.h"
#import "EFRotationView.h"
#import "EFOnboardingView.h"
#import "EFWindowPresenter.h"
#import "EFCameraManager.h"
#import "EFUploadManager.h"
#import "EFMediaManager.h"
#import "EFOnboardingManager.h"
#import "EFProtocolLauncher.h"
#import "EFUser.h"
#import "EFAPIClient.h"
#import "GPUImage.h"
#import "EFExtensions.h"
#import "Flurry.h"

NSString * const EFDisplaySettingsNotification = @"EFDisplaySettings";
NSString * const EFDisplayVideosNotification = @"EFDisplayVideos";
NSString * const EFDisplayExploreNotification = @"EFDisplayExplore";
NSString * const EFDisplayWebViewNotification = @"EFDisplayWebView";
NSString * const EFWebViewUrlKey = @"url";
NSString * const EFWebViewTitleKey = @"title";
NSString * const EFWebViewTokenKey = @"token";
NSString * const EFWebViewExternalKey = @"external";

static NSInteger const EFClosedDrawerWidthIpad = 100;
static NSInteger const EFClosedDrawerWidthIphone = 70;

@interface EFAPIClient (EFRootViewController)
- (NSString *)sessionToken;
@end

@interface EFRootViewController () <UIDynamicAnimatorDelegate, EFDrawerViewControllerDelegate, EFVideoDetailViewControllerDelegate, EFTimeSliderViewDelegate, EFZoomViewDelegate, EFVideoPreviewViewDelegate, EFTermsAndConditionsViewControllerDelegate, EFOnboardingManagerDelegate>
@property (nonatomic, strong) GPUImageView *cameraView;
@property (nonatomic, weak) IBOutlet UIButton *settingsButton;
@property (nonatomic, weak) IBOutlet UIButton *videoContainerButton;
@property (nonatomic, weak) IBOutlet UIButton *exploreButton;
@property (nonatomic, weak) IBOutlet EFZoomView *zoomView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *uploadingView;
@property (nonatomic, weak) IBOutlet UIView *liveView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *onboardingTopConstraint;
@property (nonatomic, weak) IBOutlet EFOnboardingView *onboardingView;
@property (nonatomic, assign) BOOL onboardingDisplayed;

@property (nonatomic, assign) BOOL isInitialOverlayShowing;
@property (nonatomic, assign) BOOL isVideoDetailShowing;
@property (nonatomic, assign) BOOL isWebViewDisplayed;

@property (nonatomic, strong) EFSettingsViewController *settingsViewController;
@property (nonatomic, strong) EFVideosViewController *videosViewController;
@property (nonatomic, strong) EFExploreViewController *exploreViewController;

@property (nonatomic, strong) EFVideoPreviewView *previewView;
@property (nonatomic, strong) NSTimer *previewTimer;

@property (nonatomic, strong) EFRotationView *rotationView;
@property (nonatomic, assign) BOOL isRotationDisplayed;

//Drawer
@property (nonatomic, assign) BOOL hasDoneInitialLayout;
@property (nonatomic, assign) BOOL isDrawerOpen;
@property (nonatomic, weak) IBOutlet UIView *drawerContainerView;
@property (nonatomic, weak) IBOutlet UIView *drawerContentView;
@property (nonatomic, strong) UIViewController *drawerViewController;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *drawerContainerOriginXConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *drawerContainerWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *drawerContainerTrailingConstraint;

@property (nonatomic, strong) EFProtocolLauncher *launcher;

@property (nonatomic, weak, readwrite) UIWebView *activeWebView;
@end

@implementation EFRootViewController {
    UIDynamicAnimator* _animator;
    UIGravityBehavior* _gravity;
    UICollisionBehavior* _collision;
}

- (void)setPreviewTimer:(NSTimer *)previewTimer
{
    if (_previewTimer != previewTimer) {
        [_previewTimer invalidate];
        _previewTimer = previewTimer;
    }
}

- (EFRotationView *)rotationView
{
    if (!_rotationView) {
        _rotationView = [EFRotationView rotationView];
    }
    return _rotationView;
}

- (void)dismissKeyboard
{
    [self.view endEditing:YES];
}

- (NSInteger)closedDrawerWidth
{
    if (EF_IS_IPAD) {
        return EFClosedDrawerWidthIpad;
    } else {
        return EFClosedDrawerWidthIphone;
    }
}

- (EFSettingsViewController *)settingsViewController
{
    if (!_settingsViewController) {
        _settingsViewController = [EFSettingsViewController settingsViewControllerWithDelegate:self];
    }
    return _settingsViewController;
}

- (EFVideosViewController *)videosViewController
{
    if (!_videosViewController) {
        _videosViewController = [EFVideosViewController videosViewControllerWithDelegate:self];
        _videosViewController.delegate = self;
    }
    return _videosViewController;
}

- (EFExploreViewController *)exploreViewController
{
    if (!_exploreViewController) {
        _exploreViewController = [EFExploreViewController exploreViewControllerWithDelegate:self];
    }
    return _exploreViewController;
}

- (void)setDrawerViewController:(UIViewController *)drawerViewController
{
    if (_drawerViewController != drawerViewController) {
        [self replaceViewController:_drawerViewController withViewController:drawerViewController];
        _drawerViewController = drawerViewController;
        [self updateCurrentDrawerView];
        [self updateActiveWebView:_drawerViewController];
    }
}

- (void)updateCurrentDrawerView
{
    if (self.isViewLoaded && self.drawerViewController) {
        [self.drawerViewController.view removeFromSuperview];
        self.drawerViewController.view.frame = self.drawerContentView.bounds;
        [self.drawerContentView addSubview:self.drawerViewController.view];
        
        [self.drawerViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.drawerViewController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.drawerContentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        [self.drawerContentView addConstraint:topConstraint];
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.drawerViewController.view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.drawerContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
        [self.drawerContentView addConstraint:rightConstraint];
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.drawerViewController.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.drawerContentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        [self.drawerContentView addConstraint:bottomConstraint];
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.drawerViewController.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.drawerContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
        [self.drawerContentView addConstraint:leftConstraint];
    }
}

- (void)updateActiveWebView:(UIViewController *)controller
{
    if (controller && [controller isKindOfClass:[EFExploreViewController class]]) {
        self.activeWebView = ((EFExploreViewController *)controller).webView;
    } else if (controller && [controller isKindOfClass:[EFWebViewController class]]) {
        self.activeWebView = ((EFWebViewController *)controller).webView;
    } else {
        self.activeWebView = nil;
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Launch
//////////////////////////////////////////////////////////////
- (void)performProtocolAfterLoading:(EFProtocolLauncher *)launcher
{
    self.launcher = launcher;
}

- (void)useLauncherIfAvailable
{
    if (self.launcher && [self.launcher isValidProtocol]) {
        [self.launcher performProtocolAction];
        self.launcher = nil;
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - View Cycle
//////////////////////////////////////////////////////////////
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.onboardingView updateViewMaxLayoutWidth];
    [self.view layoutSubviews];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupCameraView];
	[self setupTapGesture];
    [self beginListeningForNotifications];
    [self useLauncherIfAvailable];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self displayInitialOverlay];
    [self startRecordingIfPossible];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.drawerContainerTrailingConstraint) {
        self.drawerContainerOriginXConstraint.constant = self.drawerContainerView.frame.origin.x;
        [self.view removeConstraint:self.drawerContainerTrailingConstraint];
        self.drawerContainerTrailingConstraint = nil;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self memoryWarningHappened];
}

- (void)memoryWarningHappened
{
    if (self.drawerViewController != _settingsViewController) {
        self.settingsViewController = nil;
    }
    if (self.drawerViewController != _videosViewController) {
        self.videosViewController = nil;
    }
    if (self.drawerViewController != _exploreViewController) {
        self.exploreViewController = nil;
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Rotation
//////////////////////////////////////////////////////////////
- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [[EFCameraManager sharedManager] updateVideoOrientation:toInterfaceOrientation];
    [self hideRotationViewWithDuration:duration];
}

- (void)handleOrientationDidChange:(NSNotification *)notification
{
    if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait &&
        !self.isVideoDetailShowing && !self.isInitialOverlayShowing) {
        [self displayRotationViewWithDuration:0.2];
    } else if (self.isRotationDisplayed) {
        [self hideRotationViewWithDuration:0.2];
    }
}

- (void)updateRotationViewConstraints
{
    [self.rotationView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.rotationView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    [self.view addConstraint:topConstraint];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.rotationView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
    [self.view addConstraint:rightConstraint];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.rotationView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [self.view addConstraint:bottomConstraint];
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.rotationView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    [self.view addConstraint:leftConstraint];
}

- (void)hideRotationViewWithDuration:(CGFloat)duration
{
    if (self.isRotationDisplayed) {
        self.isRotationDisplayed = NO;
        [Flurry logEvent:@"Rotation View Hidden"];
        [UIView animateWithDuration:duration animations:^{
            self.rotationView.alpha = 0.0;
            [self displayCorrectIcons];
        } completion:^(BOOL finished) {
            if (!self.isRotationDisplayed) {
                [self.rotationView removeFromSuperview];
                [self startRecordingIfPossible];
            }
        }];
    }
}

- (void)displayRotationViewWithDuration:(CGFloat)duration
{
    if (!self.isRotationDisplayed) {
        self.isRotationDisplayed = YES;
        [Flurry logEvent:@"Rotation View Displayed"];
        [self.view.layer removeAllAnimations];
        [self stopRecording];
        self.rotationView.alpha = 0.0;
        [self.rotationView setInterfaceOrientation:self.interfaceOrientation];
        [self.rotationView removeFromSuperview];
        [self.view addSubview:self.rotationView];
        [self updateRotationViewConstraints];
        [UIView animateWithDuration:duration animations:^{
            self.rotationView.alpha = 1.0;
            [self hideAllIcons];
        }];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Recording Helpers
//////////////////////////////////////////////////////////////
- (BOOL)shouldStartRecording
{
    return (!self.isDrawerOpen && !self.isInitialOverlayShowing && !self.isRotationDisplayed && !self.isVideoDetailShowing && !self.isWebViewDisplayed && [[EFCameraManager sharedManager] isCameraStarted]);
}

- (void)startRecordingIfPossible
{
    if ([self shouldStartRecording]) {
        [self startRecording];
    } /*else {
        NSLog(@"drawer = %d initialOverlay = %d rotation = %d videoDetail = %d cameraStarted = %d", self.isDrawerOpen, self.isInitialOverlayShowing, self.isRotationDisplayed, self.isVideoDetailShowing, ![[EFCameraManager sharedManager] isCameraStarted]);
    }*/
}

- (void)startRecording
{
    [[EFCameraManager sharedManager] removeBlurFromOutputView];
    [[EFCameraManager sharedManager] startRecording];
}

- (void)stopRecording
{
    [[EFCameraManager sharedManager] stopRecording];
    [[EFCameraManager sharedManager] blurOutputView];
}

//////////////////////////////////////////////////////////////
#pragma mark - Setup
//////////////////////////////////////////////////////////////
- (void)setupCameraView
{
    if (!self.cameraView) {
        self.cameraView = [[EFCameraManager sharedManager] outputView];
        [self.cameraView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view insertSubview:self.cameraView atIndex:0];
        
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.cameraView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        [self.view addConstraint:topConstraint];
        
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.cameraView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
        [self.view addConstraint:leftConstraint];
        
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.cameraView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
        [self.view addConstraint:rightConstraint];
        
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.cameraView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        [self.view addConstraint:bottomConstraint];
    }
}

- (void)setupTapGesture
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTap:)];
    [self.cameraView addGestureRecognizer:tap];
}

//////////////////////////////////////////////////////////////
#pragma mark - Notifications
//////////////////////////////////////////////////////////////
- (void)beginListeningForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationBecameActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startUploading:) name:EFVideoBeganUplaodingToAPINotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedPosting:) name:EFVideoPostedToAPINotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bufferChanged:) name:EFCurrentVideoBufferChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displaySettings:) name:EFDisplaySettingsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayVideos:) name:EFDisplayVideosNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exploreNotification:) name:EFDisplayExploreNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayModalWebView:) name:EFDisplayWebViewNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayCameraRollCompletion:) name:EFMediaManagerSavedToCameraRollNotification object:nil];
}

- (void)stopListeningForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationBecameActive:(NSNotification *)note
{
    [[EFCameraManager sharedManager] startCamera];
    if ([self shouldStartRecording]) {
        [self startRecordingIfPossible];
    } else {
        [self stopRecording];
    }
}

- (void)startUploading:(NSNotification *)note
{
    [self.uploadingView startAnimating];
    self.uploadingView.hidden = NO;
}

- (void)finishedPosting:(NSNotification *)note
{
    [self.uploadingView stopAnimating];
    NSNumber *wasSuccessful = [[note userInfo] objectForKey:EFVideoPostedToAPIWasSuccessfulKey];
    NSString *message = [[note userInfo] objectForKey:EFVideoPostedToAPIMessageKey defaultValue:nil];
    EFPostingCompleteView *posted = [EFPostingCompleteView postingComplete:wasSuccessful.boolValue withMessage:message];
    [EFSemiTransparentModalViewController presentWithView:posted];
}

- (void)exploreNotification:(NSNotification *)note
{
    if ([note.userInfo objectForKey:EFWebViewUrlKey defaultValue:nil]) {
        self.exploreViewController.url = [note.userInfo objectForKey:EFWebViewUrlKey defaultValue:nil];
    } else {
        [self.exploreViewController reloadExplore];
    }
    [self displayExplore:nil];
}

- (void)displayModalWebView:(NSNotification *)note
{
    NSString *webURL = [note.userInfo objectForKey:EFWebViewUrlKey defaultValue:@""];
    if (((NSNumber *)[note.userInfo objectForKey:EFWebViewTokenKey defaultValue:@NO]).boolValue) {
        webURL = [webURL stringByAppendingFormat:@"&id=%@&t=%@", [[[EFUser currentUser] userId] urlEncode], [[[EFAPIClient sharedClient] sessionToken] urlEncode]];
    }
    NSNumber *external = [note.userInfo objectForKey:EFWebViewExternalKey defaultValue:@NO];
    if (external.boolValue) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:webURL]];
    } else {
        self.isWebViewDisplayed = YES;
        self.isVideoDetailShowing = NO;
        [EFWindowPresenter dismiss];
        [self stopRecording];
        UINavigationController *webVC = [EFWebViewController instantiateWithNavFromStoryboard];
        ((EFWebViewController *)webVC.topViewController).url = webURL;
        ((EFWebViewController *)webVC.topViewController).titleString = [note.userInfo objectForKey:EFWebViewTitleKey defaultValue:@""];
        ((EFWebViewController *)webVC.topViewController).completionBlock = ^{
            self.isWebViewDisplayed = NO;
            [self displayCorrectIcons];
            [self startRecordingIfPossible];
        };
        [self presentViewController:webVC animated:YES completion:^{
            [self updateActiveWebView:webVC.topViewController];
        }];
    }
}

- (void)displayCameraRollCompletion:(NSNotification *)note
{
    NSNumber *wasSuccessful = [note.userInfo objectForKey:EFMediaManagerSaveWasSuccessfulKey defaultValue:@NO];
    EFPostingCompleteView *postingCompleteView = [EFPostingCompleteView cameraRollSaved:wasSuccessful.boolValue];
    [EFSemiTransparentModalViewController presentWithView:postingCompleteView];
}

//////////////////////////////////////////////////////////////
#pragma mark - User Input
//////////////////////////////////////////////////////////////
- (void)userTap:(UITapGestureRecognizer *)tap
{
    if (!self.isDrawerOpen && [[EFCameraManager sharedManager] canCaptureVideo]) {
        NSNumber *approxLength = [[EFCameraManager sharedManager] aproximateLengthOfVideoIfTaken];
        [Flurry logEvent:@"Video Captured" withParameters:@{@"duration": [[EFCameraManager sharedManager] clipDuration], @"actualDuration": approxLength}];
        [[EFOnboardingManager sharedManager] clipCreatedWithDuration:approxLength];
        EFVideoPreviewView *capturePreview = [self displaySavingPreview];
        [[EFCameraManager sharedManager] captureVideo:^(BOOL wasSuccessful, AVURLAsset *asset) {
            if (wasSuccessful && asset) {
                [self updatePreview:capturePreview withAsset:asset];
            } else {
                [Flurry logError:@"Error saving clip" message:nil error:nil];
                [self updatePreviewWithError:capturePreview];
            }
        }];
        [self displayFlash];
    } else if (self.isDrawerOpen) {
        [Flurry logEvent:@"Drawer Closed By Background Tap"];
        [self toggleDrawerAnimated:YES];
    }
}

- (void)displayFlash
{
    UIView *flashView = [[UIView alloc] initWithFrame:self.view.bounds];
    flashView.backgroundColor = [UIColor whiteColor];
    flashView.alpha = 0.9f;
    [[EFCameraManager sharedManager].outputView addSubview:flashView];
    
    // Fade it out and remove after animation.
    [UIView animateWithDuration:0.5f animations:^{
        flashView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [flashView removeFromSuperview];
    }];
}

//////////////////////////////////////////////////////////////
#pragma mark - Asset Preview
//////////////////////////////////////////////////////////////
- (EFVideoPreviewView *)displaySavingPreview
{
    self.previewTimer = nil;
    __block EFVideoPreviewView *previewView = [EFVideoPreviewView videoPreviewView];
    __block EFVideoPreviewView *oldPreviewView = self.previewView;
    previewView.delegate = self;
    previewView.frame = CGRectMake(self.view.bounds.size.width, (self.view.bounds.size.height - previewView.frame.size.height - 10), previewView.frame.size.width, previewView.frame.size.height);
    
    [self.view insertSubview:previewView belowSubview:self.drawerContainerView];
    [previewView scrollToVideoPreviewAnimated:NO];
    
    [UIView animateWithDuration:0.3 animations:^{
        previewView.frame = CGRectMake((previewView.frame.origin.x - previewView.frame.size.width), previewView.frame.origin.y, previewView.frame.size.width, previewView.frame.size.height);
        if (oldPreviewView) {
            oldPreviewView.frame = CGRectMake(self.view.bounds.size.width, oldPreviewView.frame.origin.y, oldPreviewView.frame.size.width, oldPreviewView.frame.size.height);
            oldPreviewView.alpha = 0.0;
        }
    } completion:^(BOOL finished) {
        [oldPreviewView removeFromSuperview];
        oldPreviewView = nil;
        self.previewView = previewView;
    }];
    return previewView;
}

- (void)updatePreview:(EFVideoPreviewView *)view withAsset:(AVURLAsset *)asset
{
    if (view && view.superview) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [view updatePreviewWithAsset:asset animated:YES];
            [self startPreviewTimer];
        });
    }
}

- (void)updatePreviewWithError:(EFVideoPreviewView *)view
{
    if (view && view.superview) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [view updatePreviewWithError];
            [self startPreviewTimer];
        });
    }
}

- (void)startPreviewTimer
{
    self.previewTimer = [NSTimer scheduledTimerWithTimeInterval:8.0 target:self selector:@selector(dismissPreviewFromTimer:) userInfo:nil repeats:NO];
}

- (void)dismissPreviewFromTimer:(NSTimer *)timer
{
    [self dismissPreviewAnimated:YES];
}

- (void)dismissPreviewAnimated:(BOOL)animated
{
    self.previewTimer = nil;
    [UIView animateWithDuration:0.2 animations:^{
        self.previewView.frame = CGRectMake(self.view.bounds.size.width, self.previewView.frame.origin.y, self.previewView.frame.size.width, self.previewView.frame.size.height);
        self.previewView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.previewView removeFromSuperview];
        self.previewView = nil;
    }];
}

- (void)previewInteractionStarted
{
    self.previewTimer = nil;
}

- (void)previewInteractionEnded
{
    self.previewTimer = [NSTimer scheduledTimerWithTimeInterval:6.0 target:self selector:@selector(dismissPreviewFromTimer:) userInfo:nil repeats:NO];
}

- (void)videoWasSelectedForViewing:(AVURLAsset *)asset
{
    [Flurry logEvent:@"Video Preview Selected"];
    [self itemSelectedAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (void)videoWasDismissed
{
    [Flurry logEvent:@"Video Preview User Dismissed"];
    [self dismissPreviewAnimated:NO];
}

//////////////////////////////////////////////////////////////
#pragma mark - EFZoomViewDelegate
//////////////////////////////////////////////////////////////
- (void)zoomValueChanged:(CGFloat)value
{
    [[EFCameraManager sharedManager] updateZoom:value];
}

//////////////////////////////////////////////////////////////
#pragma mark - Buffer Notifications
//////////////////////////////////////////////////////////////
- (void)bufferChanged:(NSNotification *)note
{
    //TODO: blink "Live" text
}

//////////////////////////////////////////////////////////////
#pragma mark - Drawer
//////////////////////////////////////////////////////////////
- (void)dismissDrawer
{
    if (self.isDrawerOpen) {
        [self closeDrawerAnimated:YES];
        [self startRecordingIfPossible];
    }
}

- (IBAction)displaySettings:(id)sender
{
    [self selectSettingsButton];
    [self updateViewControllerInDrawer:self.settingsViewController];
}

- (IBAction)displayVideos:(id)sender
{
    [self selectVideosButton];
    [self updateViewControllerInDrawer:self.videosViewController];
}

- (IBAction)displayExplore:(id)sender
{
    [self selectExploreButton];
    [self updateViewControllerInDrawer:self.exploreViewController];
}

- (void)updateViewControllerInDrawer:(UIViewController *)controller
{
    if (self.isDrawerOpen) {
        if (self.drawerViewController != controller) {
            [self flurryEventSwitchingToDrawer:controller];
            [self replaceDrawerViewController:controller animated:YES];
        } else {
            [self flurryEventClosingDrawerViaButton:controller];
            [self toggleDrawerAnimated:YES];
        }
    } else {
        [self flurryEventOpeningDrawer:controller];
        [self updateDrawerWidthForController:controller];
        controller.view.alpha = 1.0;
        self.drawerViewController = controller;
        [self toggleDrawerAnimated:YES];
    }
}

- (void)toggleDrawerAnimated:(BOOL)animated
{
    if (self.isDrawerOpen) {
        [self closeDrawerAnimated:animated];
        [self startRecordingIfPossible];
    } else {
        [self stopRecording];
        [self openDrawerAnimated:animated];
    }
}

- (void)openDrawerAnimated:(BOOL)animated
{
    self.isDrawerOpen = YES;
    if (EF_IS_IOS7 && animated && NO) {
        [self openDrawerWithGravity];
    } else {
        [self openDrawerNormalAnimated:animated];
    }
}

- (void)openDrawerNormalAnimated:(BOOL)animated
{
    self.drawerContainerOriginXConstraint.constant = (self.cameraView.bounds.size.width - self.drawerContainerWidthConstraint.constant);
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:(animated ? 0.25 : 0.0) animations:^{
        [self.view layoutIfNeeded];
        [self hideAllIconsButDrawer];
    } completion:nil];
}

- (void)closeDrawerAnimated:(BOOL)animated
{
    self.isDrawerOpen = NO;
    [self deselectDrawerButtons];
    if (EF_IS_IOS7 && animated && NO) {
        [self closeDrawerWithGravity];
    } else {
        [self closeDrawerNormalAnimated:animated];
    }
}

- (void)closeDrawerNormalAnimated:(BOOL)animated
{
    self.drawerContainerOriginXConstraint.constant = (self.view.bounds.size.width - [self closedDrawerWidth]);
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:(animated ? 0.25 : 0.0) animations:^{
        [self.view layoutIfNeeded];
        [self displayCorrectIcons];
    } completion:^(BOOL finished) {
        self.drawerViewController = nil;
        [self updateDrawerWidthForController:self.drawerViewController];
    }];
}

- (void)updateDrawerWidthForController:(UIViewController *)viewController
{
    self.drawerContainerWidthConstraint.constant = [self widthForViewController:viewController];
    [self.drawerContainerView setNeedsUpdateConstraints];
    [self.drawerContainerView layoutIfNeeded];
}

- (CGFloat)widthForViewController:(UIViewController *)controller
{
    CGFloat width = [self closedDrawerWidth];
    if (controller) {
        if ([controller isKindOfClass:[EFSettingsViewController class]]) {
            width += 330;
        } else if ([controller isKindOfClass:[EFVideosViewController class]]) {
            width += 330;
        } else if ([controller isKindOfClass:[EFExploreViewController class]]) {
            width = self.cameraView.frame.size.width;
        }
    }
    return width;
}

- (void)replaceDrawerViewController:(UIViewController *)controller animated:(BOOL)animated
{
    CGFloat width = [self widthForViewController:controller];
    if (width > self.drawerContainerWidthConstraint.constant) {
       [self updateDrawerWidthForController:controller];
    }
    self.drawerContainerOriginXConstraint.constant = (self.cameraView.bounds.size.width - width);
    [self.view setNeedsUpdateConstraints];
    controller.view.alpha = 0.0;
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
        self.drawerViewController.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.drawerViewController = controller;
        [self updateDrawerWidthForController:controller];
        [UIView animateWithDuration:0.2 animations:^{
            [self.view layoutIfNeeded];
            self.drawerViewController.view.alpha = 1.0;
        }];
    }];
}

//////////////////////////////////////////////////////////////
#pragma mark - Videos
//////////////////////////////////////////////////////////////
- (void)itemSelectedAtIndexPath:(NSIndexPath *)indexPath
{
    [Flurry logEvent:@"Video Details Displayed"];
    self.isVideoDetailShowing = YES;
    EFVideoDetailViewController *videoDetail = [EFVideoDetailViewController videoDetailViewController];
    videoDetail.initialIndexPath = indexPath;
    videoDetail.delegate = self;
    [EFWindowPresenter presentViewControllerInWindow:videoDetail withAnimationBlock:^{
        [self hideAllIcons];
    } completion:^(BOOL finished) {
        [self dismissPreviewAnimated:NO];
        [self closeDrawerAnimated:NO];
        [self stopRecording];
    }];
}

- (void)videoDetailShouldDismiss
{
    self.isVideoDetailShowing = NO;
    [self startRecordingIfPossible];
    [EFWindowPresenter dismissWithAnimationBlock:^{
        [self displayCorrectIcons];
    } completion:nil];
}

//////////////////////////////////////////////////////////////
#pragma mark - Drawer Buttons
//////////////////////////////////////////////////////////////
- (void)selectSettingsButton
{
    if (self.settingsButton.selected) {
        [self deselectDrawerButtons];
    } else {
        self.videoContainerButton.selected = NO;
        self.settingsButton.selected = YES;
        self.exploreButton.selected = NO;
    }
}

- (void)selectVideosButton
{
    if (self.videoContainerButton.selected) {
        [self deselectDrawerButtons];
    } else {
        self.videoContainerButton.selected = YES;
        self.settingsButton.selected = NO;
        self.exploreButton.selected = NO;
    }
}

- (void)selectExploreButton
{
    if (self.exploreButton.selected) {
        [self deselectDrawerButtons];
    } else {
        self.videoContainerButton.selected = NO;
        self.settingsButton.selected = NO;
        self.exploreButton.selected = YES;
    }
}

- (void)deselectDrawerButtons
{
    self.videoContainerButton.selected = NO;
    self.settingsButton.selected = NO;
    self.exploreButton.selected = NO;
}

//////////////////////////////////////////////////////////////
#pragma mark - Gravity //TODO: come back later
//////////////////////////////////////////////////////////////
- (void)openDrawerWithGravity
{
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    _animator.delegate = self;
    
    _collision = [[UICollisionBehavior alloc] initWithItems:@[self.settingsButton, self.videoContainerButton]];
    [_collision setTranslatesReferenceBoundsIntoBoundaryWithInsets:UIEdgeInsetsMake(0, 250, 0, 0)];
    [_animator addBehavior:_collision];
    
    _gravity = [[UIGravityBehavior alloc] initWithItems:@[self.settingsButton, self.videoContainerButton]];
    _gravity.gravityDirection = CGVectorMake(-1.0f, 0.0f);
    _gravity.magnitude = 2.5;
    [_animator addBehavior:_gravity];
    
    UIDynamicItemBehavior *itemBehaviour = [[UIDynamicItemBehavior alloc] initWithItems:@[self.settingsButton, self.videoContainerButton]];
    itemBehaviour.elasticity = 0.3;
    [_animator addBehavior:itemBehaviour];
}

- (void)closeDrawerWithGravity
{
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    _animator.delegate = self;
    
    _collision = [[UICollisionBehavior alloc] initWithItems:@[self.settingsButton, self.videoContainerButton]];
    [_collision setTranslatesReferenceBoundsIntoBoundaryWithInsets:UIEdgeInsetsMake(0, 0, 0, 10)];
    [_animator addBehavior:_collision];
    
    _gravity = [[UIGravityBehavior alloc] initWithItems:@[self.settingsButton, self.videoContainerButton]];
    _gravity.gravityDirection = CGVectorMake(1.0f, 0.0f);
    _gravity.magnitude = 2.5;
    [_animator addBehavior:_gravity];
    
    UIDynamicItemBehavior *itemBehaviour = [[UIDynamicItemBehavior alloc] initWithItems:@[self.settingsButton, self.videoContainerButton]];
    itemBehaviour.elasticity = 0.3;
    [_animator addBehavior:itemBehaviour];
}

- (void)dynamicAnimatorWillResume:(UIDynamicAnimator*)animator
{
    NSLog(@"resume");
//    if (self.isDrawerOpen) {
//        self.drawerContainerWidthConstraint.constant = 300;
//        [self.drawerContainerView setNeedsUpdateConstraints];
//        [self.drawerContainerView layoutIfNeeded];
//    }
}

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator*)animator
{
    NSLog(@"pause");
//    if (!self.isDrawerOpen) {
//        self.drawerContainerWidthConstraint.constant = 54;
//        [self.drawerContainerView setNeedsUpdateConstraints];
//        [self.drawerContainerView layoutIfNeeded];
//    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Initial Screen
//////////////////////////////////////////////////////////////
- (void)displayInitialOverlay
{
    if ([EFTermsAndConditionsViewController shouldDisplayTermsAndConditionsOverlay]) {
        self.isInitialOverlayShowing = YES;
        [Flurry logEvent:@"Terms Displayed"];
        [self stopRecording];
        [self hideAllIcons];
        EFTermsAndConditionsViewController *termsVC = [EFTermsAndConditionsViewController termsAndConditions];
        termsVC.delegate = self;
        [EFWindowPresenter presentViewControllerInWindow:termsVC withAnimationBlock:nil completion:^(BOOL finished) {
            [self dismissPreviewAnimated:NO];
        }];
    } else {
        [[EFOnboardingManager sharedManager] startOnboardingWithDelegate:self];
    }
}

- (void)termsAndConditionsAccepted
{
    self.isInitialOverlayShowing = NO;
    [Flurry logEvent:@"Terms Accepted"];
    [self startRecordingIfPossible];
    [EFWindowPresenter dismissWithAnimationBlock:^{
        [self displayAllIcons];
    } completion:^(BOOL finished) {
        [[EFOnboardingManager sharedManager] startOnboardingWithDelegate:self];
    }];
}

//////////////////////////////////////////////////////////////
#pragma mark - Onboarding
//////////////////////////////////////////////////////////////
- (void)displayCreateClipOnboardingText:(NSString *)text withIcon:(UIImage *)icon andBackgroundColor:(UIColor *)color
{
    [self displayOnboardingWithText:text icon:icon andBackgroundColor:color completion:nil];
}

- (void)displayCreateClipSucceededOnboardingText:(NSString *)text withIcon:(UIImage *)icon andBackgroundColor:(UIColor *)color
{
    if (self.onboardingDisplayed) {
        [self transitionOnboardingToSuccessWithText:text icon:icon andBackgroundColor:color completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismissOnboardingCompletion:nil];
                [[EFOnboardingManager sharedManager] startOnboardingWithDelegate:self];
            });
        }];
    } else {
        [self displayOnboardingWithText:text icon:icon andBackgroundColor:color completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismissOnboardingCompletion:nil];
                [[EFOnboardingManager sharedManager] startOnboardingWithDelegate:self];
            });
        }];
    }
}

- (void)displayOnboardingWithText:(NSString *)text icon:(UIImage *)icon andBackgroundColor:(UIColor *)bgColor completion:(void (^)(BOOL finished))completion
{
    self.onboardingDisplayed = YES;
    [self.onboardingView setFirstViewTitle:text icon:icon andBackgroundColor:bgColor];
    [self.onboardingView displayFirstView];
    [self.view layoutIfNeeded];

    self.onboardingView.hidden = NO;
    self.onboardingTopConstraint.constant = (EF_IS_IPAD ? 30 : 10);
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    } completion:completion];
}

- (void)transitionOnboardingToSuccessWithText:(NSString *)text icon:(UIImage *)icon andBackgroundColor:(UIColor *)bgColor completion:(void (^)(BOOL finished))completion
{
    [self.onboardingView setSecondViewTitle:text icon:icon andBackgroundColor:bgColor];
    [self.view layoutIfNeeded];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.onboardingView displaySecondView];
        [self.onboardingView hideFirstView];
    } completion:completion];
}

- (void)dismissOnboardingCompletion:(void (^)(BOOL finished))completion
{
    self.onboardingTopConstraint.constant = -(self.onboardingView.frame.size.height + self.onboardingView.frame.origin.y);
    [self.view setNeedsUpdateConstraints];
    [UIView animateWithDuration:0.25 animations:^{
        [self.onboardingView hideFirstView];
        [self.onboardingView hideSecondView];
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.onboardingDisplayed = NO;
        self.onboardingView.hidden = YES;
        [self.onboardingView resetView];
        if (completion) {
            completion (finished);
        }
    }];
}

//////////////////////////////////////////////////////////////
#pragma mark - hide/display
//////////////////////////////////////////////////////////////
- (void)hideAllIcons
{
    self.drawerContainerView.alpha = 0.0;
    self.zoomView.alpha = 0.0;
    self.liveView.alpha = 0.0;
    self.previewView.alpha = 0.0;
    self.onboardingView.alpha = 0.0;
}

- (void)hideAllIconsButDrawer
{
    self.zoomView.alpha = 0.0;
    self.liveView.alpha = 0.0;
    self.previewView.alpha = 0.0;
    self.onboardingView.alpha = 0.0;
}

- (void)displayAllIcons
{
    self.drawerContainerView.alpha = 1.0;
    self.zoomView.alpha = 1.0;
    self.liveView.alpha = 1.0;
    self.onboardingView.alpha = 1.0;
}

- (void)displayOnlyDrawerIcons
{
    self.drawerContainerView.alpha = 1.0;
}

- (void)displayCorrectIcons
{
    if (self.isDrawerOpen) {
        [self displayOnlyDrawerIcons];
    } else if (!self.isVideoDetailShowing) {
        [self displayAllIcons];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Flurry
//////////////////////////////////////////////////////////////
- (void)flurryEventSwitchingToDrawer:(UIViewController *)controller
{
    if ([controller isKindOfClass:[EFSettingsViewController class]]) {
        [Flurry logEvent:@"Drawer switched to Settings"];
    } else if ([controller isKindOfClass:[EFVideosViewController class]]) {
        [Flurry logEvent:@"Drawer switched to Videos"];
    } else if ([controller isKindOfClass:[EFExploreViewController class]]) {
        [Flurry logEvent:@"Drawer switched to Explore"];
    }
}

- (void)flurryEventOpeningDrawer:(UIViewController *)controller
{
    if ([controller isKindOfClass:[EFSettingsViewController class]]) {
        [Flurry logEvent:@"Drawer Opened Settings"];
    } else if ([controller isKindOfClass:[EFVideosViewController class]]) {
        [Flurry logEvent:@"Drawer Opened Videos"];
    } else if ([controller isKindOfClass:[EFExploreViewController class]]) {
        [Flurry logEvent:@"Drawer Opened Explore"];
    }
}

- (void)flurryEventClosingDrawerViaButton:(UIViewController *)controller
{
    if ([controller isKindOfClass:[EFSettingsViewController class]]) {
        [Flurry logEvent:@"Drawer Closed By Button Settings"];
    } else if ([controller isKindOfClass:[EFVideosViewController class]]) {
        [Flurry logEvent:@"Drawer Closed By Button Videos"];
    } else if ([controller isKindOfClass:[EFExploreViewController class]]) {
        [Flurry logEvent:@"Drawer Closed By Button Explore"];
    }
}

@end
