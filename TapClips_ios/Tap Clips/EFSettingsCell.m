//
//  EFSettingsSocialConnectCell.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/2/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFSettingsCell.h"
#import "EFUser.h"

NSString * const EFSettingsCellIdentifier = @"settingsCell";

@interface EFSettingsCell ()
@property (nonatomic, weak) IBOutlet UIView *settingsBackgroundView;
@property (nonatomic, weak) IBOutlet UIImageView *settingsImageView;
@property (nonatomic, weak) IBOutlet UILabel *settingsTitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *checkImageView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, assign) EFSettingsType type;
@property (nonatomic, assign) BOOL checked;
@end

@implementation EFSettingsCell

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    if (highlighted) {
        self.settingsBackgroundView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.1];
    } else {
        self.settingsBackgroundView.backgroundColor = [UIColor clearColor];
    }
    [self updateSettingsImageForType:self.type selected:(self.checked | highlighted)];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if (selected) {
        self.checkImageView.hidden = YES;
        self.activityIndicatorView.hidden = NO;
        [self.activityIndicatorView startAnimating];
    }
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.activityIndicatorView.hidden = YES;
    self.settingsImageView.clipsToBounds = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.type = -1;
    self.checked = NO;
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.settingsBackgroundView.backgroundColor = [UIColor clearColor];
    self.settingsImageView.image = nil;
    self.settingsTitleLabel.text = @"";
    self.checkImageView.image = nil;
    self.checkImageView.hidden = NO;
    self.activityIndicatorView.hidden = YES;
    [self.activityIndicatorView stopAnimating];
}

//////////////////////////////////////////////////////////////
#pragma mark - Populate
//////////////////////////////////////////////////////////////
- (void)populateWithType:(EFSettingsType)type checked:(BOOL)checked displayCheckArea:(BOOL)displayCheck
{
    self.type = type;
    self.checked = checked;
    [self updateSettingsImageForType:type selected:(checked & displayCheck)];
    self.settingsTitleLabel.text = [self socialTitleForType:type enabled:checked];
    self.checkImageView.hidden = !displayCheck;
    self.checkImageView.image = [self checkImage:checked];
}

- (void)updateSettingsImageForType:(EFSettingsType)type selected:(BOOL)selected
{
    if (type == EFSocialTypeSprio && selected) {
        [[EFUser currentUser] fetchSprioTeamImage:^(UIImage *image, BOOL wasCached) {
            if (image) {
                self.settingsImageView.image = image;
            }
        }];
    } else {
        self.settingsImageView.image = [self socialImageForType:type selected:selected];
    }
}

- (UIImage *)socialImageForType:(EFSettingsType)type selected:(BOOL)selected
{
    UIImage *socialImage = nil;
    if (type == EFSettingsTypeFacebook || type == EFSocialTypeFacebook) {
        socialImage = (selected ? [UIImage imageNamed:@"icon-facebook-selected"] : [UIImage imageNamed:@"icon-facebook"]);
    } else if (type == EFSettingsTypeTwitter || type == EFSocialTypeTwitter) {
        socialImage = (selected ? [UIImage imageNamed:@"icon-twitter-selected"] : [UIImage imageNamed:@"icon-twitter"]);
    } else if (type == EFSocialTypeSprio && !selected) {
        socialImage = [UIImage imageNamed:@"icon-sprio"];
    } else if (type == EFSettingsTypeFeedback) {
        socialImage = (selected ? [UIImage imageNamed:@"icon-feedback-selected"] : [UIImage imageNamed:@"icon-feedback"]);
    } else if (type == EFSettingsTypeRate) {
        socialImage = (selected ? [UIImage imageNamed:@"icon-rate-selected"] : [UIImage imageNamed:@"icon-rate"]);
    } else if (type == EFSettingsTypeSaveAndDelete) {
        socialImage = (selected ? [UIImage imageNamed:@"icon-cameraRoll-selected"] : [UIImage imageNamed:@"icon-cameraRoll"]);
    }
    return socialImage;
}

- (NSString *)socialTitleForType:(EFSettingsType)type enabled:(BOOL)enabled
{
    NSString *title = @"";
    if (type == EFSettingsTypeFacebook) {
        title = (enabled ? @"Facebook" : @"Enable Facebook");
    } else if (type == EFSocialTypeFacebook) {
        title = @"Facebook";
    } else if (type == EFSettingsTypeTwitter) {
        title = (enabled ? [[EFUser currentUser] currentTwitterHandle] : @"Enable Twitter");
    } else if (type == EFSocialTypeTwitter) {
        title = (enabled ? [[EFUser currentUser] currentTwitterHandle] : @"Twitter");
    } else if (type == EFSocialTypeSprio) {
        title = (enabled ? [[EFUser currentUser] currentSprioTeamName] : @"Sprio");
    } else if (type == EFSettingsTypeFeedback) {
        title =  @"Feedback";
    } else if (type == EFSettingsTypeRate) {
        title = @"Rate the App";
    } else if (type == EFSettingsTypeTerms) {
        title = @"Terms & Conditions";
    } else if (type == EFSettingsTypePrivacy) {
        title = @"Privacy Policy";
    } else if (type == EFSettingsTypeSaveAndDelete) {
        title = @"Move to Camera Roll";
    }
    return title;
}

- (UIImage *)checkImage:(BOOL)checked
{
    UIImage *checkImage = nil;
    if (checked) {
        checkImage = [UIImage imageNamed:@"icon-checkbox-active"];
    } else {
        checkImage = [UIImage imageNamed:@"icon-checkbox"];
    }
    return checkImage;
}

@end
