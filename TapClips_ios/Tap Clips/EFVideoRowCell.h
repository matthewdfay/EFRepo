//
//  EFVideoRowCell.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/4/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

extern NSString * const EFVideoRowCellIdentifier;

@interface EFVideoRowCell : UITableViewCell

- (void)populateWithAsset:(AVURLAsset *)asset;

@end
