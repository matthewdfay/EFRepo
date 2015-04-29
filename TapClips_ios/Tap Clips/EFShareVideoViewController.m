//
//  EFShareVideoViewController.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/14/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFShareVideoViewController.h"
#import "EFCenteredCollectionViewFlowLayout.h"
#import "EFSingleSelectionView.h"
#import "EFSemiTransparentModalViewController.h"
#import "EFSendVideoViewController.h"
#import "EFShareVideoCollectionViewCell.h"
#import "EFUser.h"
#import "EFMediaManager.h"
#import "EFUploadManager.h"
#import "EFExtensions.h"
#import "Flurry.h"
#import <MessageUI/MessageUI.h>

typedef enum : NSInteger
{
    EFShareSectionSocial = 0,
    EFShareSectionSend,
    EFShareSectionTotal
} EFShareSections;

typedef enum : NSInteger
{
    EFSocialRowFacebook = 0,
    EFSocialRowTwitter,
    EFSocialRowSprio,
    EFSocialRowTotal
} EFSocialRows;

typedef enum : NSInteger
{
    EFSendRowMessage = 0,
    EFSendRowMail,
    EFSendRowAirDrop,
    EFSendRowCameraRoll,
    EFSendRowTotal
} EFSendRows;

//////////////////////////////////////////////////////////////
//TODO: remove when we have necessary data.
//////////////////////////////////////////////////////////////
static NSString * const EFInstagramURL = @"instagram://";
static NSString * const EFPinterestURL = @"pinit12://";
static NSString * const EFTweetbotURL = @"tweetbot://";
static NSString * const EFTweetieURL = @"tweetie://";
static NSString * const EFVineURL = @"vine://";
static NSString * const EFWhatsAppURL = @"whatsapp://";

@interface EFShareVideoViewController () <UICollectionViewDataSource, UICollectionViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, EFSendVideoViewControllerDelegate, EFSingleSelectionDelegate>
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UIView *processingView;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;

@property (nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, strong) NSArray *twitterHandles;

@property (nonatomic, weak) id<EFShareVideoViewControllerDelegate> delegate;
@property (nonatomic, strong) UIViewController *sendViewController;

@end

@implementation EFShareVideoViewController

+ (EFShareVideoViewController *)shareVideoController:(AVURLAsset *)asset withDelegate:(id<EFShareVideoViewControllerDelegate>)delegate
{
    EFShareVideoViewController *controller = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"shareVideoViewController"];
    controller.delegate = delegate;
    controller.asset = asset;
    return controller;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.collectionView.collectionViewLayout = [[EFCenteredCollectionViewFlowLayout alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.processingView.alpha = 0.0;
    self.collectionView.alpha = 1.0;
}

//////////////////////////////////////////////////////////////
#pragma mark - SendViewController
//////////////////////////////////////////////////////////////
- (void)setSendViewController:(UIViewController *)sendViewController
{
    if (_sendViewController != sendViewController) {
        [self replaceViewController:_sendViewController withViewController:sendViewController];
        _sendViewController = sendViewController;
        [self updateOverlayViewController];
    }
}

- (void)setSendOverlay:(UIViewController *)controller animated:(BOOL)animated
{
    controller.view.alpha = 0.0;
    [UIView animateWithDuration:(animated ? 0.2 : 0) animations:^{
        self.sendViewController.view.alpha = 0.0;
        if (controller) {
            [self hideAllIcons];
        } else {
            [self displayAllIcons];
        }
    } completion:^(BOOL finished) {
        self.sendViewController = controller;
        if (controller) {
            [UIView animateWithDuration:(animated ? 0.2 : 0.0) animations:^{
                self.sendViewController.view.alpha = 1.0;
            }];
        }
    }];
}

- (void)updateOverlayViewController
{
    if (self.isViewLoaded && self.sendViewController) {
        [self.sendViewController.view removeFromSuperview];
        self.sendViewController.view.frame = self.view.bounds;
        [self.view addSubview:self.sendViewController.view];
        
        [self.sendViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.sendViewController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        [self.view addConstraint:topConstraint];
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.sendViewController.view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
        [self.view addConstraint:rightConstraint];
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.sendViewController.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        [self.view addConstraint:bottomConstraint];
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.sendViewController.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
        [self.view addConstraint:leftConstraint];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - UICollectionView
//////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return EFShareSectionTotal;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section == EFShareSectionSocial) {
        return EFSocialRowTotal;
    } else if (section == EFShareSectionSend) {
        return EFSendRowTotal;
    } else {
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    EFShareVideoCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:EFShareVideoCollectionViewCellIdentifier forIndexPath:indexPath];
    [cell populateWithType:[self cellTypeForIndexPath:indexPath]];
    return cell;
}

- (EFShareVideoType)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == EFShareSectionSocial) {
        if (indexPath.row == EFSocialRowFacebook) {
            return EFShareVideoTypeFacebook;
        } else if (indexPath.row == EFSocialRowTwitter) {
            return EFShareVideoTypeTwitter;
        } else if (indexPath.row == EFSocialRowSprio) {
            return EFShareVideoTypeSprio;
        }
    } else if (indexPath.section == EFShareSectionSend) {
        if (indexPath.row == EFSendRowMessage) {
            return EFShareVideoTypeMessage;
        } else if (indexPath.row == EFSendRowMail) {
            return EFShareVideoTypeMail;
        } else if (indexPath.row == EFSendRowAirDrop) {
            return EFShareVideoTypeAirdrop;
        } else if (indexPath.row == EFSendRowCameraRoll) {
            return EFShareVideoTypeCameraRoll;
        }
    }
    return -1;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == EFShareSectionSocial) {
        if (indexPath.row == EFSocialRowFacebook) {
            [self facebookConnectPressed];
        } else if (indexPath.row == EFSocialRowTwitter) {
            [self twitterConnectPressed];
        } else if (indexPath.row == EFSocialRowSprio) {
            [self sprioConnectPressed];
        }
    } else if (indexPath.section == EFShareSectionSend) {
        if (indexPath.row == EFSendRowMessage) {
            [self messagePressed];
        } else if (indexPath.row == EFSendRowMail) {
            [self mailPressed];
        } else if (indexPath.row == EFSendRowAirDrop) {
            [self displayAirDrop];
        } else if (indexPath.row == EFSendRowCameraRoll) {
            [self saveToCameraRoll];
        }
    }
}


//////////////////////////////////////////////////////////////
#pragma mark - Send Delegate
//////////////////////////////////////////////////////////////
- (void)dismissSendViewController
{
    [self setSendOverlay:nil animated:YES];
}

- (void)shareToSocialMediaType:(EFSendVideoType)type withMessage:(NSString *)message
{
    [self setSendOverlay:nil animated:YES];
    NSDictionary *shareDict = [self socialDictForType:type];
    [Flurry logEvent:@"Share Initiated" withParameters:[self flurryShareDictionary]];
    [[EFMediaManager sharedManager] attemtToSaveAssetToCameraRoll:self.asset withNotification:NO callback:nil];
    [[EFUploadManager sharedManager] uploadVideo:self.asset toSocialMedia:shareDict withMessage:message callback:^(BOOL wasSuccessful, id response) {
        if (!wasSuccessful) {
            [self postFailureNotificationWithMessage:([response isKindOfClass:[NSString class]] ? response : nil)];
        }
    }];
    [self closePressed:nil];
}

//////////////////////////////////////////////////////////////
#pragma mark - Row Selection
//////////////////////////////////////////////////////////////
- (void)facebookConnectPressed
{
    if ([EFUser isFacebookConnected]) {
        [self displayFacebookShare];
    } else {
        [[EFUser currentUser] connectUserWithFacebookCallback:^(BOOL wasSuccessful, NSString *message) {
            if (wasSuccessful) {
                [self displayFacebookShare];
            } else {
                [Flurry logError:@"Error Connecting to Facebook" message:message error:nil];
            }
        }];
    }
    
}

- (void)displayFacebookShare
{
    dispatch_async(dispatch_get_main_queue(), ^{
        EFSendVideoViewController *sendVC = [EFSendVideoViewController sendVideoControllerForType:EFSendVideoTypeFacebook withAsset:self.asset title:@"Share to Facebook" imageURL:nil andDelegate:self];
        [self setSendOverlay:sendVC animated:YES];
    });
}

- (void)twitterConnectPressed
{
    [[EFUser currentUser] connectUserWithTwitterCallback:^(BOOL wasSuccessful, NSArray *twitterHandles, NSString *errorMessage) {
        [self refreshShare];
        if (wasSuccessful && [twitterHandles count] == 1 && !errorMessage.length) {
            [self displayTwitterShare];
        } else if (wasSuccessful && [twitterHandles count] > 1 && !errorMessage.length) {
            self.twitterHandles = twitterHandles;
            [self displayTwitterHandleSelection];
        } else if (errorMessage.length) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            });
        }
    }];
}

- (void)itemSelected:(NSString *)item
{
    [[EFUser currentUser] connectUserWithTwitterHandle:item callback:^(BOOL wasSuccessful, NSArray *twitterHandles, NSString *errorMessage) {
        if (wasSuccessful) {
            self.twitterHandles = nil;
            [self displayTwitterShare];
        } else if (errorMessage.length) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            });
        } else {
            [Flurry logError:@"Error with multiple twitter handles and no message" message:@"" error:nil];
        }
    }];
}

- (void)displayTwitterHandleSelection
{
    dispatch_async(dispatch_get_main_queue(), ^{
        EFSingleSelectionView *selectionView = [EFSingleSelectionView selectionViewWithDelegate:self];
        selectionView.selectionItems = self.twitterHandles;
        selectionView.titleString = @"Twitter Handles";
        [EFSemiTransparentModalViewController presentWithView:selectionView];
    });
}

- (void)displayTwitterShare
{
    dispatch_async(dispatch_get_main_queue(), ^{
        EFSendVideoViewController *sendVC = [EFSendVideoViewController sendVideoControllerForType:EFSendVideoTypeTwitter withAsset:self.asset title:[[EFUser currentUser] currentTwitterHandle] imageURL:nil andDelegate:self];
        [self setSendOverlay:sendVC animated:YES];
    });
}

- (void)sprioConnectPressed
{
    [[EFUser currentUser] connectUserWithSprioCallback:^(BOOL wasSuccessful, NSString *message) {
        [self refreshShare];
        if (wasSuccessful) {
            [self displaySprioShare];
        } else {
            [Flurry logEvent:message];
        }
    }];
}

- (void)displaySprioShare
{
    dispatch_async(dispatch_get_main_queue(), ^{
        EFSendVideoViewController *sendVC = [EFSendVideoViewController sendVideoControllerForType:EFSendVideoTypeSprio withAsset:self.asset title:[[EFUser currentUser] currentSprioTeamName] imageURL:nil andDelegate:self];
        [self setSendOverlay:sendVC animated:YES];
    });
}

//////////////////////////////////////////////////////////////
#pragma mark - Actions
//////////////////////////////////////////////////////////////
- (IBAction)closePressed:(id)sender
{
    if (self.delegate) {
        [self.delegate cancelShareSelected];
    }
}

- (NSDictionary *)socialDictForType:(EFSendVideoType)type
{
    NSMutableDictionary *socialDictionary = [NSMutableDictionary dictionary];
    if (type == EFSendVideoTypeFacebook && [[EFUser currentUser] facebookToken].length) {
        [socialDictionary setObject:@{@"token": [[EFUser currentUser] facebookToken]} forKey:@"fb"];
    }
    
    if (type == EFSendVideoTypeTwitter && [[EFUser currentUser] twitterAuthDictForHandle:[EFUser currentUser].currentTwitterHandle]) {
        [socialDictionary setObject:[[EFUser currentUser] twitterAuthDictForHandle:[EFUser currentUser].currentTwitterHandle] forKey:@"twitter"];
    }
    
    if (type == EFSendVideoTypeSprio && [[EFUser currentUser] sprioAuthDictForTeam:[EFUser currentUser].currentSprioTeamId]) {
        [socialDictionary setObject:[[EFUser currentUser] sprioAuthDictForTeam:[EFUser currentUser].currentSprioTeamId] forKey:@"sprio"];
    }
    
    return socialDictionary;
}


//////////////////////////////////////////////////////////////
#pragma mark - Send Actions
//////////////////////////////////////////////////////////////
- (void)displayAirDrop
{
    [Flurry logEvent:@"Airdrop Opened"];
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[self.asset.URL] applicationActivities:nil];
    NSArray *excludedActivities = @[UIActivityTypePostToTwitter, UIActivityTypePostToFacebook,
                                    UIActivityTypePostToWeibo, UIActivityTypePrint,
                                    UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,
                                    UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo,
                                    UIActivityTypeAssignToContact, UIActivityTypeMail,
                                    UIActivityTypeMessage, UIActivityTypeSaveToCameraRoll];
    controller.excludedActivityTypes = excludedActivities;
    controller.completionHandler = ^(NSString *activityType, BOOL completed) {
        if (completed) {
            [self closePressed:nil];
        } else {
            [self refreshShare];
        }
    };
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)messagePressed
{
    NSString *shareURL = [EFUser currentUser].shareURL;
    [[EFUser currentUser] fetchNewShareDictionaryWithCallback:nil];
    [UIView animateWithDuration:0.25 animations:^{
        self.processingView.alpha = 1.0;
        self.collectionView.alpha = 0.0;
    }];
    [[EFUploadManager sharedManager] uploadVideo:self.asset toURL:[[EFUser currentUser] getShareDictionary] callback:^(BOOL wasSuccessful, id response) {
        [self.processingView.layer removeAllAnimations];
        [self.collectionView.layer removeAllAnimations];
        [UIView animateWithDuration:0.2 animations:^{
            self.processingView.alpha = 0.0;
            self.collectionView.alpha = 1.0;
        }];
        if (wasSuccessful) {
            [self displayMessageWithURL:shareURL];
        } else {
            [self postFailureNotificationWithMessage:([response isKindOfClass:[NSString class]] ? response : nil)];
        }
    }];
}

- (void)displayMessageWithURL:(NSString *)url
{
    if (self.isViewLoaded && self.view.superview) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MFMessageComposeViewController *messageVC = [[MFMessageComposeViewController alloc] init];
            messageVC.messageComposeDelegate = self;
            messageVC.body = [NSString stringWithFormat:@"Check out this %@ second TapClip!\n%@?src=txt\n", [NSNumber numberWithDouble:round(CMTimeGetSeconds(self.asset.duration))], url];
            [self presentViewController:messageVC animated:YES completion:nil];
        });
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self refreshShare];
    [Flurry logEvent:@"Finished Sending a Message" withParameters:@{@"result": [self resultKeyForMessageResult:result]}];
    [self dismissViewControllerAnimated:YES completion:nil];
    if (result == MessageComposeResultSent) {
        [self closePressed:nil];
    }
}

- (void)mailPressed
{
    NSString *shareURL = [EFUser currentUser].shareURL;
    [[EFUser currentUser] fetchNewShareDictionaryWithCallback:nil];
    [UIView animateWithDuration:0.25 animations:^{
        self.processingView.alpha = 1.0;
        self.collectionView.alpha = 0.0;
    }];
    [[EFUploadManager sharedManager] uploadVideo:self.asset toURL:[[EFUser currentUser] getShareDictionary] callback:^(BOOL wasSuccessful, id response) {
        [self.processingView.layer removeAllAnimations];
        [self.collectionView.layer removeAllAnimations];
        [UIView animateWithDuration:0.25 animations:^{
            self.processingView.alpha = 0.0;
            self.collectionView.alpha = 1.0;
        }];
        if (wasSuccessful) {
            [self displayMailWithShareURL:shareURL];
        } else {
            [self postFailureNotificationWithMessage:([response isKindOfClass:[NSString class]] ? response : nil)];
        }
    }];
}

- (void)displayMailWithShareURL:(NSString *)url
{
    if (self.isViewLoaded && self.view.superview) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
            mailVC.mailComposeDelegate = self;
            [mailVC setSubject:@"TapClips Video"];
            [mailVC setMessageBody:[NSString stringWithFormat:@"Check out this %@ second TapClip that I took.\n%@?src=email\n\nFree App.\nhttp://tapclips.com/app", [NSNumber numberWithDouble:round(CMTimeGetSeconds(self.asset.duration))], url] isHTML:NO];
            [self presentViewController:mailVC animated:YES completion:nil];
        });
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self refreshShare];
    [Flurry logEvent:@"Finished Sending an Email" withParameters:@{@"result": [self resultKeyForMailResult:result]}];
    [self dismissViewControllerAnimated:YES completion:nil];
    if (result == MFMailComposeResultSent) {
        [self closePressed:nil];
    }
}

- (void)saveToCameraRoll
{
    [Flurry logEvent:@"Explicit Save to Camera Roll"];
    [[EFMediaManager sharedManager] attemtToSaveAssetToCameraRoll:self.asset withNotification:YES callback:^(BOOL wasSuccessful, AVURLAsset *asset) {
        if (wasSuccessful) {
            [self closePressed:nil];
        }
    }];
}

- (NSString *)resultKeyForMailResult:(MFMailComposeResult)result
{
    NSString *resultString = @"";
    if (result == MFMailComposeResultCancelled) {
        resultString = @"cancelled";
    } else if (result == MFMailComposeResultFailed) {
        resultString = @"failed";
    } else if (result == MFMailComposeResultSaved) {
        resultString = @"saved";
    } else if (result == MFMailComposeResultSent) {
        resultString = @"sent";
    }
    return resultString;
}

- (NSString *)resultKeyForMessageResult:(MessageComposeResult)result
{
    NSString *resultString = @"";
    if (result == MessageComposeResultCancelled) {
        resultString = @"cancelled";
    } else if (result == MessageComposeResultSent) {
        resultString = @"sent";
    } else if (result == MessageComposeResultFailed) {
        resultString = @"failed";
    }
    return resultString;
}

//////////////////////////////////////////////////////////////
#pragma mark - Helpers
//////////////////////////////////////////////////////////////
- (void)postFailureNotificationWithMessage:(NSString *)message
{
    [self refreshShare];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:@NO forKey:EFVideoPostedToAPIWasSuccessfulKey];
        if (message.length) {
            [dict setObject:message forKey:EFVideoPostedToAPIMessageKey];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:EFVideoPostedToAPINotification object:nil userInfo:dict];
    });
}

- (void)refreshShare
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });
}
- (void)displayAllIcons
{
    [self refreshShare];
    self.collectionView.alpha = 1.0;
    self.closeButton.alpha = 1.0;
}

- (void)hideAllIcons
{
    self.collectionView.alpha = 0.0;
    self.closeButton.alpha = 0.0;
}

- (NSDictionary *)flurryShareDictionary
{
    NSMutableDictionary *flurryDict = [NSMutableDictionary dictionary];
    [flurryDict setObject:[NSNumber numberWithBool:([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:EFInstagramURL]])] forKey:@"instagram"];
    [flurryDict setObject:[NSNumber numberWithBool:([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:EFTweetbotURL]])] forKey:@"tweetbot"];
    [flurryDict setObject:[NSNumber numberWithBool:([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:EFTweetieURL]])] forKey:@"tweetie"];
    [flurryDict setObject:[NSNumber numberWithBool:([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:EFPinterestURL]])] forKey:@"pinterest"];
    [flurryDict setObject:[NSNumber numberWithBool:([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:EFVineURL]])] forKey:@"vine"];
    [flurryDict setObject:[NSNumber numberWithBool:([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:EFWhatsAppURL]])] forKey:@"whatsapp"];
    return flurryDict;
}

@end
