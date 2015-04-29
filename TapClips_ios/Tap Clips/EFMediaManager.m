//
//  EFMediaManager.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/27/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFMediaManager.h"
#import "EFCameraManager.h"
#import "EFUploadManager.h"
#import "EFLocationManager.h"
#import "Flurry.h"
#import "EFExtensions.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>

typedef void(^EFMediaSaveReturnBlock)(NSArray *videos);

NSString * const EFMediaManagerVideosUpdatedNotification = @"mediaManagerVideosUpdated";
NSString * const EFMediaManagerSavedToCameraRollNotification = @"mediaManagerSavedToCameraRoll";
NSString * const EFMediaManagerSaveWasSuccessfulKey = @"wasSuccessful";

static NSString * const EFTapClipAlbumName = @"TapClips";
NSString * const EFClipExtensionType = @".mp4";

@interface _EFMediaCacheManager : NSObject
@property (nonatomic, strong) NSCache *imageCache;
+ (instancetype)sharedManager;

- (UIImage *)imageForKey:(NSString *)key;
- (void)setImage:(UIImage *)image forKey:(NSString *)key;
@end

@implementation _EFMediaCacheManager

+ (instancetype)sharedManager
{
    static _EFMediaCacheManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[_EFMediaCacheManager alloc] init];
    });
    return manager;
}

- (id)init
{
    self = [super init];
    if (self) {
        _imageCache = [[NSCache alloc] init];
    }
    return self;
}

- (UIImage *)imageForKey:(NSString *)key
{
    return [self.imageCache objectForKey:key];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key
{
    if (image) {
        [self.imageCache setObject:image forKey:key cost:(NSUInteger)image.size.width];
    }
}

@end


@interface EFMediaManager ()
@property (nonatomic, strong) NSMutableArray *savedVideosURLsBacking;
@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;
@property (nonatomic, strong) ALAssetsLibrary *assetLibrary;
@end

@implementation EFMediaManager {
    dispatch_queue_t _concurrentFileManagerQueue;
}

+ (EFMediaManager *)sharedManager
{
    static EFMediaManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EFMediaManager alloc] init];
    });
    return manager;
}

- (id)init
{
    self = [super init];
    if (self) {
        _concurrentFileManagerQueue = dispatch_queue_create("com.elementalfoundry.tap-clips.file-manager-queue", DISPATCH_QUEUE_CONCURRENT);
        _assetLibrary = [[ALAssetsLibrary alloc] init];
        [self oneTimeExclusionOfDocsToICloud];
        [self resetSavedVideoURLs];
    }
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark - video URLs
//////////////////////////////////////////////////////////////
- (void)oneTimeExclusionOfDocsToICloud
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRemovedAllVideosFromICloud"]) {
        NSArray *directoryContents = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[EFMediaManager saveVideosDirectory] error:nil] mutableCopy];
        for (NSString *file in directoryContents) {
            NSString *filePath = [[EFMediaManager saveVideosDirectory] stringByAppendingPathComponent:file];
            NSURL *url = [NSURL fileURLWithPath:filePath];
            [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
        }
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRemovedAllVideosFromICloud"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)resetSavedVideoURLs
{
    NSArray *directoryContents = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[EFMediaManager saveVideosDirectory] error:nil] mutableCopy];
    NSArray *directoryVideos = [directoryContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.mp4'"]];
    NSMutableDictionary *urlsByDate = [NSMutableDictionary dictionary];
    for (NSString *file in directoryVideos) {
        NSString *filePath = [[EFMediaManager saveVideosDirectory] stringByAppendingPathComponent:file];
        NSURL *url = [NSURL fileURLWithPath:filePath];

        NSDate *date = [[[url resourceValuesForKeys:[NSArray arrayWithObject:NSURLCreationDateKey] error:nil] objectForKey:NSURLCreationDateKey] dateWithoutTime];
        NSMutableArray *urlsForDate = [urlsByDate objectForKey:date defaultValue:[NSMutableArray array]];
        
        NSUInteger newIndex = [urlsForDate indexOfObject:url
                                     inSortedRange:(NSRange){0, [urlsForDate count]}
                                           options:NSBinarySearchingInsertionIndex
                                   usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                       
                                       id dateA = [[obj1 resourceValuesForKeys:[NSArray arrayWithObject:NSURLCreationDateKey] error:nil] objectForKey:NSURLCreationDateKey];
                                       id dateB = [[obj2 resourceValuesForKeys:[NSArray arrayWithObject:NSURLCreationDateKey] error:nil] objectForKey:NSURLCreationDateKey];
                                       
                                       NSComparisonResult result = [dateA compare:dateB];
                                       
                                       if (result == NSOrderedAscending) {
                                           result = NSOrderedDescending;
                                       } else if (result == NSOrderedDescending) {
                                           result = NSOrderedAscending;
                                       }
                                       return result;
                                   }];
        
        [urlsForDate insertObject:url atIndex:newIndex];
        [urlsByDate setObject:urlsForDate forKey:date];
    }
    NSMutableArray *urls = [[urlsByDate allValues] mutableCopy];

    [urls sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        // get the two creation dates
        id dateA = [[[[obj1 objectAtIndex:0] resourceValuesForKeys:[NSArray arrayWithObject:NSURLCreationDateKey] error:nil] objectForKey:NSURLCreationDateKey] dateWithoutTime];
        id dateB = [[[[obj2 objectAtIndex:0] resourceValuesForKeys:[NSArray arrayWithObject:NSURLCreationDateKey] error:nil] objectForKey:NSURLCreationDateKey] dateWithoutTime];
        
        // compare them
        NSComparisonResult result = [dateA compare:dateB];
        
        if (result == NSOrderedAscending) {
            result = NSOrderedDescending;
        } else if (result == NSOrderedDescending) {
            result = NSOrderedAscending;
        }
        return result;
    }];
    [self setSavedVideosURLsByDate:[urls copy]];
}

- (NSArray *)savedVideosURLs
{
    NSArray *directoryContents = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[EFMediaManager saveVideosDirectory] error:nil] mutableCopy];
    NSArray *directoryVideos = [directoryContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.mp4'"]];
    NSMutableArray *urls = [NSMutableArray array];
    for (NSString *file in directoryVideos) {
        NSString *filePath = [[EFMediaManager saveVideosDirectory] stringByAppendingPathComponent:file];
        NSURL *url = [NSURL fileURLWithPath:filePath];
        [urls addObject:url];
    }
    return urls;
}

- (NSArray *)savedVideosURLsByDate
{
    __block NSArray *videos = nil;
    dispatch_sync(_concurrentFileManagerQueue, ^{
        videos = [self.savedVideosURLsBacking copy];
    });
    return videos;
}

- (void)setSavedVideosURLsByDate:(NSArray *)videoURLs
{
    dispatch_barrier_async(_concurrentFileManagerQueue, ^{
        self.savedVideosURLsBacking = [videoURLs mutableCopy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:EFMediaManagerVideosUpdatedNotification object:nil];
        });
    });
}

- (NSURL *)savedVideoURLAtIndexPath:(NSIndexPath *)indexPath
{
    __block NSURL *savedVideoURL = nil;
    dispatch_sync(_concurrentFileManagerQueue, ^{
        if (indexPath.section < [self.savedVideosURLsBacking count] && indexPath.row < [[self.savedVideosURLsBacking objectAtIndex:indexPath.section] count]) {
            savedVideoURL = [[self.savedVideosURLsBacking objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        }
    });
    return savedVideoURL;
}

//////////////////////////////////////////////////////////////
#pragma mark - Save
//////////////////////////////////////////////////////////////
- (void)saveAssetAtURL:(NSURL *)assetURL withStartTime:(CGFloat)startTime duration:(CGFloat)duration andCallback:(EFMediaSaveBlock)callback
{
    if (!assetURL && callback) {
        [Flurry logError:@"Attempted to export null asset" message:@"" error:nil];
        callback (NO, nil);
        return;
    }
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
    exportSession.metadata = [self metadataForURL:assetURL];
    
    NSString *outputURL = [[EFMediaManager saveVideosDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%f%@", [[NSDate date] timeIntervalSince1970], EFClipExtensionType]];
    exportSession.outputURL = [NSURL fileURLWithPath:outputURL];
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    CMTime start = CMTimeMakeWithSeconds(startTime, 600);
    CMTime durationTime = CMTimeMakeWithSeconds(duration, 600);
    CMTimeRange range = CMTimeRangeMake(start, durationTime);
    exportSession.timeRange = range;
    NSLog(@"starting export = %@", assetURL);
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        NSLog(@"export ended");
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            [self resetSavedVideoURLs];
        }
        NSURL *completedOutputURL = [NSURL fileURLWithPath:outputURL];
        [completedOutputURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
        if (callback) {
            BOOL wasSuccessful = (exportSession.status == AVAssetExportSessionStatusCompleted);
            AVURLAsset *asset = nil;
            if (wasSuccessful) {
                asset = [AVURLAsset assetWithURL:completedOutputURL];
                [self createImagesForAsset:asset];
            }
            callback (wasSuccessful, asset);
        }
    }];
}

- (NSArray *)metadataForURL:(NSURL *)url
{
    NSMutableArray *metadata = [NSMutableArray array];
    AVMutableMetadataItem *metaDateItem = [AVMutableMetadataItem metadataItem];
    metaDateItem.key = AVMetadataCommonKeyCreationDate;
    metaDateItem.keySpace = AVMetadataKeySpaceCommon;
    metaDateItem.value = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    [metadata addObject:metaDateItem];
    
    AVMutableMetadataItem *metaAuthorItem = [AVMutableMetadataItem metadataItem];
    metaAuthorItem.key = AVMetadataCommonKeyAuthor;
    metaAuthorItem.keySpace = AVMetadataKeySpaceCommon;
    metaAuthorItem.value = @"TapClips";
    [metadata addObject:metaAuthorItem];
    
    AVMutableMetadataItem *metaSoftwareItem = [AVMutableMetadataItem metadataItem];
    metaSoftwareItem.key = AVMetadataCommonKeySoftware;
    metaSoftwareItem.keySpace = AVMetadataKeySpaceCommon;
    metaSoftwareItem.value = @"TapClips";
    [metadata addObject:metaSoftwareItem];
    
    if ([[EFLocationManager sharedManager] lastKnownLocation]) {
        AVMutableMetadataItem *metaLocationItem = [AVMutableMetadataItem metadataItem];
        metaLocationItem.key = AVMetadataCommonKeyLocation;
        metaLocationItem.keySpace = AVMetadataKeySpaceCommon;
        CLLocation *location = [[EFLocationManager sharedManager] lastKnownLocation];
        metaLocationItem.value = [NSString stringWithFormat:@"%+08.4lf%+09.4lf %f %f",
                                  location.coordinate.latitude, location.coordinate.longitude, location.course, location.speed];
        [metadata addObject:metaLocationItem];
    }
    
    return metadata;
}

- (void)removeAssetAtURL:(NSURL *)assetURL withCallback:(EFMediaSaveBlock)callback
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    [EFMediaManager removeAsset:asset];
    [self resetSavedVideoURLs];
    if (callback) {
        callback (![[NSFileManager defaultManager] fileExistsAtPath:asset.URL.path], nil);
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Video Images
//////////////////////////////////////////////////////////////
- (void)createImagesForAsset:(AVURLAsset *)asset
{
    self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    self.imageGenerator.maximumSize = CGSizeMake(225, 135);
    NSString *assetName = [self fileNameForAsset:asset];
    Float64 durationSeconds = CMTimeGetSeconds([asset duration]);
    CMTime beginning = CMTimeMakeWithSeconds(0.8, 600);
    CMTime middle = CMTimeMakeWithSeconds(durationSeconds/2.0, 600);
    CMTime end = CMTimeMakeWithSeconds(durationSeconds - 0.8, 600);
    NSArray *times = @[[NSValue valueWithCMTime:beginning],
                       [NSValue valueWithCMTime:middle],
                       [NSValue valueWithCMTime:end]];
    
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times
                                         completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime,
                                                             AVAssetImageGeneratorResult result, NSError *error) {
                                                                                          
                                             if (result == AVAssetImageGeneratorSucceeded) {
                                                 NSInteger imagePlace = 4;
                                                 if (CMTimeCompare(requestedTime, beginning) == 0) {
                                                     imagePlace = 0;
                                                 } else if (CMTimeCompare(requestedTime, middle) == 0) {
                                                     imagePlace = 1;
                                                 } else if (CMTimeCompare(requestedTime, end) == 0) {
                                                     imagePlace = 2;
                                                 }
                                                 
                                                 NSString *imageName = [NSString stringWithFormat:@"%@-%ld.png", assetName, (long)imagePlace];
                                                 UIImage *imageToSave = [UIImage imageWithCGImage:image];
                                                 NSURL *urlToSave = [NSURL fileURLWithPath:[[EFMediaManager saveVideosDirectory] stringByAppendingPathComponent:imageName]];
                                                 
                                                 //Save to cache
                                                 [[_EFMediaCacheManager sharedManager] setImage:imageToSave forKey:urlToSave.absoluteString];
                                                 //save to file
                                                 NSData * binaryImageData = UIImagePNGRepresentation(imageToSave);
                                                 [binaryImageData writeToFile:urlToSave.path atomically:YES];
                                                 
                                                 [urlToSave setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
                                             }
                                             
                                             if (result == AVAssetImageGeneratorFailed) {
                                                 NSLog(@"Failed with error: %@", [error localizedDescription]);
                                             }
                                             if (result == AVAssetImageGeneratorCancelled) {
                                                 NSLog(@"Canceled");
                                             }
                                         }];
}

- (NSString *)fileNameForAsset:(AVURLAsset *)asset
{
    NSString *fileName = [[asset URL] lastPathComponent];
    return fileName;
}

//////////////////////////////////////////////////////////////
#pragma mark - Media Items
//////////////////////////////////////////////////////////////
- (NSInteger)numberOfSections
{
    return [[self savedVideosURLsByDate] count];
}

- (NSInteger)numberOfRowsForSection:(NSInteger)section
{
    if (section < [[self savedVideosURLsByDate] count])
        return [[[self savedVideosURLsByDate] objectAtIndex:section] count];
    else
        return 0;
}

- (NSDate *)dateForSection:(NSInteger)section
{
    NSArray *row = [[self savedVideosURLsByDate] objectAtIndex:section];
    return [[[[row objectAtIndex:0] resourceValuesForKeys:[NSArray arrayWithObject:NSURLCreationDateKey] error:nil] objectForKey:NSURLCreationDateKey] dateWithoutTime];
}

- (AVURLAsset *)assetForIndexPath:(NSIndexPath *)indexPath
{
    NSURL *savedAssetURL = [self savedVideoURLAtIndexPath:indexPath];
    return [AVURLAsset URLAssetWithURL:savedAssetURL options:nil];
}

- (UIImage *)thumbnailForIndexPath:(NSIndexPath *)indexPath
{
    AVURLAsset *asset = [self assetForIndexPath:indexPath];
    return [EFMediaManager thumbnailFromAsset:asset];
}

- (NSArray *)thumbnailsForIndexPath:(NSIndexPath *)indexPath
{
    AVURLAsset *asset = [self assetForIndexPath:indexPath];
    return [EFMediaManager thumbnailsFromAsset:asset];
}

- (void)removeAssetAtIndexpath:(NSIndexPath *)indexPath callback:(EFMediaSaveBlock)callback
{
     AVURLAsset *asset = [self assetForIndexPath:indexPath];
    [EFMediaManager removeAsset:asset];
    [self resetSavedVideoURLs];
    if (callback) {
        callback (![[NSFileManager defaultManager] fileExistsAtPath:asset.URL.path], nil);
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Camera Roll
//////////////////////////////////////////////////////////////
- (void)attemtToSaveAssetToCameraRoll:(AVURLAsset *)asset withNotification:(BOOL)notification callback:(EFMediaSaveBlock)callback
{
    if ([self.assetLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:asset.URL]) {
        [self.assetLibrary writeVideoAtPathToSavedPhotosAlbum:asset.URL completionBlock:^(NSURL *assetURL, NSError *error1) {
            if (error1) {
                if (notification) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:EFMediaManagerSavedToCameraRollNotification object:nil userInfo:@{EFMediaManagerSaveWasSuccessfulKey: @NO}];
                }
                if (callback) {
                    callback (NO, nil);
                }
            } else {
                [self.assetLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                    if (asset) {
                        [self addAsset:asset toTapClipGroup:EFTapClipAlbumName callback:^(BOOL wasSuccessful, AVURLAsset *asset) {
                            if (notification) {
                                [[NSNotificationCenter defaultCenter] postNotificationName:EFMediaManagerSavedToCameraRollNotification object:nil userInfo:@{EFMediaManagerSaveWasSuccessfulKey: [NSNumber numberWithBool:wasSuccessful]}];
                            }
                            if (callback) {
                                callback (wasSuccessful, asset);
                            }
                        }];
                    }
                } failureBlock:^(NSError *error) {
                    NSLog(@"error retrieving asset = %@", error);
                    if (callback) {
                        callback (NO, nil);
                    }
                }];
            }
        }];
    } else {
        if (notification) {
            [[NSNotificationCenter defaultCenter] postNotificationName:EFMediaManagerSavedToCameraRollNotification object:nil userInfo:@{EFMediaManagerSaveWasSuccessfulKey: @NO}];
        }
        if (callback) {
            callback (NO, nil);
        }
    }
}

- (void)attemptToSaveAllAssetsToCameraRollThenDeleteWithCallback:(EFMediaSaveAllBlock)callback
{
    if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusDenied) {
        NSArray *savedURLs = [self savedVideosURLs];
        [Flurry logEvent:@"Move all videos to camera roll" timed:YES];
        [self saveVideos:[savedURLs mutableCopy] withCallback:^(NSArray *videos) {
            [Flurry endTimedEvent:@"Move all videos to camera roll" withParameters:@{@"videosMoved": [NSNumber numberWithDouble:[savedURLs count]]}];
            [self resetSavedVideoURLs];
            [[NSNotificationCenter defaultCenter] postNotificationName:EFMediaManagerSavedToCameraRollNotification object:nil userInfo:@{EFMediaManagerSaveWasSuccessfulKey: @YES}];
            if (callback) {
                callback (YES, nil);
            }
        }];
    } else {
        [Flurry logEvent:@"Attempted to Move Videos to Camera Roll With Access Denied"];
        [[NSNotificationCenter defaultCenter] postNotificationName:EFMediaManagerSavedToCameraRollNotification object:nil userInfo:@{EFMediaManagerSaveWasSuccessfulKey: @NO}];
        if (callback) {
            callback (NO, @"please allow this app access to your camera roll in settings to save");
        }
    }
}

- (void)saveVideos:(NSMutableArray *)videos withCallback:(EFMediaSaveReturnBlock)callback
{
    if ([videos count]) {
        NSURL *videoURL = [videos objectAtIndex:0];
        [videos removeObjectAtIndex:0];
        __weak EFMediaManager *weakSelf = self;
        [self.assetLibrary writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
            if (!error) {
                [self.assetLibrary assetForURL:assetURL resultBlock:^(ALAsset *cameraAsset) {
                    if (cameraAsset) {
                        [self addAsset:cameraAsset toTapClipGroup:[NSString stringWithFormat:@"%@ %@", EFTapClipAlbumName, [[NSDate date] shortDate]] callback:^(BOOL wasSuccessful, AVURLAsset *groupAsset) {
                            if (wasSuccessful) {
                                [weakSelf saveVideos:videos withCallback:callback];
                            } else {
                                [Flurry logError:@"Asset Not Saved to Group" message:@"" error:nil];
                                [weakSelf saveVideos:videos withCallback:callback];
                            }
                        }];
                        AVURLAsset *assetToRemove = [AVURLAsset URLAssetWithURL:videoURL options:nil];
                        [EFMediaManager removeAsset:assetToRemove];
                    } else {
                        [Flurry logError:@"Asset Not Returned" message:@"succeeded" error:nil];
                        [weakSelf saveVideos:videos withCallback:callback];
                    }
                } failureBlock:^(NSError *error) {
                    [Flurry logError:@"Asset Not Returned" message:error.localizedDescription error:error];
                    [weakSelf saveVideos:videos withCallback:callback];
                }];
            } else {
                [Flurry logError:@"Asset Not Saved to Camera Roll" message:error.localizedDescription error:error];
                [weakSelf saveVideos:videos withCallback:callback];
            }
        }];
    } else if (callback) {
        callback (nil);
    }
}

- (void)addAsset:(ALAsset *)asset toTapClipGroup:(NSString *)groupName callback:(EFMediaSaveBlock)callback
{
    [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:groupName]) {
            [group addAsset:asset];
            *stop = YES;
            if (callback) {
                callback (YES, nil);
            }
        }
        if(!group && !(*stop)) {
            [self.assetLibrary addAssetsGroupAlbumWithName:groupName resultBlock:^(ALAssetsGroup *group) {
                if (group) {
                    [group addAsset:asset];
                }
                if (callback) {
                    callback ((group ? YES : NO), nil);
                }
            } failureBlock:^(NSError *error) {
                if (callback) {
                    callback (NO, nil);
                }
            }];
        }
    } failureBlock:^(NSError *error) {
        if (callback) {
            callback (NO, nil);
        }
    }];
}

//////////////////////////////////////////////////////////////
#pragma mark - Class Methods
//////////////////////////////////////////////////////////////
+ (void)removeAsset:(AVURLAsset *)asset
{
    NSString *assetPath = asset.URL.path;
    for (NSInteger i = 0; i < 3; ++i) {
        unlink([[assetPath stringByAppendingString:[NSString stringWithFormat:@"-%ld.png", (long)i]] UTF8String]);
    }
    unlink([assetPath UTF8String]);
}

+ (UIImage *)createThumbnailFromAsset:(AVURLAsset *)asset
{
    NSString *key = [NSString stringWithFormat:@"%@.thumb", asset.URL.absoluteString];
    UIImage *thumbnail = [[_EFMediaCacheManager sharedManager] imageForKey:key];
    if (!thumbnail) {
        thumbnail = [self generateImageOfAsset:asset atTime:asset.duration];
        [[_EFMediaCacheManager sharedManager] setImage:thumbnail forKey:key];
    }
    return thumbnail;
}

+ (UIImage *)thumbnailFromAsset:(AVURLAsset *)asset
{
    UIImage *thumb = [[_EFMediaCacheManager sharedManager] imageForKey:asset.URL.absoluteString];
    if (!thumb) {
        NSString *imagePath = [NSString stringWithFormat:@"%@-2.png", asset.URL.path];
        thumb = [UIImage imageWithContentsOfFile:imagePath];
        if (thumb) {
            [[_EFMediaCacheManager sharedManager] setImage:thumb forKey:imagePath];
        }
    }
    return thumb;
}

+ (NSArray *)thumbnailsFromAsset:(AVURLAsset *)asset
{
    NSMutableArray *images = [NSMutableArray array];
    for (NSInteger i = 0; i < 3; ++i) {
        NSString *imagePath = [NSString stringWithFormat:@"%@-%ld.png", asset.URL.path, (long)i];
        UIImage *thumb = [[_EFMediaCacheManager sharedManager] imageForKey:imagePath];
        if (thumb) {
            [images addObject:thumb];
        } else {
            thumb = [UIImage imageWithContentsOfFile:imagePath];
            if (thumb) {
                [[_EFMediaCacheManager sharedManager] setImage:thumb forKey:imagePath];
                [images addObject:thumb];
            }
        }
    }
    return images;
}

+ (UIImage *)fullSizeCoverImageFromAsset:(AVURLAsset *)asset
{
    NSString *key = [NSString stringWithFormat:@"%@.cover", asset.URL.absoluteString];
    UIImage *fullImage = [[_EFMediaCacheManager sharedManager] imageForKey:key];
    if (!fullImage) {
        fullImage = [self generateImageOfAsset:asset atTime:asset.duration];
        [[_EFMediaCacheManager sharedManager] setImage:fullImage forKey:key];
    }
    return fullImage;
}

+ (UIImage *)fullSizeStartingImageFromAsset:(AVURLAsset *)asset
{
    NSString *key = [NSString stringWithFormat:@"%@.start", asset.URL.absoluteString];
    UIImage *fullImage = [[_EFMediaCacheManager sharedManager] imageForKey:key];
    if (!fullImage) {
        fullImage = [self generateImageOfAsset:asset atTime:kCMTimeZero];
        [[_EFMediaCacheManager sharedManager] setImage:fullImage forKey:key];
    }
    return fullImage;
}

+ (UIImage *)generateImageOfAsset:(AVURLAsset *)asset atTime:(CMTime)time
{
    CMTime actualTime;
    NSError *error = nil;
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
}

+ (NSString *)documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

+ (NSString *)saveVideosDirectory
{
    NSString *basePath = [[self documentsDirectory] stringByAppendingPathComponent:@"Save"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:basePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:basePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return basePath;
}

@end
