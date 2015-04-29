//
//  EFOnboardingView.h
//  TapClips
//
//  Created by Matthew Fay on 5/19/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EFOnboardingView : UIView

- (void)setFirstViewTitle:(NSString *)text icon:(UIImage *)icon andBackgroundColor:(UIColor *)color;
- (void)setSecondViewTitle:(NSString *)text icon:(UIImage *)icon andBackgroundColor:(UIColor *)color;
- (void)updateViewMaxLayoutWidth;
- (void)resetView;

//Changes the alpha (animatable)
- (void)displayFirstView;
- (void)displaySecondView;
- (void)hideFirstView;
- (void)hideSecondView;
@end
