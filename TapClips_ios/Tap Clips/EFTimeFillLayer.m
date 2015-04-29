//
//  EFTimeFillLayer.m
//  Tap Clips
//
//  Created by Matthew Fay on 4/21/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFTimeFillLayer.h"

#define DEG2RAD(angle) angle*M_PI/180.0

@implementation EFTimeFillLayer

@dynamic endAngle;
@synthesize fillColor, animationDuration;

-(id<CAAction>)actionForKey:(NSString *)event {
    if ([event isEqualToString:@"startAngle"] ||
        [event isEqualToString:@"endAngle"]) {
        return [self makeAnimationForKey:event];
    }
    
    return [super actionForKey:event];
}

- (id)init {
    self = [super init];
    if (self) {
		self.fillColor = [UIColor grayColor];
        
		[self setNeedsDisplay];
    }
    
    return self;
}

- (id)initWithLayer:(id)layer {
    if (self = [super initWithLayer:layer]) {
        if ([layer isKindOfClass:[EFTimeFillLayer class]]) {
            EFTimeFillLayer *other = (EFTimeFillLayer *)layer;
            self.endAngle = other.endAngle;
            self.animationDuration = other.animationDuration;
            self.fillColor = other.fillColor;
        }
    }
    
    return self;
}

+ (BOOL)needsDisplayForKey:(NSString *)key {
    if ([key isEqualToString:@"startAngle"] || [key isEqualToString:@"endAngle"]) {
        return YES;
    }
    
    return [super needsDisplayForKey:key];
}

-(void)drawInContext:(CGContextRef)ctx {
    
    // Create the path
    CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    CGFloat radius = MIN(center.x, center.y);
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, center.x, center.y);
    
    CGPoint p1 = CGPointMake(center.x + radius * cosf(-M_PI_2), center.y + radius * sinf(-M_PI_2));
    CGContextAddLineToPoint(ctx, p1.x, p1.y);
    
    int clockwise = -M_PI_2 > self.endAngle;
    CGContextAddArc(ctx, center.x, center.y, radius, -M_PI_2, self.endAngle, clockwise);
    
    CGContextClosePath(ctx);
    
    // Color it
    CGContextSetFillColorWithColor(ctx, self.fillColor.CGColor);
    CGContextSetStrokeColorWithColor(ctx, self.fillColor.CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    
    CGContextDrawPath(ctx, kCGPathFillStroke);
}

-(CABasicAnimation *)makeAnimationForKey:(NSString *)key {
	CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:key];
	anim.fromValue = [[self presentationLayer] valueForKey:key];
	anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	anim.duration = self.animationDuration;    
	return anim;
}

@end
