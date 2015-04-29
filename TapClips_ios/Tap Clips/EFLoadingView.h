//
//  EFLoadingView.h
//  TapClips
//
//  Created by Matthew Fay on 5/9/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EFLoadingView : UIView

- (void)beginAnimationgWithDuration:(NSNumber *)duration;
- (void)endAnimating;

- (void)displayError;

@end
