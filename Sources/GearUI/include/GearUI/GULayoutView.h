//
//  GULayout.h
//  GearUI
//
//  Created by 谌启亮 on 16/4/15.
//  Copyright © 2016年 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "GUNodeProtocol.h"
#import "GUNodeViewDelegate.h"
#import "GUNodeViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface GULayoutView : UIView <GUNodeViewProtocol>

/**
 从xml布局文件初始化LayoutView

 @param fileName app bundle内的xml文件名称
 */
- (instancetype)initWithFileName:(NSString *)fileName NS_DESIGNATED_INITIALIZER;

/**
 使用Node初始化LayoutView
 */
- (instancetype)initWithNode:(nullable GUNode *)node NS_DESIGNATED_INITIALIZER;


/**
 事件处理代理
 */
@property (nonatomic, weak, nullable) id<GUNodeViewDelegate> nodeViewDelegate;


/// 是否默认使用SafeArea。如果开启，子视图始终相对SafeArea内布局。
@property (nonatomic) BOOL useSafeAreaLayout;


/// 是否高亮显示
@property (nonatomic, getter=isHighlighted) BOOL highlighted;

/// 当按住时高亮显示
@property (nonatomic) BOOL highlightContentWhenTouch;

/// 自动运行子节点动画
- (void)autoRunAnimation;

/// 运行单个子节点动画
/// @param nodeId Animation节点的nodeId
- (void)runAnimationWithNodeId:(NSString *)nodeId;


/// 运行单个子节点动画，Animation节点必须时Layout的子节点
/// @param nodeId Animation节点的nodeId
/// @param completion 完成回调
- (void)runAnimationWithNodeId:(NSString *)nodeId completion:(nullable void(^)(BOOL))completion;


/// 停止运行子节点动画
/// @param nodeId Animation节点的nodeId
- (void)stopAnimationWithNodeId:(NSString *)nodeId;


/// 数据绑定
/// @param obj 数据源对象
/// @param keyPath 数据源对象的KeyPath
/// @param toKeyPath 目标节点属性KeyPath
- (void)bind:(NSObject *)obj keyPath:(NSString *)keyPath toKeyPath:(NSString *)toKeyPath;


/// 数据绑定
/// @param obj 数据源对象
/// @param keyPath 数据源对象的KeyPath
/// @param toKeyPath 目标节点属性KeyPath
/// @param map 数值转换
- (void)bind:(NSObject *)obj keyPath:(NSString *)keyPath toKeyPath:(NSString *)toKeyPath map:(id (^ _Nullable)(id _Nullable))map ;


/// 移除数据绑定
- (void)removeBindingToKeyPath:(NSString *)toKeyPath;

/// 移除所有数据绑定
- (void)removeAllBindings;

@end

NS_ASSUME_NONNULL_END
