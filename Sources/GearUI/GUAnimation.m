//
//  GUAnimation.m
//  GearUI
//
//  Created by 谌启亮 on 07/09/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUAnimation.h"
#import "GUAnimation+GUPrivate.h"

@implementation GUAnimation
{
    NSArray *_subAnimations;
    CAAnimation *_animation;
    void(^_completion)(BOOL);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _duration = 0.3;
        _updateToValue = YES;
    }
    return self;
}

- (void)setLayoutView:(GULayoutView *)layoutView {
    for (GUAnimation *animation in _subAnimations) {
        animation.layoutView = layoutView;
    }
    _layoutView = layoutView;
}

- (void)runWithCompletion:(void(^)(BOOL))completion {
    _completion = completion;
    if (self.delay >= __FLT_EPSILON__) {
        __weak id weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf _run];
        });
    }
    else {
        [self _run];
    }
}

- (void)updateChildren:(NSArray *)children {
    NSMutableArray *array = [NSMutableArray array];
    for (GUAnimation *animation in children) {
        if ([animation isKindOfClass:[GUAnimation class]]) {
            [array addObject:animation];
        }
    }
    _subAnimations = [array copy];
}

- (CAAnimation *)animation {
    if (_animation) {
        if (_fromValue == nil && [_animation isKindOfClass:[CABasicAnimation class]]) {
            UIView *targetView = [self.layoutView viewWithNodeId:self.target];
            ((CABasicAnimation *)_animation).fromValue = [targetView.layer.presentationLayer valueForKeyPath:_keyPath];
        }
        return _animation;
    }
    if ([_subAnimations count] == 0) {
        UIView *targetView = [self.layoutView viewWithNodeId:self.target];
        NSString *keyPath = _keyPath;
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:keyPath];
        animation.duration = self.duration;
        animation.fromValue = [self _genValueFromRaw:self.fromValue ofKeyPath:keyPath];
        if (animation.fromValue == nil) {
            animation.fromValue = [targetView.layer.presentationLayer valueForKeyPath:keyPath];
        }
        animation.toValue = [self _genValueFromRaw:self.toValue ofKeyPath:keyPath];
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        animation.repeatCount = _repeatCount;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:self.timeFunction];
        animation.beginTime = _beginTime;
        animation.timeOffset = _timeOffset;
        _animation = animation;
    }
    else {
        CAAnimationGroup *animation = [CAAnimationGroup animation];
        NSMutableArray *array = [NSMutableArray array];
        for (GUAnimation *a in _subAnimations) {
            CAAnimation *ani = [a animation];
            if (ani) {
                [array addObject:ani];
            }
        }
        animation.duration = self.duration;
        animation.animations = [array copy];
        animation.removedOnCompletion = NO;
        animation.repeatCount = _repeatCount;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:self.timeFunction];
        animation.beginTime = _beginTime;
        _animation = animation;
    }
    return _animation;
}

- (void)_run {
    UIView *targetView = [self.layoutView viewWithNodeId:self.target];
    if (targetView) {
        CAAnimation *animation = [self animation];
        animation.delegate = self;
        [targetView.layer addAnimation:animation forKey:_animationKey ?: _keyPath];
        if ([animation isKindOfClass:[CABasicAnimation class]] && _updateToValue) {
            if (_updateToValue) {
                CABasicAnimation *baseAnimation = (id)animation;
                [targetView.layer setValue:baseAnimation.toValue forKeyPath:baseAnimation.keyPath];
            }
        }
    }
}

- (NSString *)timeFunction {
    if ([_timeFunction isEqualToString:@"linear"]) {
        return kCAMediaTimingFunctionLinear;
    }
    else if ([_timeFunction isEqualToString:@"easeIn"]) {
        return kCAMediaTimingFunctionEaseIn;
    }
    else if ([_timeFunction isEqualToString:@"easeOut"]) {
        return kCAMediaTimingFunctionEaseOut;
    }
    else if ([_timeFunction isEqualToString:@"easeInOut"] || [_timeFunction isEqualToString:@"easeInEaseOut"]) {
        return kCAMediaTimingFunctionEaseInEaseOut;
    }
    if ([_subAnimations count] == 0) {
        return kCAMediaTimingFunctionDefault;
    }
    else {
        return kCAMediaTimingFunctionLinear;
    }
}

- (void)stop {
    UIView *targetView = [self.layoutView viewWithNodeId:self.target];
    [targetView.layer removeAnimationForKey:_animationKey ?: _keyPath];
    _completion = nil;
    _animation.delegate = nil;
}

- (id)_genValueFromRaw:(NSString *)rawValue ofKeyPath:(NSString *)keyPath {
    if (![rawValue isKindOfClass:[NSString class]]) {
        return rawValue;
    }
    if ([rawValue hasSuffix:@"%"]) {
        return @([[rawValue substringToIndex:rawValue.length-1] floatValue]/100.0*[UIScreen mainScreen].bounds.size.width);
    }
    if ([rawValue length]) {
        return @([rawValue floatValue]);
    }
    else{
        return nil;
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (_completion) {
        _completion(flag);
        _animation.delegate = nil;
        _completion = nil;
    }
}

@end
