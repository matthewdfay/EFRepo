//
//  EFVideoPreviewCollectionViewCell.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/24/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

extern NSString * const EFVideoPreviewCollectionViewCellIdentifier;

@interface EFVideoPreviewCollectionViewCell : UICollectionViewCell

- (void)populateWithLoadingIndicator:(NSNumber *)duration;

- (void)populateWithAsset:(AVURLAsset *)asset;
- (void)populateWithAsset:(AVURLAsset *)asset animated:(BOOL)animated;
- (void)populateWithError;

@end
