//
//  EFVideoDetailCell.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/8/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFVideoDetailCell.h"
#import "EFMediaManager.h"
#import "Flurry.h"
#import "EFExtensions.h"
#import <MediaPlayer/MediaPlayer.h>

NSString * const EFVideoDetailCellIdentifier = @"videoDetailCell";

@interface EFVideoDetailCell () <UIGestureRecognizerDelegate>
@property (nonatomic, weak) IBOutlet UIView *videoView;
@property (nonatomic, weak) IBOutlet UIImageView *videoImageView;
@property (nonatomic, strong) AVPlayer *mediaPlayer;
@property (nonatomic, strong) AVPlayerLayer *mediaPlayerLayer;
@property (nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) id<EFVideoDetailCellDelegate> delegate;
@property (nonatomic, assign) BOOL restart;
@end

@implementation EFVideoDetailCell

- (AVPlayer *)mediaPlayerWithPlayerItem:(AVPlayerItem *)item
{
    if (self.mediaPlayer) {
        [self.mediaPlayer replaceCurrentItemWithPlayerItem:item];
    } else {
        self.mediaPlayer = [AVPlayer playerWithPlayerItem:item];
    }
    return self.mediaPlayer;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupTapGestures];
}

- (void)dealloc
{
    [self endListeningForNotifications];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.restart = NO;
    self.asset = nil;
    self.delegate = nil;
    self.playerItem = nil;
    self.videoImageView.image = nil;
    [self stopPlayingVideo];
    [self.mediaPlayerLayer removeFromSuperlayer];
    self.mediaPlayerLayer = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.mediaPlayerLayer.frame = self.videoView.bounds;
}

- (void)populateWithAsset:(AVURLAsset *)asset delegate:(id<EFVideoDetailCellDelegate>)delegate
{
    self.asset = asset;
    self.delegate = delegate;
    if (asset) {
        self.videoImageView.image = [EFMediaManager fullSizeStartingImageFromAsset:asset];
        self.playerItem = [[AVPlayerItem alloc] initWithAsset:self.asset];
        [self mediaPlayerWithPlayerItem:self.playerItem];
        [self.mediaPlayer seekToTime:kCMTimeZero];
        self.mediaPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.mediaPlayer];
        self.mediaPlayerLayer.frame = self.videoView.bounds;
        if (EF_IS_IPHONE) {
            self.mediaPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        }
        [self.videoView.layer addSublayer:self.mediaPlayerLayer];

        [self layoutIfNeeded];
    }
}

- (void)startPlayingVideo
{
    [self beginListeningForNotifications];
    self.mediaPlayer.rate = 1.0;
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoStarted)]) {
        [self.delegate videoStarted];
    }
}

- (void)stopPlayingVideo
{
    [self endListeningForNotifications];
    self.mediaPlayer.rate = 0.0;
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPaused)]) {
        [self.delegate videoPaused];
    }
}

- (void)resetVideo
{
    self.restart = NO;
    [self.mediaPlayer seekToTime:kCMTimeZero];
}

- (void)restartVideo
{
    [Flurry logEvent:@"Video Restarted"];
    [self resetVideo];
    [self startPlayingVideo];
}

//////////////////////////////////////////////////////////////
#pragma mark - Gestures
//////////////////////////////////////////////////////////////
- (void)setupTapGestures
{
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellPressed:)];
    self.tapGesture.delegate = self;
    [self.videoView addGestureRecognizer:self.tapGesture];
}

- (void)cellPressed:(NSNotification *)note
{
    if (self.restart) {
        [self restartVideo];
    } else if (self.mediaPlayer.rate > 0.9) {
        [self stopPlayingVideo];
    } else {
        [self startPlayingVideo];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Notifications
//////////////////////////////////////////////////////////////
- (void)beginListeningForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)endListeningForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)itemDidFinishPlaying:(NSNotification *)note
{
    if ([note object] == self.playerItem && self.delegate && [self.delegate respondsToSelector:@selector(videoEnded)]) {
        self.restart = YES;
        [self.delegate videoEnded];
    }
}

@end
