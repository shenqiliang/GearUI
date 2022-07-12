//
//  GUPickerView.h
//  GearUI
//
//  Created by 谌启亮 on 09/03/2018.
//  Copyright © 2018 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>

// PickerView
@interface GUPickerView : UIPickerView

@property (nonatomic) CGFloat rowHeight; // 行高度

/// 文本颜色
@property (nonatomic, strong) UIColor *textColor;

/// 用户自定义信息
@property (nonatomic, strong) id userInfo;

/// 获取单个component选中的值
/// @param component 所获取的component
- (NSString *)selectedValueInComponent:(NSInteger)component;

/// 设置选中的值
/// @param value 选中的值
/// @param component 所选中值所在的component
/// @param animated 是否进行动画
- (void)selectValue:(NSString *)value inComponent:(NSInteger)component animated:(BOOL)animated;

@end
