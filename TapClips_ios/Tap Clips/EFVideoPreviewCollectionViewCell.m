//
//  EFVideoPreviewCollectionViewCell.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/24/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFVideoPreviewCollectionViewCell.h"
#import "EFLoadingView.h"
#import "EFMediaManager.h"

NSString * const EFVideoPreviewCollectionViewCellIdentifier = @"videoPreviewCollectionViewCell";

@interface EFVideoPreviewCollectionViewCell ()
@property (nonatomic, weak) IBOutlet UIImageView *videoImageView;
@property (nonatomic, weak) IBOutlet EFLoadingView *animationView;
@end

@implementation EFVideoPreviewCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.videoImageView.layer.shadowRadius = 3.0;
    self.videoImageView.layer.shadowOpacity = 1.0;
    self.videoImageView.layer.masksToBounds = NO;
    self.videoImageView.layer.shadowOffset = CGSizeZero;
    [self resetCell];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self resetCell];
}

- (void)populateWithLoadingIndicator:(NSNumber *)duration
{
    self.videoImageView.hidden = YES;
    self.animationView.hidden = NO;
    [self.animationView beginAnimationgWithDuration:duration];
}

- (void)populateWithAsset:(AVURLAsset *)asset
{
    [self populateWithAsset:asset animated:NO];
}

- (void)populateWithAsset:(AVURLAsset *)asset animated:(BOOL)animated
{
    if (asset) {
        self.videoImageView.image = [EFMediaManager createThumbnailFromAsset:asset];
        self.videoImageView.alpha = 0.0;
        self.videoImageView.hidden = NO;
        [UIView animateWithDuration:(animated ? 0.25 : 0.0) animations:^{
            self.videoImageView.alpha = 1.0;
        } completion:^(BOOL finished) {
            [self.animationView endAnimating];
            self.animationView.hidden = YES;
        }];
    } else {
        [self resetCell];
    }
}

- (void)populateWithError
{
    [self.animationView displayError];
}

- (void)resetCell
{
    [self.animationView endAnimating];
    self.animationView.hidden = YES;
    self.videoImageView.hidden = YES;
    self.videoImageView.image = nil;
}

@end
