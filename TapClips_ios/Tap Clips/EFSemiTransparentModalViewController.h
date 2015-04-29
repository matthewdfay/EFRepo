//
//  EFSemiTransparentModalViewController.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/26/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EFSemiTransparentModalView;

@interface EFSemiTransparentModalViewController : UIViewController

/**
 Presents a full screen semi-transparent view with
 a centered view that is passed in. The centered view
 will move if the keyboard is shown, and will become
 scrollable if the length of the passed in view is
 larger than the available display area.
 
 NOTE: the area not covered by the passed in view
 will dismiss the viewController when tapped.
 */
+ (void)presentWithView:(EFSemiTransparentModalView *)view;

/**
 Same as presentWithView: except the background
 will not dismiss the viewController.
 */
+ (void)presentWithModalView:(EFSemiTransparentModalView *)view;

/**
 Animates the presented view to be the updated
 preferred size if the size changed.
 */
+ (void)animateToPreferredSize;

/**
 Explicitly dismisses the viewController.
 */
+ (void)dismiss;

@end
