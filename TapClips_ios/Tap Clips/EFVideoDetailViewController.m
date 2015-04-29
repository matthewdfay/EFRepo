//
//  EFVideoDetailViewController.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/8/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFVideoDetailViewController.h"
#import "EFShareVideoViewController.h"
#import "EFSendVideoViewController.h"
#import "EFPostingCompleteView.h"
#import "EFSemiTransparentModalViewController.h"
#import "EFVideoDetailCell.h"
#import "EFWindowPresenter.h"
#import "EFMediaManager.h"
#import "EFUploadManager.h"
#import "EFUser.h"
#import "EFExtensions.h"
#import "Flurry.h"

@interface EFVideoDetailViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIAlertViewDelegate, EFShareVideoViewControllerDelegate, EFVideoDetailCellDelegate>
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UIView *barView;
@property (nonatomic, weak) IBOutlet UIButton *cameraButton;
@property (nonatomic, weak) IBOutlet UIButton *deleteButton;
@property (nonatomic, weak) IBOutlet UIButton *shareButton;
@property (nonatomic, weak) IBOutlet UIButton *videoControlButton;

@property (nonatomic, weak) IBOutlet UIView *leftArrowView;
@property (nonatomic, weak) IBOutlet UIView *rightArrowView;

@property (nonatomic, strong) UIViewController *overlayViewController;
@property (nonatomic, assign) BOOL hasDoneInitialLayout;
@end

@implementation EFVideoDetailViewController

- (void)setOverlayViewController:(UIViewController *)overlayViewController
{
    if (_overlayViewController != overlayViewController) {
        [self replaceViewController:_overlayViewController withViewController:overlayViewController];
        _overlayViewController = overlayViewController;
        [self updateOverlayViewController];
    }
}

- (void)setShareOverlay:(UIViewController *)controller animated:(BOOL)animated
{
    controller.view.alpha = 0.0;
    [UIView animateWithDuration:(animated ? 0.2 : 0) animations:^{
        self.overlayViewController.view.alpha = 0.0;
        if (controller) {
            [self hidePage];
        } else {
            [self displayPage];
        }
    } completion:^(BOOL finished) {
        self.overlayViewController = controller;
        if (controller) {
            [UIView animateWithDuration:(animated ? 0.2 : 0.0) animations:^{
                self.overlayViewController.view.alpha = 1.0;
            }];
        }
    }];
}

- (void)updateOverlayViewController
{
    if (self.isViewLoaded && self.overlayViewController) {
        [self.overlayViewController.view removeFromSuperview];
        self.overlayViewController.view.frame = self.view.bounds;
        [self.view addSubview:self.overlayViewController.view];
        
        [self.overlayViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.overlayViewController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        [self.view addConstraint:topConstraint];
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.overlayViewController.view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
        [self.view addConstraint:rightConstraint];
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.overlayViewController.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        [self.view addConstraint:bottomConstraint];
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.overlayViewController.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
        [self.view addConstraint:leftConstraint];
    }
}

- (void)setInitialIndexPath:(NSIndexPath *)initialIndexPath
{
    if (_initialIndexPath != initialIndexPath) {
        _initialIndexPath = initialIndexPath;
        NSLog(@"index path = %@", initialIndexPath);
        [self scrollCollectionViewToInitialIndexAnimated:YES];
    }
}

+ (EFVideoDetailViewController *)videoDetailViewController
{
    return [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"videoDetailViewController"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self beginListeningForNotifications];
    self.collectionView.allowsSelection = NO;
    [self hideIcons];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (!self.hasDoneInitialLayout) {
        self.hasDoneInitialLayout = YES;
        [self.collectionView reloadData];
        [self scrollCollectionViewToInitialIndexAnimated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.overlayViewController) {
        [UIView animateWithDuration:0.2 animations:^{
            [self displayIcons];
        } completion:^(BOOL finished) {
            [self playCurrentVideo];
        }];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Notifications
//////////////////////////////////////////////////////////////
- (void)beginListeningForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videosUpdated:) name:EFMediaManagerVideosUpdatedNotification object:nil];
}

- (void)endListeningForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)videosUpdated:(NSNotification *)note
{
    [self.collectionView reloadData];
    self.overlayViewController = nil;
    [UIView animateWithDuration:0.2 animations:^{
        [self displayPage];
    }];
}

//////////////////////////////////////////////////////////////
#pragma mark - UICollectionView
//////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [[EFMediaManager sharedManager] numberOfSections];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[EFMediaManager sharedManager] numberOfRowsForSection:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    EFVideoDetailCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:EFVideoDetailCellIdentifier forIndexPath:indexPath];
    
    [cell populateWithAsset:[[EFMediaManager sharedManager] assetForIndexPath:indexPath] delegate:self];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [(EFVideoDetailCell *)cell resetVideo];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.collectionView.bounds.size;
}

//////////////////////////////////////////////////////////////
#pragma mark - UIScrollView Delegate
//////////////////////////////////////////////////////////////
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self scrollingStarted];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self scrollingEnded];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollingEnded];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self scrollingEnded];
}

- (void)scrollingStarted
{
    [self stopCurrentVideo];
    [UIView animateWithDuration:0.2 animations:^{
        [self hideIcons];
    }];
}

- (void)scrollingEnded
{
    [UIView animateWithDuration:0.2 animations:^{
        [self displayIcons];
    } completion:^(BOOL finished) {
        [self playCurrentVideo];
    }];
}

//////////////////////////////////////////////////////////////
#pragma mark - EFVideoDetailCellDelegate
//////////////////////////////////////////////////////////////
- (void)videoStarted
{
    [self.videoControlButton setImage:[UIImage imageNamed:@"icon-pause-overlay"] forState:UIControlStateNormal];
    [self.videoControlButton setImage:[UIImage imageNamed:@"icon-pause-overlay-selected"] forState:UIControlStateHighlighted];
    [self.videoControlButton addTarget:self action:@selector(stopCurrentVideo) forControlEvents:UIControlEventTouchUpInside];
}

- (void)videoPaused
{
    [self.videoControlButton setImage:[UIImage imageNamed:@"icon-play-overlay"] forState:UIControlStateNormal];
    [self.videoControlButton setImage:[UIImage imageNamed:@"icon-play-overlay-selected"] forState:UIControlStateHighlighted];
    [self.videoControlButton addTarget:self action:@selector(playCurrentVideo) forControlEvents:UIControlEventTouchUpInside];
}

- (void)videoEnded
{
    [self.videoControlButton setImage:[UIImage imageNamed:@"icon-play-overlay"] forState:UIControlStateNormal];
    [self.videoControlButton setImage:[UIImage imageNamed:@"icon-play-overlay-selected"] forState:UIControlStateHighlighted];
    [self.videoControlButton addTarget:self action:@selector(replayCurrentVideo) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)cameraPressed:(id)sender
{
    [Flurry logEvent:@"Video Detail Dismissed by Camera Button"];
    [self dismiss];
}

//////////////////////////////////////////////////////////////
#pragma mark - Videos
//////////////////////////////////////////////////////////////
- (void)playCurrentVideo
{
    EFVideoDetailCell *cell = (EFVideoDetailCell *)[self.collectionView cellForItemAtIndexPath:[self currentIndexPath]];
    [cell startPlayingVideo];
}

- (void)stopCurrentVideo
{
    EFVideoDetailCell *cell = (EFVideoDetailCell *)[self.collectionView cellForItemAtIndexPath:[self currentIndexPath]];
    [cell stopPlayingVideo];
}

- (void)replayCurrentVideo
{
    EFVideoDetailCell *cell = (EFVideoDetailCell *)[self.collectionView cellForItemAtIndexPath:[self currentIndexPath]];
    [cell restartVideo];
}

//////////////////////////////////////////////////////////////
#pragma mark - Arrows
//////////////////////////////////////////////////////////////
- (IBAction)leftArrowPressed:(id)sender
{
    [Flurry logEvent:@"Video Detail Left Arrow Pressed"];
    [self stopCurrentVideo];
    NSIndexPath *previousVideoIndexPath = [self previousVideoIndexPath];
    if (previousVideoIndexPath) {
        [self.collectionView scrollToItemAtIndexPath:previousVideoIndexPath atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
    }
}

- (IBAction)rightArrowPressed:(id)sender
{
    [Flurry logEvent:@"Video Detail Right Arrow Pressed"];
    [self stopCurrentVideo];
    NSIndexPath *nextVideoIndexPath = [self nextVideoIndexpath];
    if (nextVideoIndexPath) {
        [self.collectionView scrollToItemAtIndexPath:nextVideoIndexPath atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Delete
//////////////////////////////////////////////////////////////
- (IBAction)deletePressed:(id)sender
{
    [Flurry logEvent:@"Delete Clip Initiated"];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Clip" message:@"Are you sure?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.cancelButtonIndex != buttonIndex) {
        [Flurry logEvent:@"Delete Clip Succeeded"];
        [[EFMediaManager sharedManager] removeAssetAtIndexpath:[self currentIndexPath] callback:^(BOOL wasSuccessful, AVURLAsset *asset) {
            if (wasSuccessful && [[EFMediaManager sharedManager] numberOfSections] == 0) {
                [self dismiss];
            } else {
                //TODO: remove the cell from the collectionView with an animation
                [self.collectionView reloadData];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self playCurrentVideo];
                });
            }
        }];
    } else {
        [Flurry logEvent:@"Delete Clip Canceled"];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Share
//////////////////////////////////////////////////////////////
- (IBAction)sharePressed:(id)sender
{
    [Flurry logEvent:@"Share Selected"];
    [self stopCurrentVideo];
    AVURLAsset *asset = [[EFMediaManager sharedManager] assetForIndexPath:[self currentIndexPath]];
    [self setShareOverlay:[EFShareVideoViewController shareVideoController:asset withDelegate:self] animated:YES];
}

- (void)cancelShareSelected
{
    [Flurry logEvent:@"Share Canceled"];
    [self setShareOverlay:nil animated:YES];
    [self playCurrentVideo];
}

//////////////////////////////////////////////////////////////
#pragma mark - Helper Methods
//////////////////////////////////////////////////////////////
- (void)hidePage
{
    self.barView.alpha = 0.0;
    self.leftArrowView.alpha = 0.0;
    self.rightArrowView.alpha = 0.0;
    self.cameraButton.alpha = 0.0;
}

- (void)displayPage
{
    NSIndexPath *currentIndexPath = [self currentIndexPath];
    BOOL displayLeftArrow = (currentIndexPath && !(currentIndexPath.section == 0 && currentIndexPath.row == 0));
    NSInteger maxSection = ([[EFMediaManager sharedManager] numberOfSections] - 1);
    NSInteger maxRow = ([[EFMediaManager sharedManager] numberOfRowsForSection:maxSection] - 1);
    BOOL displayRightArrow = (currentIndexPath && !(currentIndexPath.section == maxSection && currentIndexPath.row == maxRow));
    
    self.leftArrowView.alpha = (displayLeftArrow ? 1.0 : 0.0);
    self.rightArrowView.alpha = (displayRightArrow ? 1.0 : 0.0);
    self.cameraButton.alpha = 1.0;
    
    if (maxSection < 0 && maxRow < 0) {
        self.barView.alpha = 0.0;
    } else {
        self.barView.alpha = 1.0;
    }
}

- (void)hideIcons
{
    self.leftArrowView.alpha = 0.0;
    self.rightArrowView.alpha = 0.0;
    self.cameraButton.alpha = 0.0;
    self.deleteButton.enabled = NO;
    self.shareButton.enabled = NO;
}

- (void)displayIcons
{
    NSIndexPath *currentIndexPath = [self currentIndexPath];
    BOOL displayLeftArrow = (currentIndexPath && !(currentIndexPath.section == 0 && currentIndexPath.row == 0));
    NSInteger maxSection = ([[EFMediaManager sharedManager] numberOfSections] - 1);
    NSInteger maxRow = ([[EFMediaManager sharedManager] numberOfRowsForSection:maxSection] - 1);
    BOOL displayRightArrow = (currentIndexPath && !(currentIndexPath.section == maxSection && currentIndexPath.row == maxRow));
    
    self.leftArrowView.alpha = (displayLeftArrow ? 1.0 : 0.0);
    self.rightArrowView.alpha = (displayRightArrow ? 1.0 : 0.0);
    self.cameraButton.alpha = 1.0;
    self.deleteButton.enabled = YES;
    self.shareButton.enabled = YES;
}

- (NSInteger)centerOfCurrentOffset
{
    return (self.collectionView.contentOffset.x + (self.view.bounds.size.width / 2));
}

- (NSIndexPath *)currentIndexPath
{
    return [self.collectionView indexPathForItemAtPoint:CGPointMake([self centerOfCurrentOffset], 0)];
}

- (NSIndexPath *)previousVideoIndexPath
{
    NSInteger xValue = [self centerOfCurrentOffset] - self.collectionView.frame.size.width;
    if (xValue >= 0) {
        return [self.collectionView indexPathForItemAtPoint:CGPointMake(xValue, 0)];
    } else {
        return nil;
    }
}

- (NSIndexPath *)nextVideoIndexpath
{
    NSInteger xValue = [self centerOfCurrentOffset] + self.collectionView.frame.size.width;
    if (xValue <= self.collectionView.contentSize.width) {
        return [self.collectionView indexPathForItemAtPoint:CGPointMake(xValue, 0)];
    } else {
        return nil;
    }
}

- (void)scrollCollectionViewToInitialIndexAnimated:(BOOL)animated
{
    if (self.initialIndexPath && self.isViewLoaded) {
        [self.collectionView scrollToItemAtIndexPath:self.initialIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
    }
}

- (void)dismiss
{
    [self stopCurrentVideo];
    if (self.delegate) {
        [self.delegate videoDetailShouldDismiss];
    }
}

@end
