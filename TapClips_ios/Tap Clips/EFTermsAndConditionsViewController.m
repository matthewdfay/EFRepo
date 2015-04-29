//
//  EFTermsAndConditionsViewController.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFTermsAndConditionsViewController.h"
#import "EFWebViewController.h"
#import "EFExtensions.h"

static NSString * const EFTermsAndConditionsKey = @"termsAndConditionsKey";

@interface EFTermsAndConditionsViewController ()

@end

@implementation EFTermsAndConditionsViewController

+ (BOOL)shouldDisplayTermsAndConditionsOverlay
{
    return ![[NSUserDefaults standardUserDefaults] boolForKey:EFTermsAndConditionsKey];
}

+ (EFTermsAndConditionsViewController *)termsAndConditions
{
    return [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"termsAndConditionsViewController"];
}

- (IBAction)termsAndConditionsSelected:(id)sender
{
    [self presentViewController:[EFWebViewController termsAndConditionsViewController] animated:YES completion:nil];
}

- (IBAction)privacyPolicySelected:(id)sender
{
    [self presentViewController:[EFWebViewController privacyPolicyViewController] animated:YES completion:nil];
}

- (IBAction)termsAndConditionsAccepted:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:EFTermsAndConditionsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (self.delegate) {
        [self.delegate termsAndConditionsAccepted];
    }
}

@end
