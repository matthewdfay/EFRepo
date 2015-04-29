//
//  EFSingleSelectionCell.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/26/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const EFSingleSelectionCellIdentifier;

@interface EFSingleSelectionCell : UITableViewCell

- (void)populateWithTitle:(NSString *)title selected:(BOOL)selected;

@end
