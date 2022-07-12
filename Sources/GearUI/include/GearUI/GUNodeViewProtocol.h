//
//  GUNodeViewProtocol.h
//  GearUI
//
//  Created by 谌启亮 on 30/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUNodeProtocol.h"
#import "GUNodeViewDelegate.h"
#import "GUJSViewProtocol.h"

/// View节点对象Protocol。自定义的View类可实现此可选协议进行更精细化的控制View生成。
@protocol GUNodeViewProtocol <GUNodeProtocol>

@optional

/// View的事件代理
@property (nonatomic, weak) id<GUNodeViewDelegate> nodeViewDelegate;

/// 获取子视图（包含自身）
/// @param nodeId 子视图或者自身的nodeId
- (UIView<GUNodeViewProtocol> *)viewWithNodeId:(NSString *)nodeId NS_SWIFT_NAME(view(nodeId:));

/// 根据KeyPath设置视图或者其子视图的多个属性
/// @param keyPathAttributes 多个属性KeyPath和属性值
- (void)setKeyPathAttributes:(NSDictionary<NSString *, id> *)keyPathAttributes;

/// 根据KeyPath设置视图或者其子视图的单个属性
/// @param attribute 属性值
/// @param keyPath 属性KeyPath
- (void)setAttribute:(id)attribute forKeyPath:(NSString *)keyPath;

@end


/// UIView的默认实现方法
@interface UIView (GUNodeView) <GUJSViewProtocol>


/// 获取子视图（不包含自身）
/// @param nodeId 子视图的nodeId
- (UIView<GUNodeViewProtocol> *)subviewWithNodeId:(NSString *)nodeId;

/// 获取子视图（包含自身）
/// @param nodeId 子视图或者自身的nodeId
- (UIView<GUNodeViewProtocol> *)viewWithNodeId:(NSString *)nodeId NS_SWIFT_NAME(view(nodeId:));


/// 获取子节点对象
/// @param nodeId 子节点对象的nodeId
- (id<GUNodeProtocol>)subnodeWithId:(NSString *)nodeId;

@end
