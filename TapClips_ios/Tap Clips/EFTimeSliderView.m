//
//  EFTimeSliderView.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/17/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFTimeSliderView.h"
#import "EFCameraManager.h"
#import "EFSettingsManager.h"
#import "EFExtensions.h"
#import "Flurry.h"

@interface EFTimeSliderView ()
@property (nonatomic, weak) IBOutlet UIView *sliderBackgroundView;
@property (nonatomic, weak) IBOutlet UIButton *plusButton;
@property (nonatomic, strong) UISlider *timeSlider;
@end

@implementation EFTimeSliderView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupTimeSlider];
    self.sliderBackgroundView.layer.cornerRadius = (EF_IS_IPAD ? 19.0 : 15.0);
}

- (void)setupTimeSlider
{
    _timeSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.height, self.frame.size.width)];
    _timeSlider.center = self.center;
    _timeSlider.transform = CGAffineTransformRotate(_timeSlider.transform, 90.0/180*M_PI);
    _timeSlider.frame = CGRectMake(0, 32, _timeSlider.frame.size.width, _timeSlider.frame.size.height - 60);
    _timeSlider.minimumValue = [[EFSettingsManager sharedManager] minRecordingSeconds].floatValue;
    _timeSlider.maximumValue = [[EFSettingsManager sharedManager] maxRecordingSeconds].floatValue;
    _timeSlider.value = [[EFCameraManager sharedManager] clipDuration].floatValue;
    [_timeSlider addTarget:self action:@selector(timeSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [_timeSlider addTarget:self action:@selector(timeSliderStoppedSliding:) forControlEvents:UIControlEventTouchUpInside];
    [_timeSlider addTarget:self action:@selector(timeSliderStoppedSliding:) forControlEvents:UIControlEventTouchUpOutside];
    [self addSubview:_timeSlider];
}

- (IBAction)timeSliderChanged:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(timeChangedto:)]) {
        [self.delegate timeChangedto:[NSNumber numberWithFloat:roundf(self.timeSlider.value)]];
    }
}

- (IBAction)timeSliderStoppedSliding:(id)sender
{
    self.timeSlider.value = round(self.timeSlider.value);
    [Flurry logEvent:@"Clip Duration Finished Sliding" withParameters:@{@"duration": [NSNumber numberWithFloat:self.timeSlider.value]}];
    [self timeSliderChanged:sender];
}

- (IBAction)plusPressed:(id)sender
{
    self.timeSlider.value = (self.timeSlider.value + 1);
    [Flurry logEvent:@"Clip Duration Plus Selected" withParameters:@{@"duration": [NSNumber numberWithFloat:self.timeSlider.value]}];
    [self timeSliderChanged:self.timeSlider];
}


@end
