//
//  EFSettingsSocialConnectCell.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/2/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSInteger
{
    EFSettingsTypeFacebook = 0,
    EFSocialTypeFacebook,
    EFSettingsTypeTwitter,
    EFSocialTypeTwitter,
    EFSocialTypeSprio,
    EFSettingsTypeFeedback,
    EFSettingsTypeRate,
    EFSettingsTypeSaveAndDelete,
    EFSettingsTypeTerms,
    EFSettingsTypePrivacy
} EFSettingsType;

extern NSString * const EFSettingsCellIdentifier;

@interface EFSettingsCell : UITableViewCell

- (void)populateWithType:(EFSettingsType)type checked:(BOOL)checked displayCheckArea:(BOOL)displayCheck;

@end
