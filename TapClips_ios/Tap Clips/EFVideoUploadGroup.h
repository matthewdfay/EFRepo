//
//  EFVideoUploadGroup.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/20/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EFUploadManager.h"
#import <AWSS3/AWSS3.h>

@interface EFVideoUploadGroup : NSObject

- (id)initWithGroup:(NSString *)groupId videoRequest:(S3PutObjectRequest *)videoRequest imageRequest:(S3PutObjectRequest *)imageRequest andCompletionCallback:(EFUploadCallbackBlock)callback;

@property (nonatomic, strong, readonly) NSString *groupId;
@property (nonatomic, strong) NSError *error;

@end
