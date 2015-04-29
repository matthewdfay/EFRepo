//
//  EFSemiTransparentModalView.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/25/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EFSemiTransparentModalView : UIView

/**
 This returns the preferred size of the view to be displayed.
 
 NOTE: must be implemented.
 */
- (CGSize)preferredSize;

/**
 This will be called by EFSemiTransparentViewController
 before it will be dismissed
 
 NOTE: not required to be implemented.
 */
- (void)viewWillDismiss;

@end
