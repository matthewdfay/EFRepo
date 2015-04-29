//
//  EFTimeTrackingView.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/17/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EFTimeTrackingView : UIControl

- (void)setTime:(NSNumber *)time;
- (void)setVideoDate:(NSDate *)videoStartDate;

@end
