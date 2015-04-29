//
//  EFShareVideoCollectionViewCell.h
//  TapClips
//
//  Created by Matthew Fay on 6/11/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const EFShareVideoCollectionViewCellIdentifier;

typedef enum : NSInteger
{
    EFShareVideoTypeFacebook = 0,
    EFShareVideoTypeTwitter,
    EFShareVideoTypeSprio,
    EFShareVideoTypeMessage,
    EFShareVideoTypeMail,
    EFShareVideoTypeAirdrop,
    EFShareVideoTypeCameraRoll
} EFShareVideoType;

@interface EFShareVideoCollectionViewCell : UICollectionViewCell

- (void)populateWithType:(EFShareVideoType)type;

@end
