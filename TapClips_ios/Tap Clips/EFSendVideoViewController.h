//
//  EFSendVideoViewController.h
//  TapClips
//
//  Created by Matthew Fay on 5/14/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef enum : NSInteger
{
    EFSendVideoTypeFacebook = 0,
    EFSendVideoTypeTwitter,
    EFSendVideoTypeSprio
} EFSendVideoType;

@protocol EFSendVideoViewControllerDelegate;

@interface EFSendVideoViewController : UIViewController
+ (EFSendVideoViewController *)sendVideoControllerForType:(EFSendVideoType)type withAsset:(AVURLAsset *)asset title:(NSString *)title imageURL:(NSString *)imageURL andDelegate:(id<EFSendVideoViewControllerDelegate>)delegate;
@end

@protocol EFSendVideoViewControllerDelegate <NSObject>

@required
- (void)dismissSendViewController;
- (void)shareToSocialMediaType:(EFSendVideoType)type withMessage:(NSString *)message;

@end