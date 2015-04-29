//
//  EFCameraManager.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/26/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFCameraManager.h"
#import "EFRecordFilterPipeline.h"
#import "EFMediaManager.h"
#import "EFLocationManager.h"
#import "EFSettingsManager.h"
#import "GPUImage.h"
#import "Flurry.h"


NSString * const EFCurrentVideoBufferChangedNotification = @"currentVideoBufferChangedNotification";
NSString * const EFCurrentVideoBufferStartDateKey = @"videoStartDate";

static NSInteger const EFMaxBuffers = 2;
static NSInteger const EFBufferDuration = 120;
static CGFloat const EFOutputWidth = 960.0;
static CGFloat const EFOutputHeight = 540.0;

@interface EFCameraManager () <GPUImageVideoCameraDelegate, EFRecordFilterPipelineDelegate>

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageCropFilter *cropFilter;
@property (nonatomic, strong) EFRecordFilterPipeline *filterPipeline;
@property (nonatomic, strong, readwrite) GPUImageView *outputView;

@property (nonatomic, strong) NSNumber *clipDurationBacking;
@property (nonatomic, strong) NSDate *captureDate;
@property (nonatomic, assign) BOOL canSave;
@property (nonatomic, assign) BOOL cameraStarted;
@property (nonatomic, assign) BOOL canAddNewStreamDuringDuration;
@property (nonatomic, assign) BOOL canRemoveStreamDuringDuration;

@property (nonatomic, strong) AVURLAsset *previousBufferAsset;
@end

@implementation EFCameraManager

- (void)setPreviousBufferURL:(NSURL *)previousBufferUrl
{
    if (![self.previousBufferAsset.URL.path isEqualToString:previousBufferUrl.path]) {
        self.previousBufferAsset = [AVURLAsset URLAssetWithURL:previousBufferUrl options:nil];
    }
}

- (GPUImageView *)outputView
{
    if (!_outputView) {
        _outputView = [[GPUImageView alloc] init];
        _outputView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    }
    return _outputView;
}

- (EFRecordFilterPipeline *)filterPipeline
{
    if (!_filterPipeline) {
        _filterPipeline = [[EFRecordFilterPipeline alloc] initWithCamera:self.videoCamera input:self.cropFilter outputView:self.outputView];
        _filterPipeline.delegate = self;
    }
    return _filterPipeline;
}

- (GPUImageCropFilter *)cropFilter
{
    if (!_cropFilter) {
        _cropFilter = [[GPUImageCropFilter alloc] init];
        [_cropFilter forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(EFOutputWidth, EFOutputHeight)];
    }
    return _cropFilter;
}

- (GPUImageFilter *)newRecordingFilter
{
    GPUImageBrightnessFilter *newRecordingFilter = [[GPUImageBrightnessFilter alloc] init];
    newRecordingFilter.brightness = 0;
    
    static NSInteger movieNumber = 0;
    NSString *pathToMovie = [[EFMediaManager documentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"movie%ld%@", (long)movieNumber, EFClipExtensionType]];
    ++movieNumber;
    if (movieNumber > EFMaxBuffers) movieNumber = 0;
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *newMovieURL = [NSURL fileURLWithPath:pathToMovie];
    GPUImageMovieWriter *newMovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:newMovieURL size:CGSizeMake(EFOutputWidth, EFOutputHeight) fileType:AVFileTypeQuickTimeMovie outputSettings:nil];
    newMovieWriter.encodingLiveVideo = YES;
    [newRecordingFilter addTarget:newMovieWriter];
    return newRecordingFilter;
}

- (NSNumber *)clipDuration
{
    return [[EFSettingsManager sharedManager] defaultRecordingSeconds];
}

+ (EFCameraManager *)sharedManager
{
    static EFCameraManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EFCameraManager alloc] init];
    });
    return manager;
}

- (id)init
{
    self = [super init];
    if (self) {
        _cameraStarted = NO;
        _canAddNewStreamDuringDuration = YES;
        _canRemoveStreamDuringDuration = YES;
        [self setupVideoCamera];
    }
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark - Setup
//////////////////////////////////////////////////////////////
- (GPUImageVideoCamera *)videoCamera
{
    if (!_videoCamera) {
        _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetiFrame960x540 cameraPosition:AVCaptureDevicePositionBack];
        _videoCamera.frameRate = 30;
        BOOL canSetSmoothAutoFocus = [self isSmoothAutoFocusAvailableForDevice:_videoCamera.inputCamera];
        BOOL locked = [_videoCamera.inputCamera lockForConfiguration:nil];
        if (locked) {
            [_videoCamera.inputCamera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            if (canSetSmoothAutoFocus) {
                _videoCamera.inputCamera.smoothAutoFocusEnabled = YES;
            }
            [_videoCamera.inputCamera unlockForConfiguration];
        }
        _videoCamera.delegate = self;
        _videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeRight;
        [_videoCamera addTarget:self.cropFilter];
    }
    return _videoCamera;
}

- (BOOL)isSmoothAutoFocusAvailableForDevice:(AVCaptureDevice *)device
{
    return ([device respondsToSelector:@selector(isSmoothAutoFocusSupported)] &&
            [device isSmoothAutoFocusSupported] &&
            [device respondsToSelector:@selector(isSmoothAutoFocusEnabled)]);
}

- (void)setupVideoCamera
{
    [self videoCamera];
}

- (void)setupInitialRecordingFilters
{
    if ([self.filterPipeline.filters count] == 0) {
        [self addNewRecordingFilter];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Camera
//////////////////////////////////////////////////////////////
- (BOOL)isCameraStarted
{
    return (_videoCamera && self.cameraStarted);
}

- (void)startCamera
{
    [self.videoCamera startCameraCapture];
    self.cameraStarted = YES;
}

- (void)stopCamera
{
    self.cameraStarted = NO;
    [self stopRecording];
    [self.videoCamera stopCameraCapture];
    [self.filterPipeline removeAllRecordingFilters];
}

- (void)resetCamera
{
    [self stopCamera];
    self.filterPipeline = nil;
    self.cropFilter = nil;
    self.videoCamera = nil;
}

//////////////////////////////////////////////////////////////
#pragma mark - Recording
//////////////////////////////////////////////////////////////
- (void)startRecording
{
    if ([self.filterPipeline.filters count] == 0) {
        [self setupInitialRecordingFilters];
    }
    self.canSave = YES;
}

- (void)stopRecording
{
    self.canSave = NO;
    [self.filterPipeline stopAllRecordingFilters];
    [self setPreviousBufferURL:nil];
}

//////////////////////////////////////////////////////////////
#pragma mark - Zoom
//////////////////////////////////////////////////////////////
- (void)updateZoom:(CGFloat)percentZoom
{
    self.cropFilter.cropRegion = CGRectInset(CGRectMake(0, 0, 1, 1), (percentZoom / 4), (percentZoom / 4));
}

//////////////////////////////////////////////////////////////
#pragma mark - Video
//////////////////////////////////////////////////////////////
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (_filterPipeline && [_filterPipeline.filters count]) {
        NSDate *currentFilterStartDate = [self.filterPipeline startTimeForFilter:[self.filterPipeline.filters objectAtIndex:0]];
        if (currentFilterStartDate && [[NSDate date] timeIntervalSince1970] - [currentFilterStartDate timeIntervalSince1970] > EFBufferDuration) {
            [self durationHitRemoveOldStream];
        } else if (currentFilterStartDate && [[NSDate date] timeIntervalSince1970] - [currentFilterStartDate timeIntervalSince1970] > (EFBufferDuration - [[EFSettingsManager sharedManager] maxRecordingSeconds].floatValue)) {
            [self durationHitAddNewStream];
        }
    }
}

- (void)durationHitAddNewStream
{
    if (self.canAddNewStreamDuringDuration && [self.filterPipeline.filters count] < EFMaxBuffers) {
        self.canAddNewStreamDuringDuration = NO;
        [self addNewRecordingFilter];
        self.canAddNewStreamDuringDuration = YES;
    }
}

- (void)durationHitRemoveOldStream
{
    if (self.canRemoveStreamDuringDuration) {
        self.canRemoveStreamDuringDuration = NO;
        [self removeOldestStreamWithCallback:^(BOOL wasSuccessful, AVURLAsset *asset) {
            self.canRemoveStreamDuringDuration = YES;
        }];
    }
}

- (void)addNewRecordingFilter
{
    GPUImageFilter *newFilter = [self newRecordingFilter];
    [self.filterPipeline addRecordingFilter:newFilter];
}

- (void)removeOldestStreamWithCallback:(EFCameraCaptureBlock)callback
{
    if ([self.filterPipeline.filters count]) {
        GPUImageFilter *oldestFilter = [[self.filterPipeline filters] objectAtIndex:0];
        [self.filterPipeline removeRecordingFilter:oldestFilter];
        GPUImageMovieWriter *movieWriter = nil;
        for (id<GPUImageInput>target in oldestFilter.targets) {
            if ([target isKindOfClass:[GPUImageMovieWriter class]]) {
                movieWriter = target;
                break;
            }
        }
        if (movieWriter) {
            [movieWriter finishRecordingWithCompletionHandler:^{
                NSURL *assetURL = movieWriter.assetWriter.outputURL;
//                AVURLAsset *asset = [AVURLAsset assetWithURL:assetURL];
//                NSLog(@"asset duration = %f", CMTimeGetSeconds(asset.duration));
                [self setPreviousBufferURL:assetURL];
                if (callback) {
                    callback (YES, nil);
                }
            }];
        } else if (callback) {
            callback (NO, nil);
        }
    } else if (callback) {
        callback (NO, nil);
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Save Video
//////////////////////////////////////////////////////////////
- (NSNumber *)aproximateLengthOfVideoIfTaken
{
    NSNumber *videoLength = @0;
    if ([self.filterPipeline.filters count]) {
        GPUImageFilter *currentRecordingFilter = [self.filterPipeline.filters objectAtIndex:0];
        NSDate *startDateOfFilter = [self.filterPipeline startTimeForFilter:currentRecordingFilter];
        videoLength = [NSNumber numberWithDouble:ceil([[NSDate date] timeIntervalSinceDate:startDateOfFilter])];
    } else {
        [Flurry logError:@"Attempting Length With No Filters" message:@"" error:nil];
    }
    return (videoLength.floatValue > self.clipDuration.floatValue ? self.clipDuration : videoLength);
}

- (BOOL)canCaptureVideo
{
    return self.canSave;
}

- (void)captureVideo:(EFCameraCaptureBlock)callback
{
    if (self.canSave) {
        self.captureDate = [NSDate date];
        if (![EFLocationManager locationServicesHasBeenApproved]) {
            [[EFLocationManager sharedManager] updateCurrentLocationIfPossible:nil];
        }
        [self saveVideoWithCallback:callback];
    } else if (callback) {
        callback (NO, nil);
    }
}

- (void)saveVideoWithCallback:(EFCameraCaptureBlock)callback
{
    GPUImageFilter *currentRecordingFilter = [self.filterPipeline.filters objectAtIndex:0];
    NSDate *startDateOfFilter = [self.filterPipeline startTimeForFilter:currentRecordingFilter];
    CGFloat bufferLength = [[NSDate date] timeIntervalSinceDate:startDateOfFilter];
    
    CGFloat startTime = ((self.captureDate.timeIntervalSince1970 - startDateOfFilter.timeIntervalSince1970) > self.clipDuration.floatValue ? ((self.captureDate.timeIntervalSince1970 - startDateOfFilter.timeIntervalSince1970) - self.clipDuration.floatValue) : 0);
    
    if (currentRecordingFilter && (bufferLength > self.clipDuration.floatValue || !self.previousBufferAsset)) {
        CGFloat clipDuration = (bufferLength > [[EFCameraManager sharedManager] clipDuration].floatValue ? [[EFCameraManager sharedManager] clipDuration].floatValue : bufferLength);
        [self attempToSaveVideoFromFilter:currentRecordingFilter withVideoStartTime:startTime duration:clipDuration initialCalls:0 andCallback:callback];
    } else if (currentRecordingFilter) {
        NSLog(@"TODO: record from multi buffer");
        if (callback) {
            callback (NO, nil);
        }
    } else if (callback) {
        callback (NO, nil);
    }
}

- (void)attempToSaveVideoFromFilter:(GPUImageFilter *)recordingFilter withVideoStartTime:(CGFloat)startTime duration:(CGFloat)duration initialCalls:(NSInteger)numberOfCalls andCallback:(EFCameraCaptureBlock)callback
{
    if ([self canSaveVideoFromFilter:recordingFilter withStartTime:startTime andDuration:duration]){
        [self saveVideoFromFilter:recordingFilter withStartTime:startTime duration:duration andCallback:callback];
    } else if (numberOfCalls < 30) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self attempToSaveVideoFromFilter:recordingFilter withVideoStartTime:startTime duration:duration initialCalls:(numberOfCalls + 1) andCallback:callback];
        });
    } else {
        [Flurry logError:@"Saved Video After Erroring" message:@"" error:nil];
        [self saveVideoFromFilter:recordingFilter withStartTime:startTime duration:duration andCallback:callback];
    }
}

- (BOOL)canSaveVideoFromFilter:(GPUImageFilter *)recordingFilter withStartTime:(CGFloat)startTime andDuration:(CGFloat)duration
{
    GPUImageMovieWriter *movieWriter = nil;
    for (id<GPUImageInput>target in recordingFilter.targets) {
        if ([target isKindOfClass:[GPUImageMovieWriter class]]) {
            movieWriter = target;
            break;
        }
    }
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:movieWriter.assetWriter.outputURL];
    CMTime requestTime = CMTimeMakeWithSeconds((startTime + duration), 600);
    CMTime actualTime;
    NSError *error = nil;
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    imageGenerator.maximumSize = CGSizeMake(225, 135);
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    CGImageRef cgImage = [imageGenerator copyCGImageAtTime:requestTime actualTime:&actualTime error:&error];
    UIImage *thumbnail = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
//    NSLog(@"error = %@", error);
//    NSLog(@"requestedTime = %f", CMTimeGetSeconds(requestTime));
//    NSLog(@"actualTime = %f", CMTimeGetSeconds(actualTime));
//    NSLog(@"movieWriter Duration = %f", CMTimeGetSeconds(movieWriter.duration));
    
    return (thumbnail && !error);
}

- (void)saveVideoFromFilter:(GPUImageFilter *)recordingFilter withStartTime:(CGFloat)startTime duration:(CGFloat)duration andCallback:(EFCameraCaptureBlock)callback
{
    GPUImageMovieWriter *movieWriter = nil;
    for (id<GPUImageInput>target in recordingFilter.targets) {
        if ([target isKindOfClass:[GPUImageMovieWriter class]]) {
            movieWriter = target;
            break;
        }
    }
    
    [[EFMediaManager sharedManager] saveAssetAtURL:movieWriter.assetWriter.outputURL withStartTime:startTime duration:duration andCallback:^(BOOL wasSuccessful, AVURLAsset *asset) {
        if (callback) {
            callback (wasSuccessful, asset);
        }
    }];
}

//////////////////////////////////////////////////////////////
#pragma mark - Blur
//////////////////////////////////////////////////////////////
- (void)blurOutputView
{
    [self.filterPipeline blurOutputView];
}

- (void)removeBlurFromOutputView
{
    [self.filterPipeline removeBlurFromOutputView];
}

//////////////////////////////////////////////////////////////
#pragma mark - EFRecordingFilterPipelineDelegate
//////////////////////////////////////////////////////////////
- (void)newMainRecordingBufferFromStartDate:(NSDate *)startDate
{
    NSDictionary *startTimeDict = (startDate ? @{EFCurrentVideoBufferStartDateKey: startDate}: nil);
    [[NSNotificationCenter defaultCenter] postNotificationName:EFCurrentVideoBufferChangedNotification object:nil userInfo:startTimeDict];
}

//////////////////////////////////////////////////////////////
#pragma mark - Orientation
//////////////////////////////////////////////////////////////
- (void)updateVideoOrientation:(UIInterfaceOrientation)orientation
{
    self.videoCamera.outputImageOrientation = orientation;
}

@end
