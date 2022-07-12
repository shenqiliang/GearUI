//
//  GULabel.h
//  GearUI
//
//  Created by 谌启亮 on 30/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUNodeViewProtocol.h"

UIKIT_EXTERN NSAttributedStringKey const GUHighlightedTextColorAttributeName;
UIKIT_EXTERN NSAttributedStringKey const GUHighlightedTextBackgroundColorAttributeName;

/// 基本文本标签视图
@interface GULabel : UILabel <GUNodeViewProtocol>

/// 富文本xml，支持常见的html格式
@property (nonatomic, strong) NSString *xml;

/// 行间距
@property (nonatomic) CGFloat lineSpace;

/// 行高，建议全部文字使用相同字体时才设置此值
@property (nonatomic) CGFloat lineHeight;

/// 已显示行数
@property (nonatomic, readonly) NSUInteger displayedNumberOfLines;

//是否截断
@property (nonatomic, getter=isTruncated, readonly) BOOL truncated;


// 截断显示的字符，默认“”
@property (nonatomic, strong) NSAttributedString *truncationString;

@end
