//
//  EFUploadManager.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/20/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFUploadManager.h"
#import "EFUser.h"
#import "EFVideoUploadGroup.h"
#import "EFMediaManager.h"
#import "EFReachability.h"
#import "EFAPIClient.h"
#import "EFExtensions.h"

NSString * const EFVideoBeganUplaodingToAPINotification = @"videoBeganUplaodingToAPI";
NSString * const EFVideoPostedToAPINotification = @"videoUploadedToAPI";
NSString * const EFVideoPostedToAPIWasSuccessfulKey = @"wasSuccessful";
NSString * const EFVideoPostedToAPIMessageKey = @"message";

NSString * const EFAWSBucketKey = @"tclip.tv";
NSString * const EFAWSVideoContentType = @"video/mp4";
NSString * const EFAWSImageContentType = @"image/jpeg";

static NSString * const EFNetworkFailureMessage = @"No Internet Connection";

//TODO: store keys elsewhere
static NSString * const EFAWSAccessKey = @"AKIAJEEP7WDNBI2Z7YBQ";
static NSString * const EFAWSSecretKey = @"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";

@interface EFUploadManager () <AmazonServiceRequestDelegate>

@property (nonatomic, strong, readwrite) AmazonS3Client *client;
@property (nonatomic, strong, readwrite) S3TransferManager *transferManager;
@property (nonatomic, strong) NSMutableSet *groups;

@end

@implementation EFUploadManager{
    dispatch_queue_t _concurrentUploadQueue;
}

+ (EFUploadManager *)sharedManager
{
    static EFUploadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EFUploadManager alloc] init];
    });
    return manager;
}

- (id)init
{
    self = [super init];
    if (self) {
        _concurrentUploadQueue = dispatch_queue_create("com.elementalfoundry.ios.sprio-upload-images-queue", DISPATCH_QUEUE_CONCURRENT);
        
        self.client = [[AmazonS3Client alloc] initWithAccessKey:EFAWSAccessKey withSecretKey:EFAWSSecretKey];
        self.client.endpoint = [AmazonEndpoints s3Endpoint:US_EAST_1];
        self.transferManager = [[S3TransferManager alloc] init];
        self.transferManager.s3 = self.client;
        self.transferManager.delegate = self;
        
        self.groups = [NSMutableSet set];
    }
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark - Video Upload
//////////////////////////////////////////////////////////////
- (void)uploadVideo:(AVURLAsset *)videoAsset withCallback:(EFUploadCallbackBlock)callback
{
    dispatch_async(_concurrentUploadQueue, ^{
        [self addVideoToNewGroup:videoAsset withCallback:callback];
    });
}

- (void)addVideoToNewGroup:(AVURLAsset *)video withCallback:(EFUploadCallbackBlock)callback
{
    NSString *groupId = [UIApplication createUniqueIdentifier];
    S3PutObjectRequest *videoRequest = [self createRequestForVideo:video inGroup:groupId];
    S3PutObjectRequest *imageRequest = [self createRequestForImage:[EFMediaManager fullSizeCoverImageFromAsset:video] inGroup:groupId];
    __block EFVideoUploadGroup *group = nil;
    group = [self createGroup:groupId forVideoRequest:videoRequest andImageRequest:imageRequest callback:^(BOOL wasSuccessful, id response) {
        [self removeGroup:group];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback (wasSuccessful, response);
            }
        });
    }];
    
    [self addGroup:group];
}

- (S3PutObjectRequest *)createRequestForVideo:(AVURLAsset *)video inGroup:(NSString *)groupId
{
    NSString *videoName = [NSString stringWithFormat:@"upload/clips/%@/%@%@", groupId, [UIApplication createUniqueIdentifier], EFClipExtensionType];
    //TODO: store the unique identifier as the key for the size, location, direction, ect
    
    NSData *videoData = [self dataFromVideoAsset:video];
    
    S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:videoName inBucket:EFAWSBucketKey];
    por.contentType = EFAWSVideoContentType;
    por.cannedACL   = [S3CannedACL publicRead];
    por.data        = videoData;
    por.requestTag  = videoName;
    return por;
}

- (S3PutObjectRequest *)createRequestForImage:(UIImage *)image inGroup:(NSString *)groupId
{
    NSString *ImageName = [NSString stringWithFormat:@"upload/clips/%@/%@", groupId, [UIApplication createUniqueIdentifier]];
    
    S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:ImageName inBucket:EFAWSBucketKey];
    por.contentType = EFAWSImageContentType;
    por.cannedACL   = [S3CannedACL publicRead];
    por.data        = UIImageJPEGRepresentation(image, 0.0);;
    por.requestTag  = ImageName;
    return por;
}

- (NSData *)dataFromVideoAsset:(AVURLAsset *)videoAsset
{
    return [NSData dataWithContentsOfURL:videoAsset.URL];
}

//////////////////////////////////////////////////////////////
#pragma mark - Upload to Social
//////////////////////////////////////////////////////////////
- (void)uploadVideo:(AVURLAsset *)videoAsset toSocialMedia:(NSDictionary *)socialDict withMessage:(NSString *)message callback:(EFUploadCallbackBlock)callback
{
    __block NSDictionary *newSocialDictionary = [socialDict copy];
    __block NSString *messageString = [message copy];
    if ([socialDict objectForKey:@"fb" defaultValue:nil]) {
        [[EFUser currentUser] connectUserWithFacebookShareCallback:^(BOOL wasSuccessful, NSString *message) {
            [self uploadVideo:videoAsset toUpdatedSocialMedia:newSocialDictionary withMessage:messageString callback:callback];
        }];
    } else {
        [self uploadVideo:videoAsset toUpdatedSocialMedia:newSocialDictionary withMessage:message callback:callback];
    }
    
}

- (void)uploadVideo:(AVURLAsset *)videoAsset toUpdatedSocialMedia:(NSDictionary *)socialDict withMessage:(NSString *)message callback:(EFUploadCallbackBlock)callback
{
    __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
    }];
    if ([EFReachability isNetworkReachable]) {
        [self postVideoBeganUploadingToAPINotification];
        [self uploadVideo:videoAsset withCallback:^(BOOL wasSuccessful, id response) {
            if (wasSuccessful) {
                [self uploadVideoURL:response toSocialMedia:socialDict withMessage:message andVideoInfo:[self infoForVideo:videoAsset] callback:^(BOOL wasSuccessful, id response) {
                    [self postVideoUploadedToAPINotification:wasSuccessful];
                    [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                    if (callback) {
                        callback (wasSuccessful, response);
                    }
                }];
            } else {
                [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                if (callback) {
                    callback (wasSuccessful, response);
                }
            }
        }];
    } else if (callback) {
        callback (NO, EFNetworkFailureMessage);
    }
}

- (void)uploadVideoURL:(NSDictionary *)videoURLs toSocialMedia:(NSDictionary *)socialDict withMessage:(NSString *)message andVideoInfo:(NSDictionary *)videoInfo callback:(EFUploadCallbackBlock)callback
{
    [[EFAPIClient sharedClient] createPostWithDescription:message attachments:videoURLs shareDict:socialDict andVideoInfo:videoInfo success:^(BOOL wasSuccessful, id response, id cache) {
        if (callback) {
            callback (wasSuccessful, response);
        }
    } failure:^(NSError *error) {
        if (callback) {
            callback (NO, error.localizedDescription);
        }
    }];
}

- (void)postVideoBeganUploadingToAPINotification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:EFVideoBeganUplaodingToAPINotification object:nil userInfo:nil];
    });
}

- (void)postVideoUploadedToAPINotification:(BOOL)wasSuccessful
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:EFVideoPostedToAPINotification object:nil userInfo:@{EFVideoPostedToAPIWasSuccessfulKey: [NSNumber numberWithBool:wasSuccessful]}];
    });
}

- (NSDictionary *)infoForVideo:(AVURLAsset *)asset
{
    NSMutableDictionary *videoInfo = [NSMutableDictionary dictionary];
    
    //size
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize size = [videoTrack naturalSize];
    [videoInfo setObject:@[[NSNumber numberWithInteger:size.width], [NSNumber numberWithInteger:size.height]] forKey:@"size"];
    
    //duration
    [videoInfo setObject:[NSNumber numberWithDouble:CMTimeGetSeconds(asset.duration)] forKey:@"duration"];
    
    //location
    NSArray *locationItems = [AVMetadataItem metadataItemsFromArray:[asset commonMetadata] withKey:AVMetadataCommonKeyLocation keySpace:AVMetadataKeySpaceCommon];
    if ([locationItems count]) {
        [videoInfo setObject:((AVMetadataItem *)[locationItems objectAtIndex:0]).value forKey:@"location"];
    }
    return videoInfo;
}

//////////////////////////////////////////////////////////////
#pragma mark - Upload to Private
//////////////////////////////////////////////////////////////
- (void)uploadVideo:(AVURLAsset *)videoAsset toURL:(NSDictionary *)urlDict callback:(EFUploadCallbackBlock)callback
{
    __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
    }];

    if ([EFReachability isNetworkReachable]) {
        [self uploadVideo:videoAsset withCallback:^(BOOL wasSuccessful, id response) {
            if (wasSuccessful) {
                [self uploadVideoURL:response toURL:urlDict withVideoInfo:[self infoForVideo:videoAsset] callback:^(BOOL wasSuccessful, id response) {
                    [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                    if (callback) {
                        callback (wasSuccessful, response);
                    }
                }];
            } else {
                [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                if (callback) {
                    callback (wasSuccessful, response);
                }
            }
        }];
    } else if (callback) {
        callback (NO, EFNetworkFailureMessage);
    }
}

- (void)uploadVideoURL:(NSDictionary *)videoURLs toURL:(NSDictionary *)urlDict withVideoInfo:(NSDictionary *)videoInfo callback:(EFUploadCallbackBlock)callback
{
    [[EFAPIClient sharedClient] createPostWithAttachments:videoURLs toShareURL:urlDict withVideoInfo:videoInfo success:^(BOOL wasSuccessful, id response, id cache) {
        if (callback) {
            callback (wasSuccessful, response);
        }
    } failure:^(NSError *error) {
        if (callback) {
            callback (NO, error.localizedDescription);
        }
    }];
}

//////////////////////////////////////////////////////////////
#pragma mark - Image Upload Helpers
//////////////////////////////////////////////////////////////
- (EFVideoUploadGroup *)createGroup:(NSString *)groupId forVideoRequest:(S3PutObjectRequest *)request andImageRequest:(S3PutObjectRequest *)imageRequest callback:(EFUploadCallbackBlock)callback
{
    return [[EFVideoUploadGroup alloc] initWithGroup:groupId videoRequest:request imageRequest:imageRequest andCompletionCallback:callback];
}

- (void)addGroup:(EFVideoUploadGroup *)group
{
    @synchronized(self) {
        [self.groups addObject:group];
    }
}

- (void)removeGroup:(EFVideoUploadGroup *)group
{
    @synchronized(self) {
        NSAssert([self.groups containsObject:group], @"Must have group to remove it");
        [self.groups removeObject:group];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Cancel
//////////////////////////////////////////////////////////////
- (void)cancelAllUploads
{
    [self.transferManager cancelAllTransfers];
}

@end
