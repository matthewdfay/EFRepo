//
//  EFUploadManager.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/20/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/S3TransferManager.h>
#import <AWSS3/AWSS3.h>
#import <AVFoundation/AVFoundation.h>


typedef void(^EFUploadCallbackBlock)(BOOL wasSuccessful, id response);

extern NSString * const EFVideoBeganUplaodingToAPINotification;
extern NSString * const EFVideoPostedToAPINotification;
extern NSString * const EFVideoPostedToAPIWasSuccessfulKey;
extern NSString * const EFVideoPostedToAPIMessageKey;

extern NSString * const EFAWSBucketKey;
extern NSString * const EFAWSVideoContentType;
extern NSString * const EFAWSImageContentType;

@interface EFUploadManager : NSObject

+ (EFUploadManager *)sharedManager;

@property (nonatomic, strong, readonly) AmazonS3Client *client;
@property (nonatomic, strong, readonly) S3TransferManager *transferManager;

/**
 Uploads a single or multiple images and calls back when all have been uploaded.
 If successful, the response contains an array of URLs to the uploaded images.
 Else, the response contains the error.
 */
- (void)uploadVideo:(AVURLAsset *)videoAsset withCallback:(EFUploadCallbackBlock)callback;

/**
 Uploads the video then posts the video to the given social media outlets.
 */
- (void)uploadVideo:(AVURLAsset *)videoAsset toSocialMedia:(NSDictionary *)socialDict withMessage:(NSString *)message callback:(EFUploadCallbackBlock)callback;

/**
 Uploads the video then tells the server what URL to use.
 
 NOTE: only for "private" sharing.
 */
- (void)uploadVideo:(AVURLAsset *)videoAsset toURL:(NSDictionary *)urlDict callback:(EFUploadCallbackBlock)callback;

/**
 Cancels all current uploads.
 */
- (void)cancelAllUploads;
@end
