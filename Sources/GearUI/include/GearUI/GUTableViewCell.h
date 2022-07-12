//
//  GUTableViewCell.h
//  GearUI
//
//  Created by 谌启亮 on 30/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUNodeViewProtocol.h"

@class GULayoutView;

@interface GUTableViewCell : UITableViewCell <GUNodeViewProtocol>

/// 复制一份可复用的Cell
/// @param reuseIdentifier 复用ID
- (GUTableViewCell *)reuseCellWithIdentifier:(NSString *)reuseIdentifier;

/// 事件代理
@property(nonatomic, weak) id<GUNodeViewDelegate> nodeViewDelegate;

/// 加载完成回调，此时已做好属性绑定，可在此进行数据绑定
- (void)didLoadFromNode:(GUNode *)node;

/// 用户自定义信息
@property(nonatomic, strong) id userInfo;

/// GUNodeViewProtocol实现方法
- (UIView<GUNodeViewProtocol> *)viewWithNodeId:(NSString *)nodeId NS_SWIFT_NAME(view(nodeId:));

/// 选中时背景色
@property (nonatomic, strong) UIColor *selectedBackgroundColor;

/// 内容布局根视图
@property (nonatomic, strong, readonly) GULayoutView *layoutView;


@end
