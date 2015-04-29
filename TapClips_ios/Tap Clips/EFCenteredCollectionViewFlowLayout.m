//
//  EFCenteredCollectionViewFlowLayout.m
//  TapClips
//
//  Created by Matthew Fay on 6/11/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFCenteredCollectionViewFlowLayout.h"
#import "EFExtensions.h"

@implementation EFCenteredCollectionViewFlowLayout

- (NSInteger)itemWidth
{
    if (EF_IS_IPAD) {
        return 110.0;
    } else {
        return 80.0;
    }
}

- (NSInteger)itemHeight
{
    if (EF_IS_IPAD) {
        return 110.0;
    } else {
        return 80.0;
    }
}

- (void)prepareLayout {
    self.itemSize = CGSizeMake([self itemWidth], [self itemHeight]);
    self.minimumInteritemSpacing = 0;
    self.scrollDirection = UICollectionViewScrollDirectionVertical;
}

// Only works if everything fits in the visible rect
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *attribs = [super layoutAttributesForElementsInRect:rect];
    
    CGRect visibleRect;
    visibleRect.origin = self.collectionView.contentOffset;
    visibleRect.size = self.collectionView.bounds.size;
    
    NSArray *splitAttribs = [self splitAttributesByIndexPath:attribs];
    NSInteger sections = [splitAttribs count];
    for (NSArray *sectionArray in splitAttribs) {
        NSInteger rows = [sectionArray count];
        for (UICollectionViewLayoutAttributes *attributes in sectionArray) {
            NSInteger itemSection = attributes.indexPath.section;
            NSInteger itemRow = attributes.indexPath.row;
            NSInteger itemHeight = attributes.frame.size.height;
            NSInteger itemWidth = attributes.frame.size.width;
            NSInteger leftX = round((visibleRect.size.width - (itemWidth * rows)) / 2.0);
            NSInteger rowY = round((visibleRect.size.height - (itemHeight * sections)) / 2.0);
            NSInteger newXValue = leftX + (itemRow * itemWidth);
            NSInteger newYValue = rowY + (itemSection * itemHeight);
            
            CGRect rect = attributes.frame;
            rect.origin.y = newYValue;
            rect.origin.x = newXValue;
            attributes.frame = rect;
        }
    }
    
    return attribs;
}

- (NSArray *)splitAttributesByIndexPath:(NSArray *)attribs
{
    NSMutableDictionary *splitAttributes = [NSMutableDictionary dictionary];
    for (UICollectionViewLayoutAttributes *attributes in attribs) {
        NSNumber *section = [NSNumber numberWithInteger:attributes.indexPath.section];
        NSMutableArray *sectionArray = [splitAttributes objectForKey:section];
        if (!sectionArray) {
            sectionArray = [NSMutableArray array];
        }
        [sectionArray addObject:attributes];
        [splitAttributes setObject:sectionArray forKey:section];
    }
    return [splitAttributes allValues];
}

// indicate that we want to redraw as we scroll
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

@end
