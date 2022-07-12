//
//  GUViewController.h
//  GearUI
//
//  Created by 谌启亮 on 16/4/15.
//  Copyright © 2016年 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUNodeProtocol.h"
#import "GULayoutView.h"
#import "GUNodeViewDelegate.h"

@interface GUViewController : UIViewController <GUNodeProtocol, GUNodeViewDelegate>


/**
 初始化方法

 @param node 初始化用的节点，为nil时读取类同名的xml文件
 @return 一个新的GUViewController
 */
- (nonnull instancetype)initWithNode:(nullable GUNode *)node fileName:(nullable NSString *)fileName NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, nonnull) GULayoutView *view;

/// 背景色
@property (nonatomic, strong, nullable) UIColor *backgroundColor;

/// 当显示键盘是否自动上移
@property (nonatomic) BOOL offsetViewWhenKeyboardShow;

/// 点击未响应区域是否自动隐藏键盘，默认YES
@property (nonatomic) BOOL autoHideKeyboard;

/// 布局时是否默认使用safeArea
@property (nonatomic) BOOL useSafeAreaLayout;

@end
