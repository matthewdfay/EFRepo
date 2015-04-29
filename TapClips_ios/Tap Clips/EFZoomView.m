//
//  EFZoomView.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/22/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFZoomView.h"
#import "EFExtensions.h"
#import "Flurry.h"

@interface EFZoomView ()
@property (nonatomic, weak) IBOutlet UIView *zoomBackgroundView;
@property (nonatomic, weak) IBOutlet UISlider *zoomSlider;
@property (nonatomic, weak) IBOutlet UIButton *minusButton;
@property (nonatomic, weak) IBOutlet UIButton *plusButton;
@end

@implementation EFZoomView

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.zoomBackgroundView.layer.cornerRadius = (EF_IS_IPAD ? 20.0 : 15.0);
}

- (IBAction)zoomSliderChanged:(id)sender
{
    [self sliderValueChanged:((UISlider *)sender).value];
}

- (IBAction)zoomSliderFinishedSliding:(id)sender
{
    [Flurry logEvent:@"Zoom Finished Sliding" withParameters:@{@"zoomValue": [NSNumber numberWithFloat:self.zoomSlider.value]}];
}

- (IBAction)minusZoomSliderPressed:(id)sender
{
    CGFloat newSliderValue = (self.zoomSlider.value - 1);
    [Flurry logEvent:@"Zoom Minus Selected" withParameters:@{@"zoomValue": [NSNumber numberWithFloat:newSliderValue]}];
    if (newSliderValue < self.zoomSlider.minimumValue) {
        newSliderValue = self.zoomSlider.minimumValue;
    }
    self.zoomSlider.value = newSliderValue;
    [self sliderValueChanged:newSliderValue];
}

- (IBAction)plusZoomSliderPressed:(id)sender
{
    CGFloat newSliderValue = (self.zoomSlider.value + 1);
    [Flurry logEvent:@"Zoom Plus Selected" withParameters:@{@"zoomValue": [NSNumber numberWithFloat:newSliderValue]}];
    if (newSliderValue > self.zoomSlider.maximumValue) {
        newSliderValue = self.zoomSlider.maximumValue;
    }
    self.zoomSlider.value = newSliderValue;
    [self sliderValueChanged:newSliderValue];
}

- (void)sliderValueChanged:(CGFloat)value
{
    if (self.delegate) {
        [self.delegate zoomValueChanged:(value/self.zoomSlider.maximumValue)];
    }
}

@end
