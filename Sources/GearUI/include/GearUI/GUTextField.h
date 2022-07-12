//
//  GUTextField.h
//  GearUI
//
//  Created by 谌启亮 on 21/09/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUNodeViewProtocol.h"

@interface GUTextField : UITextField <GUNodeViewProtocol>

/// PlaceHolder文本颜色
@property (nonatomic, strong) UIColor *placeholderColor;

/// 最大输入长度（字符个数）
@property (nonatomic) NSInteger maxInputLength;

/// 最大输入宽度，一个中文字符占两个宽度
@property (nonatomic) NSInteger maxInputWidth;

/// 可输入字符集
@property (nonatomic, strong) NSCharacterSet *allowInputCharacterSet;

/// 是否禁止长按系统菜单
@property (nonatomic, assign) BOOL disableMenu;

@end
