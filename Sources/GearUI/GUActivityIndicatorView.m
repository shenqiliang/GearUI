//
//  GUActivityIndicatorView.m
//  GearUI
//
//  Created by harmanhuang on 2017/10/26.
//  Copyright © 2017年 谌启亮. All rights reserved.
//

#import "GUActivityIndicatorView.h"

#define TimeIntervalCheckTimeout 0.5

@interface GUActivityIndicatorView()

@property (nonatomic, strong) NSDate *timeStartAnimating;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation GUActivityIndicatorView

- (void)startAnimating
{
    [super startAnimating];
    
    if (self.shouldAutoHideWhenTimeout && self.timeIntervalToHide > 0) {
        self.timeStartAnimating = [NSDate new];
        [self.timer invalidate];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:TimeIntervalCheckTimeout target:self selector:@selector(onTimerSchedule) userInfo:nil repeats:YES];
    } else {
        self.timeStartAnimating = nil;
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)stopAnimating
{
    [super stopAnimating];
    
    self.timeStartAnimating = nil;
    [self.timer invalidate];
    self.timer = nil;
}

- (void)onTimerSchedule
{
    NSTimeInterval timeInterval = [[NSDate new] timeIntervalSinceDate:self.timeStartAnimating];
    if (timeInterval >= self.timeIntervalToHide) {
        [self stopAnimating];
        if ([self.animationDelegate respondsToSelector:@selector(onTimeout:)]) {
            [self.animationDelegate onTimeout:self];
        }
    }
}

#pragma mark - setter & getter
- (CGFloat)timeIntervalToHide
{
    if (_timeIntervalToHide <= 0) {
        _timeIntervalToHide = 6;
    }
    return _timeIntervalToHide;
}

@end
