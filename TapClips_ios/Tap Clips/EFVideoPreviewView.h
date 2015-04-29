//
//  EFVideoPreviewView.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/24/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol EFVideoPreviewViewDelegate;

@interface EFVideoPreviewView : UIView

+ (EFVideoPreviewView *)videoPreviewView;

@property (nonatomic, weak) id<EFVideoPreviewViewDelegate> delegate;

- (void)updatePreviewWithAsset:(AVURLAsset *)asset animated:(BOOL)animated;
- (void)updatePreviewWithError;
- (void)scrollToVideoPreviewAnimated:(BOOL)animated;

@end

@protocol EFVideoPreviewViewDelegate <NSObject>

@optional
- (void)previewInteractionStarted;
- (void)previewInteractionEnded;
- (void)videoWasSelectedForViewing:(AVURLAsset *)asset;
- (void)videoWasDismissed;

@end