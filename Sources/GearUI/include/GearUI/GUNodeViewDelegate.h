//
//  GUNodeViewDelegate.h
//  GearUI
//
//  Created by 谌启亮 on 30/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol GUNodeProtocol;

/// 视图节点代理
@protocol GUNodeViewDelegate <NSObject>

/// 视图中某个节点被点击
/// @param nodeView 视图对象
/// @param node 节点对象
/// @return 是否处理成功
- (BOOL)nodeView:(UIView<GUNodeProtocol> *)nodeView didTapNode:(id<GUNodeProtocol>)node;

@end
