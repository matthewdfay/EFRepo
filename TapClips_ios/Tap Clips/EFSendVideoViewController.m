//
//  EFSendVideoViewController.m
//  TapClips
//
//  Created by Matthew Fay on 5/14/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFSendVideoViewController.h"
#import "EFMediaManager.h"
#import "EFUploadManager.h"
#import "EFUser.h"
#import "EFSettingsManager.h"
#import "EFExtensions.h"
#import "Flurry.h"

static NSString * const EFShareVideoDefaultCaptionText = @"Write a caption";

@interface EFSendVideoViewController () <UITextViewDelegate>

@property (nonatomic, strong) NSString *shareTitleText;
@property (nonatomic, strong) NSRegularExpression *regex;
@property (nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, assign) EFSendVideoType type;
@property (nonatomic, strong) id<EFSendVideoViewControllerDelegate> delegate;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *sendButton;
@property (nonatomic, weak) IBOutlet UITextView *messageTextView;

@end

@implementation EFSendVideoViewController

- (NSString *)captionText
{
    return [self.messageTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)userInputCaptionText
{
    return ([[self captionText] isEqualToString:EFShareVideoDefaultCaptionText] ? nil : [self captionText]);
}

+ (EFSendVideoViewController *)sendVideoControllerForType:(EFSendVideoType)type withAsset:(AVURLAsset *)asset title:(NSString *)title imageURL:(NSString *)imageURL andDelegate:(id<EFSendVideoViewControllerDelegate>)delegate
{
    EFSendVideoViewController *controller = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"sendVideoViewController"];
    controller.delegate = delegate;
    controller.type = type;
    controller.asset = asset;
    controller.shareTitleText = title;
    return controller;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.messageTextView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.6].CGColor;
    self.messageTextView.layer.borderWidth = 1.0;
    self.messageTextView.text = EFShareVideoDefaultCaptionText;
    self.titleLabel.text = self.shareTitleText;
    self.regex = [NSRegularExpression twitterHandleRegularExpression];
}

//////////////////////////////////////////////////////////////
#pragma mark - UITextViewDelegate
//////////////////////////////////////////////////////////////
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:EFShareVideoDefaultCaptionText]) {
        textView.text = @"#TapClips ";
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    NSArray *results = [self.regex matchesInString:textView.text options:NSMatchingReportCompletion range:NSMakeRange(0, textView.text.length)];
    for (NSTextCheckingResult *result in results) {
        NSRange actualRange = NSMakeRange(result.range.location, (result.range.length - 1));
        NSString *foundString = [textView.text substringWithRange:actualRange];
        NSString *replacementString = [[EFSettingsManager sharedManager] replacementStringForKey:foundString];
        if (replacementString.length) {
            NSLog(@"replaced %@ with %@", foundString, replacementString);
            textView.text = [textView.text stringByReplacingCharactersInRange:actualRange withString:replacementString];
        } else {
            NSLog(@"could not find %@", foundString);
        }
    }
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    if ([[self captionText] isEqualToString:@"#TapClips "]) {
        textView.text = EFShareVideoDefaultCaptionText;
    }
    return YES;
}

//////////////////////////////////////////////////////////////
#pragma mark - Actions
//////////////////////////////////////////////////////////////
- (IBAction)backPressed:(id)sender
{
    [Flurry logEvent:@"Send Dismissed"];
    if (self.delegate) {
        [self.delegate dismissSendViewController];
    }
}

- (IBAction)sendPressed:(id)sender
{
    [Flurry logEvent:@"Send Initiated"];
    if (self.delegate) {
        [self.delegate shareToSocialMediaType:self.type withMessage:[self userInputCaptionText]];
    }
}

@end
