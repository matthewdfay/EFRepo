//
//  EFSettingsHeaderCell.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/2/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const EFSettingsHeaderCellIdentifier;

@interface EFSettingsHeaderCell : UITableViewCell

- (void)populateWithTitle:(NSString *)title;

@end
