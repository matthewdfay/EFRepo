//
//  EFTermsAndConditionsViewController.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EFTermsAndConditionsViewControllerDelegate;

@interface EFTermsAndConditionsViewController : UIViewController

@property (nonatomic, weak) id<EFTermsAndConditionsViewControllerDelegate> delegate;

+ (BOOL)shouldDisplayTermsAndConditionsOverlay;
+ (EFTermsAndConditionsViewController *)termsAndConditions;

@end

@protocol EFTermsAndConditionsViewControllerDelegate <NSObject>

@required
- (void)termsAndConditionsAccepted;

@end