//
//  EFLoadingView.m
//  TapClips
//
//  Created by Matthew Fay on 5/9/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFLoadingView.h"
#import <QuartzCore/QuartzCore.h>

@interface EFLoadingView ()
@property (nonatomic, weak) IBOutlet UILabel *savingLabel;
@property (nonatomic, weak) IBOutlet UIView *loadingContainerView;
@property (nonatomic, weak) IBOutlet UIView *loadingView;
@end

@implementation EFLoadingView

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.loadingContainerView.layer.cornerRadius = (self.loadingContainerView.frame.size.height/2);
    self.loadingContainerView.clipsToBounds = YES;
}

- (void)beginAnimationgWithDuration:(NSNumber *)duration
{
    self.savingLabel.frame = CGRectMake(0, 0, self.frame.size.width, self.loadingContainerView.frame.origin.y);
    self.savingLabel.text = @"Saving";
    self.loadingContainerView.hidden = NO;
    self.loadingView.frame = CGRectMake(0, 0, 0, self.loadingContainerView.frame.size.height);
    [UIView animateWithDuration:duration.floatValue animations:^{
        self.loadingView.frame = self.loadingContainerView.bounds;
    }];
}

- (void)endAnimating
{
    [self.layer removeAllAnimations];
    [self.loadingContainerView.layer removeAllAnimations];
    [self.loadingView.layer removeAllAnimations];
}

- (void)displayError
{
    self.savingLabel.frame = self.bounds;
    self.savingLabel.text = @"Error\nSaving";
    self.loadingContainerView.hidden = YES;
    [self endAnimating];
}

@end
