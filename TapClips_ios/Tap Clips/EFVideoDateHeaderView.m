//
//  EFVideoDateHeaderView.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/7/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFVideoDateHeaderView.h"
#import "EFExtensions.h"

NSString * const EFVideoDateHeaderViewIdentifier = @"videoDateHeaderView";

@interface EFVideoDateHeaderView ()
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@end

@implementation EFVideoDateHeaderView

- (void)populateWithDate:(NSDate *)date
{
    if (date) {
        self.dateLabel.text = [date longDate];
    } else {
        self.dateLabel.text = @"";
    }
}

@end
