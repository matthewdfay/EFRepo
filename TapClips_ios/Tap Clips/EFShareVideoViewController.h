//
//  EFShareVideoViewController.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/14/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol EFShareVideoViewControllerDelegate;

@interface EFShareVideoViewController : UIViewController

+ (EFShareVideoViewController *)shareVideoController:(AVURLAsset *)asset withDelegate:(id<EFShareVideoViewControllerDelegate>)delegate;

@end

@protocol EFShareVideoViewControllerDelegate <NSObject>

@required
- (void)cancelShareSelected;

@end