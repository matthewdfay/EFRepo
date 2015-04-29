//
//  EFTwitterRequest.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/25/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^EFTwittherSignedRequestHandler) (NSData *data, NSURLResponse *response, NSError *error);

@interface EFTwitterRequest : NSObject

+ (void)performRequestTokenFetchWithCallback:(EFTwittherSignedRequestHandler)callback;

@end
