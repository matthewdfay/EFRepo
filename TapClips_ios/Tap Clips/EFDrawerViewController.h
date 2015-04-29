//
//  EFDrawerViewController.h
//  TapClips
//
//  Created by Matthew Fay on 6/13/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EFDrawerViewControllerDelegate;

@interface EFDrawerViewController : UIViewController

@property (nonatomic, strong) id<EFDrawerViewControllerDelegate> delegate;

@end

@protocol EFDrawerViewControllerDelegate <NSObject>

@required
- (void)dismissDrawer;

@optional
- (void)itemSelectedAtIndexPath:(NSIndexPath *)indexPath;

@end