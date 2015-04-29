//
//  EFSettingsSelectionCell.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/3/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFSettingsSelectionCell.h"

NSString * const EFSettingsSelectionCellIdentifier = @"settingsSelectionCell";

@interface EFSettingsSelectionCell ()
@property (nonatomic, weak) IBOutlet UIView *settingsBackgroundView;
@property (nonatomic, weak) IBOutlet UILabel *settingsTitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *settingsBoxImageView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@end

@implementation EFSettingsSelectionCell

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    self.settingsBackgroundView.backgroundColor = (highlighted ? [UIColor colorWithWhite:0.8 alpha:0.15] : [UIColor clearColor]);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if (selected) {
        self.settingsBoxImageView.hidden = YES;
        self.activityIndicatorView.hidden = NO;
        [self.activityIndicatorView startAnimating];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.settingsBackgroundView.backgroundColor = [UIColor clearColor];
    self.settingsTitleLabel.text = @"";
    self.settingsBoxImageView.hidden = NO;
    self.activityIndicatorView.hidden = YES;
    [self.activityIndicatorView stopAnimating];
}

- (void)populateWithTitle:(NSString *)title
{
    self.settingsTitleLabel.text = title;
}

@end
