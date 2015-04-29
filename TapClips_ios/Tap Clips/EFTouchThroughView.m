//
//  EFTouchThroughView.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/25/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFTouchThroughView.h"

@implementation EFTouchThroughView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL inSubview = NO;
    for (UIView *subview in self.subviews) {
        if (CGRectContainsPoint(subview.frame, point)) {
            inSubview = YES;
            break;
        }
    }
    return inSubview;
}

@end
