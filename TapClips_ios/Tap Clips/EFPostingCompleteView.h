//
//  EFPostingCompleteView.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/16/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFSemiTransparentModalView.h"

@interface EFPostingCompleteView : EFSemiTransparentModalView

+ (EFPostingCompleteView *)postingComplete:(BOOL)wasSuccessful withMessage:(NSString *)message;
+ (EFPostingCompleteView *)cameraRollSaved:(BOOL)wasSuccessful;

@end
