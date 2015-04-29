//
//  EFSemiTransparentModalView.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/25/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFSemiTransparentModalView.h"

@implementation EFSemiTransparentModalView

- (CGSize)preferredSize
{
    [NSException raise:NSGenericException format:@"Must override preferredSize"];
    return CGSizeZero;
}

- (void)viewWillDismiss {/*Intentionally Blank*/ }

@end
