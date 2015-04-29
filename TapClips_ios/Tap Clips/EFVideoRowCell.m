//
//  EFVideoRowCell.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/4/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFVideoRowCell.h"
#import "EFMediaManager.h"
#import "EFExtensions.h"

NSString * const EFVideoRowCellIdentifier = @"videoRowCell";

@interface EFVideoRowCell ()

@property (nonatomic, weak) IBOutlet UIImageView *firstImage;
@property (nonatomic, weak) IBOutlet UILabel *durationlabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@end

@implementation EFVideoRowCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.firstImage.image = nil;
    self.durationlabel.text = @"";
    self.dateLabel.text = @"";
}

- (void)populateWithAsset:(AVURLAsset *)asset
{
    self.firstImage.image = [EFMediaManager thumbnailFromAsset:asset];
    [self populateDurationLabelWithAsset:asset];
    [self populateDateLabelWithAsset:asset];
}

- (void)populateDurationLabelWithAsset:(AVURLAsset *)asset
{
    NSNumber *duration = [NSNumber numberWithFloat:round(CMTimeGetSeconds(asset.duration))];
    self.durationlabel.text = [NSString stringWithFormat:@"%@ seconds", duration];
}

- (void)populateDateLabelWithAsset:(AVURLAsset *)asset
{
    NSDate *date = [[asset.URL resourceValuesForKeys:[NSArray arrayWithObject:NSURLCreationDateKey] error:nil] objectForKey:NSURLCreationDateKey];
    if (date) {
        if ([date isToday]) {
            self.dateLabel.text = [NSString stringWithFormat:@"%@", [date timeSinceDate]];
        } else {
            self.dateLabel.text = [NSString stringWithFormat:@"%@", [date time]];
        }
    }
}

@end
