//
//  EFSettingsViewController.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/21/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFSettingsViewController.h"
#import "EFWebViewController.h"
#import "EFSettingsCell.h"
#import "EFSettingsHeaderCell.h"
#import "EFSettingsSelectionCell.h"
#import "EFCameraManager.h"
#import "EFSettingsManager.h"
#import "EFMediaManager.h"
#import "EFUser.h"
#import "EFExtensions.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "Flurry.h"

typedef enum : NSInteger
{
    EFSettingsSectionSaveAndDelete = 0,
    EFSettingsSectionSupportHeader,
    EFSettingsSectionRate,
    EFSettingsSectionSupport,
    EFSettingsSectionTerms,
    EFSettingsSectionPrivacy,
    EFSettingsSectionsTotal
} EFSettingsSections;

@interface EFSettingsViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *twitterHandles;
@end

@implementation EFSettingsViewController

+ (EFSettingsViewController *)settingsViewControllerWithDelegate:(id<EFDrawerViewControllerDelegate>)delegate;
{
    EFSettingsViewController *vc = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"settingsViewController"];
    vc.delegate = delegate;
    return vc;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"EFSettingsCell" bundle:nil] forCellReuseIdentifier:EFSettingsCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"EFSettingsSelectionCell" bundle:nil] forCellReuseIdentifier:EFSettingsSelectionCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

//////////////////////////////////////////////////////////////
#pragma mark - UITableView
//////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return EFSettingsSectionsTotal;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == EFSettingsSectionRate && ![[EFSettingsManager sharedManager] appRatingURL].length) {
        return 0;
    } else if (section == EFSettingsSectionTerms || section == EFSettingsSectionPrivacy){
        return 0;
    } else {
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == EFSettingsSectionSaveAndDelete) {
        return 60.0;
    } else if (indexPath.section == EFSettingsSectionSupportHeader) {
        return 30.0;
    } else if (indexPath.section == EFSettingsSectionRate) {
        return 60.0;
    } else if (indexPath.section == EFSettingsSectionSupport) {
        return 60.0;
    } else if (indexPath.section == EFSettingsSectionTerms) {
        return 50;
    } else if (indexPath.section == EFSettingsSectionPrivacy) {
        return 50;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == EFSettingsSectionSaveAndDelete) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:EFSettingsCellIdentifier];
        [(EFSettingsCell *)cell populateWithType:EFSettingsTypeSaveAndDelete checked:NO displayCheckArea:NO];
    } else if (indexPath.section == EFSettingsSectionSupportHeader) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:EFSettingsHeaderCellIdentifier];
        [(EFSettingsHeaderCell *)cell populateWithTitle:@"Support"];
    } else if (indexPath.section == EFSettingsSectionRate) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:EFSettingsCellIdentifier];
        [(EFSettingsCell *)cell populateWithType:EFSettingsTypeRate checked:NO displayCheckArea:NO];
    } else if (indexPath.section == EFSettingsSectionSupport) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:EFSettingsCellIdentifier];
        [(EFSettingsCell *)cell populateWithType:EFSettingsTypeFeedback checked:NO displayCheckArea:NO];
    } else if (indexPath.section == EFSettingsSectionTerms) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:EFSettingsCellIdentifier];
        [(EFSettingsCell *)cell populateWithType:EFSettingsTypeTerms checked:NO displayCheckArea:NO];
    } else if (indexPath.section == EFSettingsSectionPrivacy) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:EFSettingsCellIdentifier];
        [(EFSettingsCell *)cell populateWithType:EFSettingsTypePrivacy checked:NO displayCheckArea:NO];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == EFSettingsSectionSaveAndDelete) {
        [self saveAllVideosThenDelete];
    } else if (indexPath.section == EFSettingsSectionRate) {
        [self rateAppSelected];
    } else if (indexPath.section == EFSettingsSectionSupport) {
        [self supportSelected];
    } else if (indexPath.section == EFSettingsSectionTerms) {
        [self termsAndConditionsSelected];
    } else if (indexPath.section == EFSettingsSectionPrivacy) {
        [self privacyPolicySelected];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Row Selection
//////////////////////////////////////////////////////////////
- (void)saveAllVideosThenDelete
{
    [Flurry logEvent:@"Move All Videos to Camera Roll Selected"];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"All clips will be moved to the Camera Roll " delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.delegate = self;
    [alert show];
}

- (void)rateAppSelected
{
    [Flurry logEvent:@"Rate App Selected"];
    [self.tableView reloadData];
    NSURL *url = [NSURL URLWithString:[[EFSettingsManager sharedManager] appRatingURL]];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)supportSelected
{
    [Flurry logEvent:@"Support Selected"];
    MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
    mail.mailComposeDelegate = self;
    [mail setSubject:[NSString stringWithFormat:@"TapClips Support (%@)", [UIApplication applicationVersion]]];
    [mail setToRecipients:@[@"support@tapclips.com"]];
    NSString *body = [NSString stringWithFormat:@"\n\n\n\nUser Id = %@\nApp Version = %@", ([[EFUser currentUser] serverUserId].length ? [[EFUser currentUser] serverUserId] : [[EFUser currentUser] userId]), [UIApplication applicationVersion]];
    [mail setMessageBody:body isHTML:NO];
    mail.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:mail animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [Flurry logEvent:@"Settings Finished Posting to Support" withParameters:@{@"result": [self nameForMailResult:result]}];
    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)nameForMailResult:(MFMailComposeResult)result
{
    NSString *name = @"unknown";
    if (result == MFMailComposeResultCancelled)
        name = @"cancelled";
    else if (result == MFMailComposeResultSent)
        name = @"sent";
    else if (result == MFMailComposeResultSaved)
        name = @"saved";
    else if (result == MFMailComposeResultFailed)
        name = @"failed";
    return name;
}

- (void)termsAndConditionsSelected
{
    [self presentViewController:[EFWebViewController termsAndConditionsViewController] animated:YES completion:^{
        [self.tableView reloadData];
    }];
}

- (void)privacyPolicySelected
{
    [self presentViewController:[EFWebViewController privacyPolicyViewController] animated:YES completion:^{
        [self.tableView reloadData];
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        [[EFMediaManager sharedManager] attemptToSaveAllAssetsToCameraRollThenDeleteWithCallback:^(BOOL wasSuccessful, NSString *message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
    } else {
        [self.tableView reloadData];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Actions
//////////////////////////////////////////////////////////////
- (IBAction)cameraPressed:(id)sender
{
    [Flurry logEvent:@"Drawer Closed By Camera Button Settings"];
    if (self.delegate) {
        [self.delegate dismissDrawer];
    }
}

@end
