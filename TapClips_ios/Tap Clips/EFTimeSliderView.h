//
//  EFTimeSliderView.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/17/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EFTimeSliderViewDelegate;

@interface EFTimeSliderView : UIView

@property (nonatomic, weak) id<EFTimeSliderViewDelegate> delegate;
@end

@protocol EFTimeSliderViewDelegate <NSObject>

@optional
- (void)timeChangedto:(NSNumber *)duration;

@end