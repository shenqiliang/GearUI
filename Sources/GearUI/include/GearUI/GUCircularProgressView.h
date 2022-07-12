//
//  GUCircleProgressView.h
//  GearUI
//
//  Created by 谌启亮 on 13/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 圆形进度条
@interface GUCircularProgressView : UIView

// 当前进度，取值范围【0-1】
@property (nonatomic) CGFloat progress;

// 设置进度，可使用动画
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;

// 进度条宽度
@property (nonatomic) CGFloat lineWidth;

// 进度条填充颜色
@property (nonatomic, strong, nullable) UIColor *fillColor;

// 进度条背景色
@property (nonatomic, strong, nullable) UIColor *circleColor;

@end

NS_ASSUME_NONNULL_END
