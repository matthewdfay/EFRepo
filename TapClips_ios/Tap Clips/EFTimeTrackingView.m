//
//  EFTimeTrackingView.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/17/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFTimeTrackingView.h"
#import "EFTimeFillLayer.h"

@interface EFTimeTrackingView ()

@property (nonatomic, weak) IBOutlet UIView *backgroundLayerView;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UIImageView *overlayImageView;
@property (nonatomic, strong) EFTimeFillLayer *animatingCircleLayer;
@property (nonatomic, strong) EFTimeFillLayer *backgroundLayer;

@property (nonatomic, strong) NSNumber *duration;
@property (nonatomic, strong) NSDate *startDate;

@end

@implementation EFTimeTrackingView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupLayers];
}

- (void)setupLayers
{
    self.backgroundLayer = [EFTimeFillLayer layer];
    self.backgroundLayer.frame =  CGRectInset(self.backgroundLayerView.bounds, 2, 2);
    self.backgroundLayer.fillColor = [UIColor whiteColor]; //TODO: change this to real color
    self.backgroundLayer.endAngle = 3*M_PI/2;
    self.backgroundLayer.animationDuration = 0.0;
    [self.backgroundLayerView.layer insertSublayer:self.backgroundLayer atIndex:0];
    
    self.animatingCircleLayer = [EFTimeFillLayer layer];
    self.animatingCircleLayer.frame =  CGRectInset(self.backgroundLayerView.bounds, 2, 2);
    self.animatingCircleLayer.fillColor = [UIColor colorWithRed:0.0 green:171/255.0 blue:93/255.0 alpha:1.0];
    self.animatingCircleLayer.endAngle = -M_PI_2;
    self.animatingCircleLayer.animationDuration = self.duration.floatValue;
    [self.backgroundLayerView.layer insertSublayer:self.animatingCircleLayer above:self.backgroundLayer];
}

//////////////////////////////////////////////////////////////
#pragma mark - Animations
//////////////////////////////////////////////////////////////
- (void)updateAnimation
{
    self.animatingCircleLayer.animationDuration = 0.2;
    self.animatingCircleLayer.endAngle = [self angleForDurationAfterStart:[[NSDate date] timeIntervalSinceDate:self.startDate]];
    if (self.startDate) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.startDate) {
                self.animatingCircleLayer.animationDuration = (self.duration.floatValue - [[NSDate date] timeIntervalSinceDate:self.startDate]);
                self.animatingCircleLayer.endAngle = 3 * M_PI / 2;
            } else {
                self.animatingCircleLayer.animationDuration = 0.2;
                self.animatingCircleLayer.endAngle = [self angleForDurationAfterStart:[[NSDate date] timeIntervalSinceDate:self.startDate]];
            }
        });
    }
}

- (CGFloat)angleForDurationAfterStart:(CGFloat)timeAfterStart
{
    CGFloat angle = -M_PI_2;
    if (self.startDate) {
        if (timeAfterStart > self.duration.floatValue) {
            angle = 3 * M_PI / 2;
        } else {
            CGFloat percetThrough = (timeAfterStart / self.duration.floatValue);
            angle = ((percetThrough * (2 * M_PI)) - M_PI_2);
        }
    }
    return angle;
}

//////////////////////////////////////////////////////////////
#pragma mark - Updating
//////////////////////////////////////////////////////////////
- (void)setTime:(NSNumber *)time
{
    self.duration = time;
    self.animatingCircleLayer.animationDuration = self.duration.floatValue;
    [self updateTimeLabelWithDuration:time];
    [self updateAnimation];
}

- (void)updateTimeLabelWithDuration:(NSNumber *)duration
{
    self.timeLabel.text = [NSString stringWithFormat:@":%@%@", (duration.doubleValue < 10 ? @"0" : @""), duration];
}

- (void)setVideoDate:(NSDate *)videoStartDate
{
    self.startDate = videoStartDate;
    [self updateAnimation];
}

@end
