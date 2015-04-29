//
//  EFSingleSelectionCell.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/26/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFSingleSelectionCell.h"

NSString * const EFSingleSelectionCellIdentifier = @"singleSelectionCellIdentifier";

@interface EFSingleSelectionCell ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *selectedImageView;
@end

@implementation EFSingleSelectionCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupTitleLabel];
        [self setupSelectedImageView];
        
        self.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark - Setup
//////////////////////////////////////////////////////////////
- (void)setupSelectedImageView
{
    UIImage *check = [UIImage imageNamed:@"icon_check"];
    self.selectedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(280 - check.size.width - 7, 0, check.size.width, 44)];
    self.selectedImageView.contentMode = UIViewContentModeRight;
    self.selectedImageView.image = check;
    self.selectedImageView.hidden = YES;
    [self addSubview:self.selectedImageView];
}

- (void)setupTitleLabel
{
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 230, 24)];
    self.titleLabel.textColor = [UIColor whiteColor];
    [self addSubview:self.titleLabel];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.selectedImageView.hidden = YES;
    self.titleLabel.text = @"";
}

- (void)populateWithTitle:(NSString *)title selected:(BOOL)selected
{
    self.titleLabel.text = title;
    self.selectedImageView.hidden = !selected;
}

@end
