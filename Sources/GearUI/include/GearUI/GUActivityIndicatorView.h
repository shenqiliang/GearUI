//
//  GUActivityIndicatorView.h
//  GearUI
//
//  Created by harmanhuang on 2017/10/26.
//  Copyright © 2017年 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class GUActivityIndicatorView;

// delegate for activity indicator
@protocol GUActivityIndicatorViewAnimationDelegate <NSObject>

@optional
// 超时时通知回调
- (void)onTimeout:(GUActivityIndicatorView *)activityIndicatorView;

@end

@interface GUActivityIndicatorView : UIActivityIndicatorView

// delegate
@property (nonatomic, weak, nullable) id<GUActivityIndicatorViewAnimationDelegate> animationDelegate;

// 是否超时自动隐藏
@property (nonatomic, assign) BOOL shouldAutoHideWhenTimeout;

/** 超时时间，默认为6s */
@property (nonatomic, assign) CGFloat timeIntervalToHide;

@end

NS_ASSUME_NONNULL_END
