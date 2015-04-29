//
//  EFMediaManager.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/27/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^EFPhotosBlock)(NSArray *images);
typedef void(^EFMediaSaveBlock)(BOOL wasSuccessful, AVURLAsset *asset);
typedef void(^EFMediaSaveAllBlock)(BOOL wasSuccessful, NSString *message);

extern NSString * const EFMediaManagerVideosUpdatedNotification;
extern NSString * const EFMediaManagerSavedToCameraRollNotification;
extern NSString * const EFMediaManagerSaveWasSuccessfulKey;

extern NSString * const EFClipExtensionType;

@interface EFMediaManager : NSObject

+ (EFMediaManager *)sharedManager;

- (void)saveAssetAtURL:(NSURL *)assetURL withStartTime:(CGFloat)startTime duration:(CGFloat)duration andCallback:(EFMediaSaveBlock)callback;
- (void)removeAssetAtURL:(NSURL *)assetURL withCallback:(EFMediaSaveBlock)callback;

- (NSInteger)numberOfSections;
- (NSInteger)numberOfRowsForSection:(NSInteger)section;

- (NSDate *)dateForSection:(NSInteger)section;
- (AVURLAsset *)assetForIndexPath:(NSIndexPath *)indexPath;
- (UIImage *)thumbnailForIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)thumbnailsForIndexPath:(NSIndexPath *)indexPath;
- (void)removeAssetAtIndexpath:(NSIndexPath *)indexPath callback:(EFMediaSaveBlock)callback;

- (void)attemtToSaveAssetToCameraRoll:(AVURLAsset *)asset withNotification:(BOOL)notification callback:(EFMediaSaveBlock)callback;
- (void)attemptToSaveAllAssetsToCameraRollThenDeleteWithCallback:(EFMediaSaveAllBlock)callback;

+ (NSString *)documentsDirectory;
+ (UIImage *)createThumbnailFromAsset:(AVURLAsset *)asset;
+ (UIImage *)thumbnailFromAsset:(AVURLAsset *)asset;
+ (NSArray *)thumbnailsFromAsset:(AVURLAsset *)asset;
+ (UIImage *)fullSizeCoverImageFromAsset:(AVURLAsset *)asset;
+ (UIImage *)fullSizeStartingImageFromAsset:(AVURLAsset *)asset;

@end
