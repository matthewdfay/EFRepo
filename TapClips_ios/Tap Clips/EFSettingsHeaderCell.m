//
//  EFSettingsHeaderCell.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/2/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFSettingsHeaderCell.h"

NSString * const EFSettingsHeaderCellIdentifier = @"settingsHeaderCell";

@interface EFSettingsHeaderCell ()
@property (nonatomic, weak) IBOutlet UILabel *settingsTitleLabel;
@end

@implementation EFSettingsHeaderCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.settingsTitleLabel.text = @"";
}

- (void)populateWithTitle:(NSString *)title
{
    self.settingsTitleLabel.text = title;
}

@end
