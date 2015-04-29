//
//  EFRecordFilterPipeline.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/19/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFRecordFilterPipeline.h"
#import <GPUImage.h>

@interface EFRecordFilterPipeline ()
@property (nonatomic, strong, readwrite) NSMutableArray *filters;
@property (nonatomic, strong, readwrite) NSMutableArray *closingFilters;
@property (nonatomic, strong, readwrite) NSMutableArray *startTimes;
@property (nonatomic, strong, readwrite) NSMutableArray *closingStartTimes;
@property (nonatomic, strong) GPUImageVideoCamera *camera;
@property (nonatomic, strong) GPUImageOutput *input;
@property (nonatomic, strong) GPUImageView *output;

@property (nonatomic, strong) GPUImageiOSBlurFilter *blurFilter;
@property (nonatomic, strong) GPUImageOverlayBlendFilter *watermarkFilter;
@property (nonatomic, strong) GPUImagePicture *watermarkPicture;

@end

@implementation EFRecordFilterPipeline

- (GPUImageFilter *)currentFilter
{
    if ([self.filters count]) {
        return [self.filters objectAtIndex:0];
    } else {
        return nil;
    }
}

- (GPUImageiOSBlurFilter *)blurFilter
{
    if (!_blurFilter) {
        _blurFilter = [[GPUImageiOSBlurFilter alloc] init];
        _blurFilter.blurRadiusInPixels = 4.0;
        _blurFilter.saturation = 1.0;
        _blurFilter.rangeReductionFactor = 0.2;
    }
    return _blurFilter;
}

- (GPUImageOverlayBlendFilter *)watermarkFilter
{
    if (!_watermarkFilter) {
        _watermarkFilter = [[GPUImageOverlayBlendFilter alloc] init];
        [self.watermarkPicture addTarget:_watermarkFilter];
    }
    return _watermarkFilter;
}

- (GPUImagePicture *)watermarkPicture
{
    if (!_watermarkPicture) {
        UIImage *overlayImage = [self watermarkImage];
        _watermarkPicture = [[GPUImagePicture alloc] initWithImage:overlayImage smoothlyScaleOutput:YES];
        [_watermarkPicture processImage];
    }
    return _watermarkPicture;
}

- (UIImage *)watermarkImage
{
    UIImage *image = [UIImage imageNamed:@"icon-watermark"];
    CGSize overlaySize = CGSizeMake([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    UIGraphicsBeginImageContextWithOptions(overlaySize, NO, 0.0);
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0, image.size.height);
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
    CGRect imageRect = CGRectMake((overlaySize.width - image.size.width - 10),-(overlaySize.height - image.size.height - 10), image.size.width, image.size.height);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), imageRect, image.CGImage);
    UIImage *overlayImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return overlayImage;
}

- (id)initWithCamera:(GPUImageVideoCamera *)camera input:(GPUImageOutput *)input outputView:(GPUImageView *)output
{
    self = [super init];
    if (self) {
        self.filters = [NSMutableArray array];
        self.closingFilters = [NSMutableArray array];
        self.startTimes = [NSMutableArray array];
        self.closingStartTimes = [NSMutableArray array];
        self.camera = camera;
        self.input = input;
        self.output = output;
        [self.input addTarget:self.output];
    }
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark - Recording
//////////////////////////////////////////////////////////////
- (void)addRecordingFilter:(GPUImageFilter *)filter
{
    [self.input addTarget:filter];
    [self.camera addAudioTarget:filter];
    [self.startTimes addObject:[NSDate date]];
    [self.filters addObject:filter];
    
    if ([self.filters count] == 1) {
        [self updateDelegateWithNewFilter:[self currentFilter]];
    }
}

- (void)removeRecordingFilter:(GPUImageFilter *)filter
{
    [self.input removeTarget:filter];
    [self.camera removeAudioTarget:filter];
    if ([self.filters containsObject:filter]) {
        NSInteger indx = [self.filters indexOfObject:filter];
        [self.startTimes removeObjectAtIndex:indx];
        [self.filters removeObject:filter];
    }
    
    [self updateDelegateWithNewFilter:[self currentFilter]];
}

- (void)removeAllRecordingFilters
{
    NSArray *existingFilters = [self.filters copy];
    for (GPUImageFilter *filter in existingFilters) {
        [self removeRecordingFilter:filter];
    }
    [self.startTimes removeAllObjects];
    [self.filters removeAllObjects];
    
    [self updateDelegateWithNewFilter:nil];
}

- (NSDate *)startTimeForFilter:(GPUImageFilter *)filter
{
    if (!filter)
        return nil;
    else if (![self.filters containsObject:filter] || [self.startTimes count] == 0)
        return nil;
    
    NSInteger indx = [self.filters indexOfObject:filter];
    if ([self.startTimes count] <= indx)
        return nil;
    return [[self.startTimes objectAtIndex:indx] copy];
}

- (void)updateDelegateWithNewFilter:(GPUImageFilter *)filter
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(newMainRecordingBufferFromStartDate:)]) {
        [self.delegate newMainRecordingBufferFromStartDate:[self startTimeForFilter:filter]];
    }
}

- (void)stopAllRecordingFilters
{
    [self.closingFilters addObjectsFromArray:self.filters];
    [self.closingStartTimes addObjectsFromArray:self.startTimes];
    [self.filters removeAllObjects];
    [self.startTimes removeAllObjects];
    NSArray *existingFilters = [self.closingFilters copy];
    for (GPUImageFilter *filter in existingFilters) {
        if (filter.targets && [[filter.targets objectAtIndex:0] isKindOfClass:[GPUImageMovieWriter class]]) {
            GPUImageMovieWriter *writer = [filter.targets objectAtIndex:0];
            [writer finishRecordingWithCompletionHandler:^{
                [self.input removeTarget:filter];
                [self.camera removeAudioTarget:filter];
                if ([self.filters containsObject:filter]) {
                    NSInteger indx = [self.filters indexOfObject:filter];
                    [self.closingStartTimes removeObjectAtIndex:indx];
                    [self.closingFilters removeObject:filter];
                }
            }];
        }
    }
    
    [self updateDelegateWithNewFilter:nil];
}

//////////////////////////////////////////////////////////////
#pragma mark - Blur
//////////////////////////////////////////////////////////////
- (void)blurOutputView
{
    [self.input removeTarget:self.output];
    [self.blurFilter addTarget:self.output];
    [self.input addTarget:self.blurFilter];
}

- (void)removeBlurFromOutputView
{
    [self.blurFilter removeAllTargets];
    [self.input removeTarget:self.blurFilter];
    [self.input addTarget:self.output];
}

@end
