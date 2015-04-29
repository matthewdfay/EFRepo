//
//  EFZoomView.h
//  Tap Clips
//
//  Created by Matthew Fay on 4/22/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EFZoomViewDelegate;

@interface EFZoomView : UIView
@property (nonatomic, weak) IBOutlet id<EFZoomViewDelegate> delegate;
@end

@protocol EFZoomViewDelegate <NSObject>

@required
- (void)zoomValueChanged:(CGFloat)value;

@end