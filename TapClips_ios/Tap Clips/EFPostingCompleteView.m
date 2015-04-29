//
//  EFPostingCompleteView.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/16/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFPostingCompleteView.h"
#import "EFSemiTransparentModalViewController.h"
#import "EFExtensions.h"

@interface EFPostingCompleteView ()
@property (nonatomic, weak) IBOutlet UILabel *messageLabel;
@property (nonatomic, strong) NSTimer *dismissTimer;
@property (nonatomic, assign) BOOL shouldAutoDismiss;
@end

@implementation EFPostingCompleteView

+ (EFPostingCompleteView *)postingComplete:(BOOL)wasSuccessful withMessage:(NSString *)message
{
    EFPostingCompleteView *view = nil;
    if (wasSuccessful) {
        view = [self successView];
    } else {
        view = [self failureViewWithMessage:message];
    }
    return view;
}

+ (EFPostingCompleteView *)successView
{
    UINib * nib = [UINib nibWithNibName:@"EFPostingCompleteView" bundle:nil];
    NSArray *views = [nib instantiateWithOwner:nil options:nil];
    EFPostingCompleteView *view = [views lastObject];
    view.shouldAutoDismiss = YES;
    return view;
}

+ (EFPostingCompleteView *)failureViewWithMessage:(NSString *)message
{
    UINib * nib = [UINib nibWithNibName:@"EFPostingCompleteFailureView" bundle:nil];
    NSArray *views = [nib instantiateWithOwner:nil options:nil];
    EFPostingCompleteView *view = [views lastObject];
    view.shouldAutoDismiss = NO;
    if (message.length) {
        view.messageLabel.text = message;
    }
    return view;
}

+ (EFPostingCompleteView *)cameraRollSaved:(BOOL)wasSuccessful
{
    EFPostingCompleteView *view = nil;
    if (wasSuccessful) {
        view = [self cameraRollView];
    } else {
        view = [self failureViewWithMessage:@"Error saving to camera roll"];
    }
    return view;
}

+ (EFPostingCompleteView *)cameraRollView
{
    UINib * nib = [UINib nibWithNibName:@"EFPostingCompleteViewCameraRoll" bundle:nil];
    NSArray *views = [nib instantiateWithOwner:nil options:nil];
    EFPostingCompleteView *view = [views lastObject];
    view.shouldAutoDismiss = YES;
    return view;
}

- (void)setShouldAutoDismiss:(BOOL)shouldAutoDismiss
{
    if (_shouldAutoDismiss != shouldAutoDismiss) {
        _shouldAutoDismiss = shouldAutoDismiss;
        if (_shouldAutoDismiss) {
            self.dismissTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(dismiss) userInfo:nil repeats:NO];
        } else {
            [self.dismissTimer invalidate];
            self.dismissTimer = nil;
        }
    }
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.layer.cornerRadius = 10.0;
}

- (CGSize)preferredSize
{
    if (EF_IS_IPHONE) {
        return CGSizeMake(180, 140);
    } else {
        return CGSizeMake(200, 160);
    }
}

- (void)viewWillDismiss
{
    [self.dismissTimer invalidate];
}

- (IBAction)dismissPressed:(id)sender
{
    [self dismiss];
}

- (void)dismiss
{
    [EFSemiTransparentModalViewController dismiss];
}

@end
