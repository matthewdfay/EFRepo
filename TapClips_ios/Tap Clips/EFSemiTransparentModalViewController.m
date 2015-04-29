//
//  EFSemiTransparentModalViewController.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/26/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFSemiTransparentModalViewController.h"
#import "EFSemiTransparentModalView.h"
#import "EFAppDelegate.h"
#import "EFRootViewController.h"
#import "EFExtensions.h"

static UIWindow *modalPresentationWindow = nil;
static NSInteger EFModalBorders = 40;

@interface EFSemiTransparentModalViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UIView *closeButton;
@property (nonatomic, weak) IBOutlet UIView *containerView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *containerHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *containerWidthConstraint;

@property (nonatomic, strong) EFSemiTransparentModalView *contentView;
@property (nonatomic, assign) BOOL isFullScreen;

@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, assign) BOOL enableBackgroundDismiss;
@property (nonatomic) NSInteger currentKeyboardHeight;

@end

@implementation EFSemiTransparentModalViewController

- (void)setContentView:(EFSemiTransparentModalView *)contentView
{
    if (_contentView != contentView) {
        [_contentView removeFromSuperview];
        _contentView = contentView;
        [self updateContentView];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Present
//////////////////////////////////////////////////////////////
+ (void)presentWithView:(EFSemiTransparentModalView *)view
{
    [[EFAppDelegate rootViewController] dismissKeyboard];
    EFSemiTransparentModalViewController *modal = [EFSemiTransparentModalViewController instantiateFromStoryboard];
    modal.contentView = view;
    modal.enableBackgroundDismiss = YES;
    [EFSemiTransparentModalViewController presentFromWindow:modal];
}

+ (void)presentWithModalView:(EFSemiTransparentModalView *)view
{
    [[EFAppDelegate rootViewController] dismissKeyboard];
    EFSemiTransparentModalViewController *modal = [EFSemiTransparentModalViewController instantiateFromStoryboard];
    modal.contentView = view;
    modal.enableBackgroundDismiss = NO;
    [EFSemiTransparentModalViewController presentFromWindow:modal];
}

+ (void)presentFromWindow:(UIViewController *)viewControllerToPresent
{
    modalPresentationWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    modalPresentationWindow.windowLevel = UIWindowLevelStatusBar;
    modalPresentationWindow.rootViewController = viewControllerToPresent;
    modalPresentationWindow.backgroundColor = [UIColor clearColor];
    [modalPresentationWindow makeKeyAndVisible];
}

+ (EFSemiTransparentModalViewController *)instantiateFromStoryboard
{
    return [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"semiTransparentViewController"];
}

//////////////////////////////////////////////////////////////
#pragma mark - Dismiss
//////////////////////////////////////////////////////////////
+ (void)dismiss
{
    if (modalPresentationWindow) {
        [modalPresentationWindow.rootViewController.view endEditing:YES];
        [self windowWillDismiss:modalPresentationWindow];
    }
}

+ (void)windowWillDismiss:(UIWindow *)window
{
    EFSemiTransparentModalViewController *controller = (EFSemiTransparentModalViewController *)window.rootViewController;
    [controller willBeRemovedByModalWindowDismissing];
}

- (void)willBeRemovedByModalWindowDismissing
{
    [self cleanupOnDisappear];
    [self animateViewOut];
}

- (void)cleanupOnDisappear
{
    [self.contentView viewWillDismiss];
}

- (IBAction)handleBackgroundTap:(id)sender {
    if (self.enableBackgroundDismiss) {
        [[self class] dismiss];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - View Lifecycle
//////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.currentKeyboardHeight = 0;
    [self installTapGesture];
    [self updateContentView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self prepareViewForAppearanceAnimation];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self animateViewIntoPlace];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (!modalPresentationWindow.rootViewController.presentedViewController) {
        [self animateViewOut];
        [self cleanupOnDisappear];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - initial setup
//////////////////////////////////////////////////////////////
- (void)installTapGesture
{
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundTap:)];
    self.tap.delegate = self;
    [self.view addGestureRecognizer:self.tap];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self.view];
    return !CGRectContainsPoint(self.containerView.frame, location);
}

//////////////////////////////////////////////////////////////
#pragma mark - Updating Views
//////////////////////////////////////////////////////////////
+ (void)animateToPreferredSize
{
    if (modalPresentationWindow) {
        EFSemiTransparentModalViewController *controller = (EFSemiTransparentModalViewController *)modalPresentationWindow.rootViewController;
        CGSize preferredSize = [controller.contentView preferredSize];
        NSInteger maxHeight = [controller currentMaxHeight];
        
        controller.containerHeightConstraint.constant = ((preferredSize.height <= maxHeight) ? preferredSize.height : maxHeight);
        controller.containerWidthConstraint.constant = preferredSize.width;
        [controller.containerView setNeedsUpdateConstraints];
        
        [UIView animateWithDuration:0.25f animations:^{
            [controller.containerView layoutIfNeeded];
        }];
    }
}

- (void)updateContentView
{
    if (self.isViewLoaded && self.contentView) {
        [self.contentView removeFromSuperview];
        [self.containerView addSubview:self.contentView];
        [self updateContentViewConstraints];
        [self updateContainerViewWithContentViewControllerPreferredSize];
        if (self.enableBackgroundDismiss) {
            self.closeButton.hidden = NO;
            [self.closeButton.superview bringSubviewToFront:self.closeButton];
        } else {
            self.closeButton.hidden = YES;
        }
    }
}

- (void)updateContentViewConstraints
{
    NSLayoutConstraint *topConstraint =
    [NSLayoutConstraint constraintWithItem:self.contentView
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.self.containerView
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                  constant:0.0];
    [self.containerView addConstraint:topConstraint];
    
    NSLayoutConstraint *leftConstraint =
    [NSLayoutConstraint constraintWithItem:self.contentView
                                 attribute:NSLayoutAttributeLeft
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.self.containerView
                                 attribute:NSLayoutAttributeLeft
                                multiplier:1.0
                                  constant:0.0];
    [self.containerView addConstraint:leftConstraint];
    
    NSLayoutConstraint *rightConstraint =
    [NSLayoutConstraint constraintWithItem:self.contentView
                                 attribute:NSLayoutAttributeRight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.self.containerView
                                 attribute:NSLayoutAttributeRight
                                multiplier:1.0
                                  constant:0.0];
    [self.containerView addConstraint:rightConstraint];
    
    NSLayoutConstraint *bottomConstraint =
    [NSLayoutConstraint constraintWithItem:self.contentView
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.self.containerView
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                  constant:0.0];
    [self.containerView addConstraint:bottomConstraint];
}

- (void)updateContainerViewWithContentViewControllerPreferredSize
{
    if (!self.contentView) return;
    
    [self.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.contentView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    CGSize preferredSize = [self.contentView preferredSize];
    NSInteger maxHeight = [self currentMaxHeight];
    
    self.containerHeightConstraint.constant = ((preferredSize.height <= maxHeight) ? preferredSize.height : maxHeight);
    self.containerWidthConstraint.constant = preferredSize.width;
}

- (NSInteger)currentMaxHeight
{
    NSInteger maxHeight = self.view.bounds.size.height - (self.isFullScreen ? 0 : EFModalBorders);
    maxHeight -= self.currentKeyboardHeight;
    return maxHeight;
}

//////////////////////////////////////////////////////////////
#pragma mark - Appearance Animations
//////////////////////////////////////////////////////////////
- (void)prepareViewForAppearanceAnimation
{
    self.containerView.alpha = 0.0;
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)animateViewIntoPlace
{
    [self performFirstStageOfEntryAnimation];
}

- (void)performFirstStageOfEntryAnimation
{
    self.containerView.transform = CGAffineTransformMakeScale(0.1, 0.1);
    
    [UIView animateWithDuration:0.2 animations:^{
        self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        self.containerView.transform = CGAffineTransformMakeScale(1.06, 1.06);
        self.containerView.alpha = 1.0;
    } completion:^(BOOL finished) {
        [self performSecondStageOfEntryAnimation];
    }];
}

- (void)performSecondStageOfEntryAnimation
{
    [UIView animateWithDuration:0.2 animations:^{
        self.containerView.transform = CGAffineTransformIdentity;
    }];
}

//////////////////////////////////////////////////////////////
#pragma mark - Exit Animations
//////////////////////////////////////////////////////////////
- (void)animateViewOut
{
    [self performFirstStageOfExitAnimation];
}

- (void)performFirstStageOfExitAnimation
{
    [UIView animateWithDuration:0.15 animations:^{
        self.containerView.transform = CGAffineTransformMakeScale(1.06, 1.06);
    } completion:^(BOOL finished) {
        [self performSecondStageOfExitAnimation];
    }];
}

- (void)performSecondStageOfExitAnimation
{
    [UIView animateWithDuration:0.15 animations:^{
        self.view.backgroundColor = [UIColor clearColor];
        self.containerView.transform = CGAffineTransformMakeScale(0.1, 0.1);
        self.containerView.alpha = 0.0;
    } completion:^(BOOL finished) {
        modalPresentationWindow = nil;
    }];
}

@end
