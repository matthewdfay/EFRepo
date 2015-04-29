//
//  EFImage.h
//  TapClips
//
//  Created by Matthew Fay on 6/4/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EFNetworkRequest.h"

typedef enum : NSInteger {
    EFImageSizeThumbnail = 0,
    EFImageSizeLarge
} EFImageSize;

typedef void(^EFImageFetchCallback)(UIImage *image, BOOL wasCached);

@interface EFImage : NSObject

/**
 returns an EFImage instance.
 */
+ (instancetype)imageWithURLString:(NSString *)URLString;
- (id)initWithURLString:(NSString *)URLString;

/**
 fetches the image of a specified size at the given URL and calls back when loaded.
 
 NOTE: if the image is in cache, does not go to network.
 */
+ (EFImageRequest *)fetchImageWithString:(NSString *)URLString size:(EFImageSize)size callback:(EFImageFetchCallback)callback;
- (EFImageRequest *)fetchImageWithSize:(EFImageSize)size callback:(EFImageFetchCallback)callback;

/**
 returns an image if cached.
 */
- (UIImage *)imageWithSize:(EFImageSize)size;
- (UIImage *)imageWithLargestSize;
- (UIImage *)imageWithAtLeastSize:(EFImageSize)size;

@end
