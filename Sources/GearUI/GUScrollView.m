//
//  GUScrollView.m
//  GearUI
//
//  Created by 谌启亮 on 2017/7/1.
//  Copyright © 2017年 谌启亮. All rights reserved.
//

#import "GUScrollView.h"
#import "GULayoutView.h"

@interface GUScrollView ()

@property (nonatomic, assign) CGFloat gesturePointX;    // 滑动返回的起点，默认值45

@end

@implementation GUScrollView
{
    GULayoutView *_layoutView;
    NSLayoutConstraint *_layoutWidthConstraint;
    NSLayoutConstraint *_layoutHeightConstraint;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _layoutView = [GULayoutView new];
        _layoutView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_layoutView];
        [_layoutView setAttribute:@"0" forKeyPath:@"top"];
        [_layoutView setAttribute:@"0" forKeyPath:@"left"];
        [_layoutView setAttribute:@"0" forKeyPath:@"bottom"];
        [_layoutView setAttribute:@"0" forKeyPath:@"right"];

//        NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:_layoutView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
//        centerX.priority = UILayoutPriorityDefaultLow;
//        NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:_layoutView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
//        centerY.priority = UILayoutPriorityDefaultLow;
//
//        [self addConstraints:@[centerY, centerX/*, bottom, right*/]];
        
//        if (@available(iOS 11, *)) {
//            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
//        }

    }
    return self;
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    return YES;
}

- (void)updateChildren:(NSArray *)children {
    [_layoutView updateChildren:children];
}

- (void)setFixContentWidth:(BOOL)fixContentWidth {
    if (_fixContentWidth != fixContentWidth) {
        if (fixContentWidth) {
            _layoutWidthConstraint = [NSLayoutConstraint constraintWithItem:_layoutView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
            [self addConstraint:_layoutWidthConstraint];
        }
        else {
            [self removeConstraint:_layoutWidthConstraint];
        }
    }
}

- (void)setFixContentHeight:(BOOL)fixContentHeight {
    if (_fixContentHeight != fixContentHeight) {
        if (fixContentHeight) {
            _layoutHeightConstraint = [NSLayoutConstraint constraintWithItem:_layoutView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
            [self addConstraint:_layoutHeightConstraint];
        }
        else {
            [self removeConstraint:_layoutHeightConstraint];
        }
    }
}

- (void)setContentSize:(CGSize)contentSize {
    [super setContentSize:contentSize];
    if (_fitContent) {
        [self invalidateIntrinsicContentSize];
    }
}

- (CGSize)intrinsicContentSize {
    if (_fitContent) {
        return self.contentSize;
    }
    else {
        return [super intrinsicContentSize];
    }
}



#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.view == self && [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]  && self.shouldBackByGesture) {
        UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint translationPoint = [panGesture translationInView:self];
        CGPoint touchLocation = [panGesture locationInView:self];
        if (translationPoint.x > 0 && fabs(translationPoint.x) > fabs(translationPoint.y)) {
            if (touchLocation.x < self.gesturePointX) {
                return false;
            }
        }
        return YES;
    }
    return YES;
}

#pragma mark - getter
- (CGFloat)gesturePointX
{
    if (_gesturePointX <= 0) {
        _gesturePointX = 45.0f;
    }
    return _gesturePointX;
}

@end
