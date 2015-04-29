//
//  EFCameraManager.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/26/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

extern NSString * const EFCurrentVideoBufferChangedNotification;
extern NSString * const EFCurrentVideoBufferStartDateKey;

typedef void(^EFCameraCaptureBlock)(BOOL wasSuccessful, AVURLAsset *asset);

@class GPUImageView;

@interface EFCameraManager : NSObject

+ (EFCameraManager *)sharedManager;

@property (nonatomic, strong, readonly) GPUImageView *outputView;

-(NSNumber *)clipDuration;

- (void)blurOutputView;
- (void)removeBlurFromOutputView;

- (BOOL)isCameraStarted;
- (void)startCamera;
- (void)stopCamera;
- (void)resetCamera;

- (void)startRecording;
- (void)stopRecording;

- (NSNumber *)aproximateLengthOfVideoIfTaken;
- (void)captureVideo:(EFCameraCaptureBlock)callback;
- (BOOL)canCaptureVideo;

- (void)updateZoom:(CGFloat)percentZoom;

- (void)updateVideoOrientation:(UIInterfaceOrientation)orientation;

@end
