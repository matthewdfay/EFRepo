//
//  EFOnboardingView.m
//  TapClips
//
//  Created by Matthew Fay on 5/19/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFOnboardingView.h"

@interface EFOnboardingView ()
@property (nonatomic, weak) IBOutlet UIView *firstView;
@property (nonatomic, weak) IBOutlet UIImageView *firstIconView;
@property (nonatomic, weak) IBOutlet UILabel *firstLabel;

@property (nonatomic, weak) IBOutlet UIView *secondView;
@property (nonatomic, weak) IBOutlet UIImageView *secondIconView;
@property (nonatomic, weak) IBOutlet UILabel *secondLabel;

@end

@implementation EFOnboardingView

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.firstView.layer.cornerRadius = (self.firstView.frame.size.height/2);
    self.secondView.layer.cornerRadius = (self.secondView.frame.size.height/2);
    [self resetView];
}

- (void)setFirstViewTitle:(NSString *)text icon:(UIImage *)icon andBackgroundColor:(UIColor *)color
{
    self.firstView.backgroundColor = color;
    self.firstLabel.text = text;
    self.firstIconView.image = icon;
    [self setNeedsLayout];
}

- (void)setSecondViewTitle:(NSString *)text icon:(UIImage *)icon andBackgroundColor:(UIColor *)color
{
    self.secondView.backgroundColor = color;
    self.secondLabel.text = text;
    self.secondIconView.image = icon;
    [self setNeedsLayout];
}

- (void)updateViewMaxLayoutWidth
{
    self.firstLabel.preferredMaxLayoutWidth = (self.firstView.frame.size.width - self.firstIconView.frame.size.width);
    self.secondLabel.preferredMaxLayoutWidth = (self.secondView.frame.size.width - self.secondIconView.frame.size.width);
}

- (void)resetView
{
    [self hideFirstView];
    self.firstIconView.image = nil;
    self.firstLabel.text = @"";
    self.firstView.backgroundColor = [UIColor clearColor];
    
    [self hideSecondView];
    self.secondIconView.image = nil;
    self.secondLabel.text = @"";
    self.secondView.backgroundColor = [UIColor clearColor];
}

//Changes the alpha (animatable)
- (void)displayFirstView
{
    self.firstView.alpha = 1.0;
}

- (void)displaySecondView
{
    self.secondView.alpha = 1.0;
}

- (void)hideFirstView
{
    self.firstView.alpha = 0.0;
}

- (void)hideSecondView
{
    self.secondView.alpha = 0.0;
}

@end
