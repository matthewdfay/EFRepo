//
//  EFShareVideoCollectionViewCell.m
//  TapClips
//
//  Created by Matthew Fay on 6/11/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFShareVideoCollectionViewCell.h"

NSString * const EFShareVideoCollectionViewCellIdentifier = @"shareVideoCollectionViewCell";

@interface EFShareVideoCollectionViewCell ()
@property (nonatomic, assign) EFShareVideoType type;
@property (nonatomic, weak) IBOutlet UIImageView *cellImageView;
@property (nonatomic, weak) IBOutlet UILabel *cellTitleLabel;
@end

@implementation EFShareVideoCollectionViewCell

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    self.cellImageView.image = [self imageForType:self.type selected:(self.highlighted || self.selected)];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.cellImageView.image = [self imageForType:self.type selected:(self.highlighted || self.selected)];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.type = -1;
    self.cellImageView.image = nil;
    self.cellTitleLabel.text = @"";
}

- (void)populateWithType:(EFShareVideoType)type
{
    self.type = type;
    self.cellImageView.image = [self imageForType:type selected:self.selected];
    self.cellTitleLabel.text = [self titleForType:type];
}

- (UIImage *)imageForType:(EFShareVideoType)type selected:(BOOL)selected
{
    UIImage *image = nil;
    
    if (type == EFShareVideoTypeFacebook) {
        image = [UIImage imageNamed:[NSString stringWithFormat:@"icon-facebook%@", (selected ? @"-selected" : @"")]];
    } else if (type == EFShareVideoTypeTwitter) {
        image = [UIImage imageNamed:[NSString stringWithFormat:@"icon-twitter%@", (selected ? @"-selected" : @"")]];
    } else if (type == EFShareVideoTypeSprio) {
        image = [UIImage imageNamed:[NSString stringWithFormat:@"icon-sprio%@", (selected ? @"-selected" : @"")]];
    } else if (type == EFShareVideoTypeMessage) {
        image = [UIImage imageNamed:[NSString stringWithFormat:@"icon-message%@", (selected ? @"-selected" : @"")]];
    } else if (type == EFShareVideoTypeMail) {
        image = [UIImage imageNamed:[NSString stringWithFormat:@"icon-email%@", (selected ? @"-selected" : @"")]];
    } else if (type == EFShareVideoTypeAirdrop) {
        image = [UIImage imageNamed:[NSString stringWithFormat:@"icon-airdrop%@", (selected ? @"-selected" : @"")]];
    } else if (type == EFShareVideoTypeCameraRoll) {
        image = [UIImage imageNamed:[NSString stringWithFormat:@"icon-save%@", (selected ? @"-selected" : @"")]];
    }
    
    return image;
}

- (NSString *)titleForType:(EFShareVideoType)type
{
    NSString *title = @"";
    
    if (type == EFShareVideoTypeFacebook) {
        title = @"Facebook";
    } else if (type == EFShareVideoTypeTwitter) {
        title = @"Twitter";
    } else if (type == EFShareVideoTypeSprio) {
        title = @"Sprio";
    } else if (type == EFShareVideoTypeMessage) {
        title = @"Message";
    } else if (type == EFShareVideoTypeMail) {
        title = @"Mail";
    } else if (type == EFShareVideoTypeAirdrop) {
        title = @"AirDrop";
    } else if (type == EFShareVideoTypeCameraRoll) {
        title = @"Save";
    }
    
    return title;
}

@end
