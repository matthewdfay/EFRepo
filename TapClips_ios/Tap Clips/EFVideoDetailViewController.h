//
//  EFVideoDetailViewController.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/8/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EFVideoDetailViewControllerDelegate;

@interface EFVideoDetailViewController : UIViewController

+ (EFVideoDetailViewController *)videoDetailViewController;

@property (nonatomic, strong) NSIndexPath *initialIndexPath;
@property (nonatomic, weak) id<EFVideoDetailViewControllerDelegate> delegate;

@end

@protocol EFVideoDetailViewControllerDelegate <NSObject>

@required
- (void)videoDetailShouldDismiss;

@end