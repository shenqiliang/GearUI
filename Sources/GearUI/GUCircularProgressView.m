//
//  GUCircleProgressView.m
//  GearUI
//
//  Created by 谌启亮 on 13/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUCircularProgressView.h"

@implementation GUCircularProgressView
{
    CAShapeLayer *_foregroundLayer;
    CAShapeLayer *_backgroundLayer;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _backgroundLayer = [CAShapeLayer layer];
        _backgroundLayer.fillColor = [UIColor clearColor].CGColor;
        [self.layer addSublayer:_backgroundLayer];

        _foregroundLayer = [CAShapeLayer layer];
        [self.layer addSublayer:_foregroundLayer];
        
        
        _backgroundLayer.fillColor = _foregroundLayer.fillColor = [UIColor clearColor].CGColor;
        _backgroundLayer.lineWidth = _foregroundLayer.lineWidth = _lineWidth = 12;
        
        _foregroundLayer.strokeColor = [UIColor blueColor].CGColor;
        _backgroundLayer.strokeColor = [UIColor grayColor].CGColor;

        CGFloat radius = (MIN(self.bounds.size.width,self.bounds.size.height)-_lineWidth)/2;
        _backgroundLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2) radius:radius startAngle:-M_PI_2 endAngle:M_PI*2-M_PI_2 clockwise:YES].CGPath;
        _foregroundLayer.path = _backgroundLayer.path;
        _foregroundLayer.strokeEnd = _progress;
        _foregroundLayer.lineCap = @"round";
    }
    return self;
}

- (void)updatePath {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.fromValue = @(_foregroundLayer.presentationLayer.strokeEnd);
    animation.toValue = @(_progress);
    animation.duration = UIView.inheritedAnimationDuration;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    _foregroundLayer.strokeEnd = _progress;
    if (UIView.areAnimationsEnabled) {
        [_foregroundLayer addAnimation:animation forKey:@"strokeEnd"];
    }
}

- (void)layoutSubviews {
    _foregroundLayer.frame = _backgroundLayer.frame = self.bounds;
    CGFloat radius = (MIN(self.bounds.size.width,self.bounds.size.height)-_lineWidth)/2;
    _backgroundLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2) radius:radius startAngle:-M_PI_2 endAngle:M_PI*2-M_PI_2 clockwise:YES].CGPath;
    _foregroundLayer.path = _backgroundLayer.path;
    _foregroundLayer.strokeEnd = _progress;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    if (_lineWidth != lineWidth) {
        _lineWidth = lineWidth;
        _backgroundLayer.lineWidth = _lineWidth;
        _foregroundLayer.lineWidth= _lineWidth;
    }
}

- (void)setFillColor:(UIColor *)fillColor {
    if (_fillColor != fillColor) {
        _fillColor = fillColor;
        _foregroundLayer.strokeColor = _fillColor.CGColor;
    }
}

- (void)setCircleColor:(UIColor *)circleColor {
    if (_circleColor != circleColor) {
        _circleColor = circleColor;
        _backgroundLayer.strokeColor = _circleColor.CGColor;
    }
}

- (void)setProgress:(CGFloat)progress {
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    if (_progress != progress) {
        _progress = progress;
        if (animated) {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.3];
        }
        [self updatePath];
        if (animated) {
            [UIView commitAnimations];
        }
    }
}

@end
