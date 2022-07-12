//
//  GUTextView.h
//  GearUI
//
//  Created by 谌启亮 on 16/4/15.
//  Copyright © 2016年 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUNodeProtocol.h"

@interface GUTextView : UITextView

/// 最大输入长度（字符个数）
@property (nonatomic) NSInteger maxInputLength;

/// 最大输入宽度，一个中文字符占两个宽度
@property (nonatomic) NSInteger maxInputWidth;

/// 可输入字符集
@property (nonatomic, strong) NSCharacterSet *allowInputCharacterSet;

/// placeholder文本
@property (nonatomic, strong) NSString *placeholder;

@end
