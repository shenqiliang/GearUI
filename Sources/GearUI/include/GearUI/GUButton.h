//
//  GUButton.h
//  GearUI
//
//  Created by 谌启亮 on 03/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUNodeViewProtocol.h"


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, GUButtonLayoutType) {
    GUButtonLayoutTypeDefault = 0, // 默认，图片显示左边，标题显示右边
    GUButtonLayoutTypeTitleRight = 1, // 图片显示左边，标题显示右边
    GUButtonLayoutTypeTitleLeft = 2, // 图片显示右边，标题显示左边
    GUButtonLayoutTypeTitleBottom = 3, // 图片显示上边，标题显示下边
    GUButtonLayoutTypeTitleTop = 4, // 图片显示下边，标题显示上边
};


/*!
 * 按钮控件
 * @discussion 支持自定义各状态按钮标题（title）、标题颜色（titleColor）、标题阴影颜色（titleShadowColor）、图片（image）、背景图片（backgroundImage）。
 * @discussion 属性采用“状态”+“属性名”方式命名，如selectedTitle、highlightedSelectedTitle
 * @li 1. 设置按钮各种状态标题 @code <Button title="NormalTitle" selectedTitle="SeletedTitle" highlightedTitle="HighlightedTitle" highlightedSelectedTitle="HighlightedSelectedTitle"/> @endcode
 * @li 2. 设置按钮图片 @code <Button image="icon_btn" highlightedImage="icon_btn_highlighted"/> @endcode
 * @li 3. 设置按钮背景图片 @code <Button backgroundImage="icon_btn" highlightedBackgroundImage="icon_btn_highlighted"/> @endcode
 * @li ...
 */
@interface GUButton : UIButton <GUNodeViewProtocol>

// 按钮响应事件
@property (nonatomic, strong, nullable) NSString *action;

// 是否延迟高亮。如果设置为YES，当按钮快速点击时，取消高亮态会有视觉上的延迟以给用户明确提示。
@property (nonatomic) BOOL delaysHighlighting;

// 按钮图片和title的布局关系，参见GUButtonLayoutType
@property (nonatomic) GUButtonLayoutType layoutType;

// 自定义用户信息
@property (nonatomic) id userInfo;

@end

NS_ASSUME_NONNULL_END
