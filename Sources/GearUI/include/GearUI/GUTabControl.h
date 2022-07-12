//
//  GUTabControl.h
//  GearUI
//
//  Created by sidetang on 2017/10/1.
//  Copyright © 2017年 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GUTabControl : UIControl

/// 响应方法名
@property (nonatomic, strong) NSString *action;

// Tab标题列表
@property (nonatomic, copy) NSArray<NSString *> *items;

// 选中Tab索引
@property (nonatomic) NSInteger selectedIndex;

// 单个Tab宽度
@property (nonatomic) CGFloat itemWidth;

// Tab间隔
@property (nonatomic) CGFloat itemSpace;

// 选中标题颜色
@property (nonatomic, strong) UIColor *selectedTitleColor;

// 未选中标题颜色
@property (nonatomic, strong) UIColor *titleColor;

// 标题字体
@property (nonatomic, strong) UIFont *titleFont;

// 选中标题字体
@property (nonatomic, strong) UIFont *selectedTitleFont;

// 选中指示条颜色
@property (nonatomic, strong) UIColor *indicatorColor;

// 选中指示条图像
@property (nonatomic, strong) UIImage *indicatorImage;

// 选中指示条大小
@property (nonatomic) CGSize indicatorSize;

// 是否开启动画
@property (nonatomic) BOOL enableAnimation;

@end
