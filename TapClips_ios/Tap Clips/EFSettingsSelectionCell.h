//
//  EFSettingsSelectionCell.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/3/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

NSString * const EFSettingsSelectionCellIdentifier;

@interface EFSettingsSelectionCell : UITableViewCell

- (void)populateWithTitle:(NSString *)title;

@end
