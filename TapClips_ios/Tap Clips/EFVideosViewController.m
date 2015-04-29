//
//  EFVideosViewController.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/4/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFVideosViewController.h"
#import "EFVideoDateHeaderView.h"
#import "EFVideoRowCell.h"
#import "EFVideoDetailViewController.h"
#import "EFMediaManager.h"
#import "EFExtensions.h"
#import "Flurry.h"

@interface EFVideosViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@end

@implementation EFVideosViewController

+ (EFVideosViewController *)videosViewControllerWithDelegate:(id<EFDrawerViewControllerDelegate>)delegate
{
    EFVideosViewController *vc = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"videosViewController"];
    vc.delegate = delegate;
    return vc;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"EFVideoDateHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:EFVideoDateHeaderViewIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self beginListeningForNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self endListeningForNotifications];
}

//////////////////////////////////////////////////////////////
#pragma mark - Notifications
//////////////////////////////////////////////////////////////
- (void)beginListeningForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videosUpdated:) name:EFMediaManagerVideosUpdatedNotification object:nil];
}

- (void)endListeningForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)videosUpdated:(NSNotification *)note
{
    [self.tableView reloadData];
}

//////////////////////////////////////////////////////////////
#pragma mark - Collection View
//////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[EFMediaManager sharedManager] numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[EFMediaManager sharedManager] numberOfRowsForSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EFVideoRowCell *cell = [self.tableView dequeueReusableCellWithIdentifier:EFVideoRowCellIdentifier];
    [cell populateWithAsset:[[EFMediaManager sharedManager] assetForIndexPath:indexPath]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    EFVideoDateHeaderView *header = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:EFVideoDateHeaderViewIdentifier];
    [header populateWithDate:[[EFMediaManager sharedManager] dateForSection:section]];
    return header;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(itemSelectedAtIndexPath:)]) {
        [self.delegate itemSelectedAtIndexPath:indexPath];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Actions
//////////////////////////////////////////////////////////////
- (IBAction)cameraPressed:(id)sender
{
    [Flurry logEvent:@"Drawer Closed By Camera Button Videos"];
    if (self.delegate) {
        [self.delegate dismissDrawer];
    }
}

@end
