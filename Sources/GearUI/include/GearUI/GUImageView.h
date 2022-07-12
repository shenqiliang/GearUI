//
//  GUImageView.h
//  GearUI
//
//  Created by 谌启亮 on 03/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUNodeViewProtocol.h"


/// 基本图片视图
@interface GUImageView : UIImageView <GUNodeViewProtocol>

/// 显示内容，可为url、本地路径、image name、颜色值或图形表达式
@property (nonatomic, strong) NSString *content;

/// 高亮覆盖色
@property (nonatomic, strong) UIColor *highlightedCoverColor;

/// PlaceHolder图片
@property (nonatomic, strong) UIImage *placeholderImage;

/// 是否开启从PlaceHolder到真实网络图片渐变动画
@property (nonatomic) BOOL useFadeTransition;

/// 取消网络请求
- (void)cancelImageRequest;

/// 用户自定义信息
@property (nonatomic, strong) id userInfo;


@end
