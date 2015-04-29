//
//  EFTimeFillLayer.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/21/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface EFTimeFillLayer : CALayer

@property (nonatomic) CGFloat animationDuration;
@property (nonatomic) CGFloat endAngle;

@property (nonatomic, strong) UIColor *fillColor;

@end
