//
//  EFRecordFilterPipeline.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/19/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImageVideoCamera.h"
#import "GPUImageFilter.h"
#import "GPUImageView.h"

@protocol EFRecordFilterPipelineDelegate;

@interface EFRecordFilterPipeline : NSObject

@property (nonatomic, readonly) NSMutableArray *filters;

- (id)initWithCamera:(GPUImageVideoCamera *)camera input:(GPUImageOutput *)input outputView:(GPUImageView *)output;

- (void)addRecordingFilter:(GPUImageFilter *)filter; //Starts recording after audio is setup
- (void)removeRecordingFilter:(GPUImageFilter *)filter; //Removes from audio
- (void)removeAllRecordingFilters;
- (void)stopAllRecordingFilters;

- (void)blurOutputView;
- (void)removeBlurFromOutputView;

- (NSDate *)startTimeForFilter:(GPUImageFilter *)filter;

@property (nonatomic, weak) id<EFRecordFilterPipelineDelegate> delegate;

@end

@protocol EFRecordFilterPipelineDelegate <NSObject>

@optional
- (void)newMainRecordingBufferFromStartDate:(NSDate *)startDate;

@end