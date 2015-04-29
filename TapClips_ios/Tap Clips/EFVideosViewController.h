//
//  EFVideosViewController.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/4/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EFDrawerViewController.h"

@interface EFVideosViewController : EFDrawerViewController

+ (EFVideosViewController *)videosViewControllerWithDelegate:(id<EFDrawerViewControllerDelegate>)delegate;

@end