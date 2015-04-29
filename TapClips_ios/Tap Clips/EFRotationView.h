//
//  EFRotationView.h
//  TapClips
//
//  Created by Matthew Fay on 5/22/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EFRotationView : UIView

+ (EFRotationView *)rotationView;

- (void)setInterfaceOrientation:(UIInterfaceOrientation)orientation;

@end
