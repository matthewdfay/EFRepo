//
//  EFVideoDetailCell.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/8/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

extern NSString * const EFVideoDetailCellIdentifier;

@protocol EFVideoDetailCellDelegate;

@interface EFVideoDetailCell : UICollectionViewCell

- (void)populateWithAsset:(AVURLAsset *)asset delegate:(id<EFVideoDetailCellDelegate>)delegate;

- (void)startPlayingVideo;
- (void)stopPlayingVideo;
- (void)restartVideo;
- (void)resetVideo;

@end

@protocol EFVideoDetailCellDelegate <NSObject>

@optional
- (void)videoStarted;
- (void)videoPaused;
- (void)videoEnded;

@end