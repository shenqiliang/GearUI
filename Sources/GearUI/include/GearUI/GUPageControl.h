//
//  GUPageControl.h
//  GearUI
//
//  Created by 谌启亮 on 13/09/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>

/// PageControl控件，提供类似UIPageControl功能，但具备更多自定义能力
@interface GUPageControl : UIControl

/// 总共Page数
@property (nonatomic) NSUInteger numberOfPages;

/// 当前Page
@property (nonatomic) NSInteger currentPage;

/// 圆点颜色
@property (nonatomic, strong) UIColor *dotColor;

/// 当前选中圆点颜色
@property (nonatomic, strong) UIColor *currentDotColor;

/// 圆点大小
@property (nonatomic) CGFloat dotSize;

/// 圆点间隔
@property (nonatomic) CGFloat dotSpacing;

@end
