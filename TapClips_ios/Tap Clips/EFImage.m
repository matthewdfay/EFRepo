//
//  EFImage.m
//  TapClips
//
//  Created by Matthew Fay on 6/4/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFImage.h"
#import "Flurry.h"

//////////////////////////////////////////////////////////////
// _EFImageGlobalCacheManager
//////////////////////////////////////////////////////////////
@interface _EFImageGlobalCacheManager : NSObject
@property (nonatomic, strong) NSCache *imageCache;
+ (instancetype)sharedManager;

- (UIImage *)imageWithURL:(NSURL *)url;
- (void)setImage:(UIImage *)image withURL:(NSURL *)url;
@end

@implementation _EFImageGlobalCacheManager

+ (instancetype)sharedManager
{
    static _EFImageGlobalCacheManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[_EFImageGlobalCacheManager alloc] init];
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

- (UIImage *)imageWithURL:(NSURL *)url
{
    return [self.imageCache objectForKey:url];
}

- (void)setImage:(UIImage *)image withURL:(NSURL *)url
{
    [self.imageCache setObject:image forKey:url cost:(NSUInteger)image.size.width];
}

@end


//////////////////////////////////////////////////////////////
// EFImage
//////////////////////////////////////////////////////////////
@class EFImageRequest;

@interface EFImage ()
@property (nonatomic, copy) NSString *baseImageString;
@end

@implementation EFImage

+ (instancetype)imageWithURLString:(NSString *)URLString
{
    return [[self alloc] initWithURLString:URLString];
}

- (id)initWithURLString:(NSString *)URLString
{
    self = [super init];
    if (self) {
        _baseImageString = [URLString copy];
    }
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark - Fetching
//////////////////////////////////////////////////////////////
+ (EFImageRequest *)fetchImageWithString:(NSString *)URLString size:(EFImageSize)size callback:(EFImageFetchCallback)callback
{
    EFImage *imageInstance = [EFImage imageWithURLString:URLString];
    return [imageInstance fetchImageWithSize:size callback:callback];
}

- (EFImageRequest *)fetchImageWithSize:(EFImageSize)size callback:(EFImageFetchCallback)callback
{
    EFImageRequest *request = nil;
    if ([self canFetchImageWithCurrentBaseString]) {
        BOOL didLoadFromCache = [self attemptToFetchChachedImageWithSize:size callback:callback];
        if (!didLoadFromCache) {
            request = [self executeFetchWithSize:size callback:callback];
        }
    } else {
        [self handleFailedRequestWithCallback:callback];
    }
    
    
    return request;
}

- (BOOL)attemptToFetchChachedImageWithSize:(EFImageSize)size callback:(EFImageFetchCallback)callback
{
    UIImage *cachedImage = [self imageWithSize:size];
    if (cachedImage) {
        if (callback)
            callback(cachedImage, YES);
        return YES;
    }
    return NO;
}

//////////////////////////////////////////////////////////////
#pragma mark - Execute Fetch
//////////////////////////////////////////////////////////////
- (EFImageRequest *)executeFetchWithSize:(EFImageSize)size callback:(EFImageFetchCallback)callback
{
    NSURLRequest *request = [self URLRequestForSize:size];
    return [self executeImageRequest:request withCallback:callback];
}

- (EFImageRequest *)executeImageRequest:(NSURLRequest *)request withCallback:(EFImageFetchCallback)callback
{
    return [EFImageRequest sendRequest:request success:^(NSHTTPURLResponse *response, id responseObject) {
        [self handleSuccessfulRequestWithResponse:responseObject URL:request.URL callback:callback];
    } failure:^(NSError *error) {
        [Flurry logError:@"Error Fetching Image" message:error.localizedDescription error:error];
        [self handleFailedRequestWithCallback:callback];
    }];
}

//////////////////////////////////////////////////////////////
#pragma mark - Request Handling
//////////////////////////////////////////////////////////////
- (void)handleSuccessfulRequestWithResponse:(id)response URL:(NSURL *)origionalURL callback:(EFImageFetchCallback)callback
{
    if ([self isResponseObjectImage:response]) {
        [[_EFImageGlobalCacheManager sharedManager] setImage:response withURL:origionalURL];
        if (callback)
            callback(response, NO);
    } else {
        [self handleFailedRequestWithCallback:callback];
    }
}

- (void)handleFailedRequestWithCallback:(EFImageFetchCallback)callback
{
    if (callback)
        callback(nil, NO);
}

//////////////////////////////////////////////////////////////
#pragma mark - Image
//////////////////////////////////////////////////////////////
- (UIImage *)imageWithSize:(EFImageSize)size
{
    NSURL *imageURL = [self URLForSize:size];
    return [[_EFImageGlobalCacheManager sharedManager] imageWithURL:imageURL];
}

- (UIImage *)imageWithLargestSize
{
    UIImage *image = nil;
    for (EFImageSize currentSize = EFImageSizeLarge; currentSize >= EFImageSizeThumbnail; currentSize--) {
        image = [self imageWithSize:currentSize];
        
        if (image) break;
    }
    return image;
}

- (UIImage *)imageWithAtLeastSize:(EFImageSize)size
{
    UIImage *image = nil;
    for (EFImageSize currentSize = size; currentSize <= EFImageSizeLarge; currentSize++) {
        image = [self imageWithSize:currentSize];
        
        if (image) break;
    }
    return image;
}

//////////////////////////////////////////////////////////////
#pragma mark - Fetching Helper Methods
//////////////////////////////////////////////////////////////
- (NSURLRequest *)URLRequestForSize:(EFImageSize)size
{
    NSURL *imageURL = [self URLForSize:size];
    return [NSURLRequest requestWithURL:imageURL];
}

- (NSURL *)URLForSize:(EFImageSize)size
{
    //TODO: change this when we change the size of the images
    return [NSURL URLWithString:self.baseImageString];
}

- (BOOL)isResponseObjectImage:(id)response
{
    return [response isKindOfClass:[UIImage class]];
}

- (BOOL)canFetchImageWithCurrentBaseString
{
    return self.baseImageString.length > 0;
}

@end
