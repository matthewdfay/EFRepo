//
//  EFRotationView.m
//  TapClips
//
//  Created by Matthew Fay on 5/22/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFRotationView.h"

@interface EFRotationView ()
@property (nonatomic, weak) IBOutlet UIImageView *rotationImageView;
@end

@implementation EFRotationView

+ (EFRotationView *)rotationView
{
    UINib * nib = [UINib nibWithNibName:@"EFRotationView" bundle:nil];
    NSArray *views = [nib instantiateWithOwner:nil options:nil];
    EFRotationView *view = [views lastObject];
    return view;
}

- (void)setInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    self.rotationImageView.image = [self rotationImageWithOrinetation:orientation];
}

- (UIImage *)rotationImageWithOrinetation:(UIInterfaceOrientation)orientation
{
    UIImage *src = [UIImage imageNamed:@"overlay-rotation"];
    UIImage *image = nil;
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        image = [[UIImage alloc] initWithCGImage:src.CGImage scale:src.scale orientation:UIImageOrientationRight];
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        image = [[UIImage alloc] initWithCGImage:src.CGImage scale:src.scale orientation:UIImageOrientationLeft];
    }
    return image;
}

@end
