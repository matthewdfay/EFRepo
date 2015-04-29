//
//  EFSingleSelectionView.m
//  TapClips
//
//  Created by Matthew Fay on 6/12/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFSingleSelectionView.h"
#import "EFSingleSelectionCell.h"
#import "EFSemiTransparentModalViewController.h"

NSInteger const EFSingleSelectionCellHeight = 44;

@interface EFSingleSelectionView () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) id<EFSingleSelectionDelegate> delegate;
@end

@implementation EFSingleSelectionView

+ (EFSingleSelectionView *)selectionViewWithDelegate:(id<EFSingleSelectionDelegate>)delegate
{
    UINib * nib = [UINib nibWithNibName:@"EFSingleSelectionView" bundle:nil];
    NSArray *views = [nib instantiateWithOwner:nil options:nil];
    EFSingleSelectionView *view = [views lastObject];
    view.delegate = delegate;
    return view;
}

- (void)setTitleString:(NSString *)titleString
{
    if (_titleString != titleString) {
        _titleString = titleString;
        _titleLabel.text = _titleString;
    }
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.tableView registerClass:[EFSingleSelectionCell class] forCellReuseIdentifier:EFSingleSelectionCellIdentifier];
}

- (CGSize)preferredSize
{
    if ([self.selectionItems count] > 0) {
        NSInteger height = self.titleLabel.bounds.size.height;
        height += [self displayedCellsHeight];
        if (height > [self maxHeight]) {
            height = [self maxHeight];
        }
        return CGSizeMake(300, height);
    } else {
        return CGSizeMake(300, 200);
    }
}

- (NSInteger)displayedCellsHeight
{
    NSInteger height = 0;
    height = ([self.selectionItems count] * EFSingleSelectionCellHeight);
    return height;
}

- (NSInteger)maxHeight
{
    return ([[UIScreen mainScreen] bounds].size.width - 20);
}

//////////////////////////////////////////////////////////////
#pragma mark - UITableView
//////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.selectionItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EFSingleSelectionCell *cell = [tableView dequeueReusableCellWithIdentifier:EFSingleSelectionCellIdentifier];
    NSString *cellTitle = [self.selectionItems objectAtIndex:indexPath.row];
    [cell populateWithTitle:cellTitle selected:[self isItemSelected:cellTitle]];
    return cell;
}

- (BOOL)isItemSelected:(NSString *)item
{
    if (item && self.currentlySelectedItem && [item isEqualToString:self.currentlySelectedItem]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate) {
        NSString *item = [self.selectionItems objectAtIndex:indexPath.row];
        [self.delegate itemSelected:item];
    }
    [EFSemiTransparentModalViewController dismiss];
}

@end
