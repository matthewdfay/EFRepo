//
//  EFMoreSelectionCell.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/26/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFMoreSelectionCell.h"

NSString * const EFMoreSelectionCellIdentifier = @"moreSelectionCellIdentifier";

@interface EFMoreSelectionCell ()
@property (nonatomic, strong) UILabel *moreLabel;
@end

@implementation EFMoreSelectionCell

- (NSString *)reuseIdentifier
{
    return EFMoreSelectionCellIdentifier;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor lightGrayColor];
        self.contentView.backgroundColor = [UIColor lightGrayColor];
        [self setupMoreLabel];
        self.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    return self;
}

- (void)setupMoreLabel
{
    self.moreLabel = [[UILabel alloc] initWithFrame:self.bounds];
//    self.moreLabel.font = [UIFont cellCreationTextWithSize:18.0];
    self.moreLabel.textColor = [UIColor blackColor];
    self.moreLabel.textAlignment = NSTextAlignmentCenter;
    self.moreLabel.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.moreLabel.text = @"More";
    [self addSubview:self.moreLabel];
}

@end
