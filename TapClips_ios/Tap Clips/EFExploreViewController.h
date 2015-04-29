//
//  EFExploreViewController.h
//  TapClips
//
//  Created by Matthew Fay on 5/27/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EFDrawerViewController.h"

@interface EFExploreViewController : EFDrawerViewController

@property (nonatomic, strong) NSString *url;
@property (nonatomic, weak, readonly) UIWebView *webView;

+ (EFExploreViewController *)exploreViewControllerWithDelegate:(id<EFDrawerViewControllerDelegate>)delegate;
- (void)reloadExplore;

@end
