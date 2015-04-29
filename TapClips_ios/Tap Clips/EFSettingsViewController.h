//
//  EFSettingsViewController.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/21/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EFDrawerViewController.h"

@interface EFSettingsViewController : EFDrawerViewController

+ (EFSettingsViewController *)settingsViewControllerWithDelegate:(id<EFDrawerViewControllerDelegate>)delegate;

@end
