//
//  EFVideoUploadGroup.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/20/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFVideoUploadGroup.h"
#import "EFExtensions.h"
#import "Flurry.h"
#import <AWSS3/AWSS3.h>

@interface EFVideoUploadGroup () <AmazonServiceRequestDelegate>

@property (nonatomic, strong, readwrite) NSString *groupId;
@property (nonatomic, copy) EFUploadCallbackBlock completionBlock;
@property (nonatomic, strong) NSString *videoURL;
@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, strong) S3PutObjectRequest *videoRequest;
@property (nonatomic, strong) S3PutObjectRequest *imageRequest;

@end

@implementation EFVideoUploadGroup

- (id)initWithGroup:(NSString *)groupId videoRequest:(S3PutObjectRequest *)videoRequest imageRequest:(S3PutObjectRequest *)imageRequest andCompletionCallback:(EFUploadCallbackBlock)callback;
{
    self = [super init];
    if (self) {
        _groupId = groupId;
        _completionBlock = callback;
        _videoRequest = videoRequest;
        _videoRequest.delegate = self;
        _imageRequest = imageRequest;
        _imageRequest.delegate = self;
        
        @try {
            [[[EFUploadManager sharedManager] transferManager] upload:_videoRequest];
        }
        @catch (NSException *exception) {
            [Flurry logError:@"Error Uploading Video" message:exception.name exception:exception];
        }
        
        @try {
            [[[EFUploadManager sharedManager] transferManager] upload:_imageRequest];
        }
        @catch (NSException *exception) {
            [Flurry logError:@"Error Uploading Video Image" message:exception.name exception:exception];
        }
    }
    return self;
}

- (EFUploadCallbackBlock)getCompletionBlock
{
    EFUploadCallbackBlock callback = nil;
    if (self.completionBlock) {
        callback = self.completionBlock;
        self.completionBlock = nil;
    }
    return callback;
}

//////////////////////////////////////////////////////////////
#pragma mark - Amazon Delegate
//////////////////////////////////////////////////////////////
-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    if (response.error) {
        [self didRecieveURL:nil fromResponse:response andRequest:request withError:response.error];
    } else {
        NSString * contentType = (request == self.videoRequest ? EFAWSVideoContentType : nil);
        if (!contentType && request == self.imageRequest) {
            contentType = EFAWSImageContentType;
        }
        [self getURLFromResponse:response withContentType:contentType request:request];
    }
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError called: %@", error);
    [self didRecieveURL:nil fromResponse:nil andRequest:request withError:error];
}

- (void)didRecieveURL:(NSURL *)contentURL fromResponse:(AmazonServiceResponse *)response andRequest:(AmazonServiceRequest *)request withError:(NSError *)error
{
    EFUploadCallbackBlock callback = nil;
    BOOL isVideo = NO;
    BOOL isImage = NO;
    @synchronized(self)
    {
        if ([request.requestTag isEqualToString:self.videoRequest.requestTag]) {
            self.videoRequest = nil;
            isVideo = YES;
        }
        if ([request.requestTag isEqualToString:self.imageRequest.requestTag]) {
            self.imageRequest = nil;
            isImage = YES;
        }

        if (!self.error) {
            if (error) {
                self.error = error;
                callback = [self getCompletionBlock];
            } else {
                if (contentURL.absoluteString.length > 0) {
                    if (isVideo) {
                        self.videoURL = contentURL.absoluteString;
                    } else if (isImage) {
                        self.imageURL = contentURL.absoluteString;
                    }
                }
                if (!self.error && !self.videoRequest && !self.imageRequest) {
                    callback = [self getCompletionBlock];
                }
            }
        }
    }
    
    if (callback) {
        if (self.error)
            callback (NO, error.localizedDescription);
        else {
            NSMutableDictionary *returnDict = [NSMutableDictionary dictionary];
            if (self.videoURL.length) {
                [returnDict setObject:[self.videoURL copy] forKey:@"url"];
            }
            if (self.imageURL.length) {
                [returnDict setObject:[self.imageURL copy] forKey:@"imgUrl"];
            }
            callback (YES, returnDict);
        }
    }
}

- (void)getURLFromResponse:(AmazonServiceResponse *)response withContentType:(NSString *)contentType request:(AmazonServiceRequest *)request
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        // Set the content type so that the browser will treat the URL as an image.
        S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
        override.contentType = contentType;
        
        // Request a pre-signed URL to picture that has been uplaoded.
        S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
        gpsur.key                     = request.requestTag;
        gpsur.bucket                  = EFAWSBucketKey;
        gpsur.expires                 = [NSDate oneYearFromNow];
        gpsur.responseHeaderOverrides = override;
        
        // Get the URL
        NSError *error;
        NSURL *url = [[[EFUploadManager sharedManager] client] getPreSignedURL:gpsur error:&error];
        NSURL *pathURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@%@", url.host, url.path]];
        [self didRecieveURL:pathURL fromResponse:response andRequest:request withError:error];
        
    });
}

@end
