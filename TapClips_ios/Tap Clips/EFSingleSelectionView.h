//
//  EFSingleSelectionView.h
//  TapClips
//
//  Created by Matthew Fay on 6/12/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFSemiTransparentModalView.h"

@protocol EFSingleSelectionDelegate;

@interface EFSingleSelectionView : EFSemiTransparentModalView

+ (EFSingleSelectionView *)selectionViewWithDelegate:(id<EFSingleSelectionDelegate>)delegate;

@property (nonatomic, strong) NSString *titleString;
//an array of all the items to display that are availabe for selection. (Must be strings)
@property (nonatomic, strong) NSArray *selectionItems;
@property (nonatomic, strong) NSString *currentlySelectedItem;

@end

@protocol EFSingleSelectionDelegate <NSObject>

/**
 returns the selected value.
 */
@required
- (void)itemSelected:(NSString *)item;

@end