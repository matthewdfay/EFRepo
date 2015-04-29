//
//  EFVideoPreviewView.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/24/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFVideoPreviewView.h"
#import "EFVideoPreviewCollectionViewCell.h"
#import "EFExtensions.h"

@interface EFVideoPreviewView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) AVURLAsset *asset;

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@end

@implementation EFVideoPreviewView

+ (EFVideoPreviewView *)videoPreviewView
{
    UINib * nib = [UINib nibWithNibName:@"EFVideoPreviewView" bundle:nil];
    NSArray *views = [nib instantiateWithOwner:nil options:nil];
    EFVideoPreviewView *view = [views lastObject];
    return view;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.collectionView registerNib:[UINib nibWithNibName:@"EFVideoPreviewCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:EFVideoPreviewCollectionViewCellIdentifier];
    [self.collectionView reloadData];
}

- (void)updatePreviewWithAsset:(AVURLAsset *)asset animated:(BOOL)animated
{
    for (EFVideoPreviewCollectionViewCell *cell in self.collectionView.visibleCells) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        if (indexPath.row == 1) {
            [cell populateWithAsset:asset animated:animated];
        }
    }
    self.asset = asset;
}

- (void)updatePreviewWithError
{
    for (EFVideoPreviewCollectionViewCell *cell in self.collectionView.visibleCells) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        if (indexPath.row == 1) {
            [cell populateWithError];
        }
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Collection View
//////////////////////////////////////////////////////////////
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 2;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.collectionView.frame.size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    EFVideoPreviewCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:EFVideoPreviewCollectionViewCellIdentifier forIndexPath:indexPath];
    
    if (indexPath.row == 1) {
        if (self.asset) {
            [cell populateWithAsset:self.asset];
        } else {
            [cell populateWithLoadingIndicator:@6];
        }
    } else {
        [cell populateWithAsset:nil];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1 && self.asset && self.delegate && [self.delegate respondsToSelector:@selector(videoWasSelectedForViewing:)]) {
        [self.delegate videoWasSelectedForViewing:self.asset];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - Scroll View
//////////////////////////////////////////////////////////////
- (void)scrollToVideoPreviewAnimated:(BOOL)animated
{
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:animated];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(previewInteractionStarted)]) {
        [self.delegate previewInteractionStarted];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1 && self.delegate && [self.delegate respondsToSelector:@selector(videoWasDismissed)]) {
        [self.delegate videoWasDismissed];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate && self.delegate && [self.delegate respondsToSelector:@selector(previewInteractionEnded)]) {
        [self.delegate previewInteractionEnded];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(previewInteractionEnded)]) {
        [self.delegate previewInteractionEnded];
    }
}

@end
