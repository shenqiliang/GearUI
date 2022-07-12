//
//  GUTableView.h
//  GearUI
//
//  Created by 谌启亮 on 30/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUNodeViewProtocol.h"
#import "GUTableViewCell.h"

@interface GUTableView : UITableView <GUNodeViewProtocol>

/// dequeue一个可复用的Cell
/// @param nodeId 样式Cell的nodeId
- (GUTableViewCell *)dequeueCellWithNodeId:(NSString *)nodeId;

/**
 根据node id和attributes返回复用Cell

 @param nodeId cell的node id
 @param attributes 默认的约束等属性
 @return 根据node id和attributes复用Cell
 */
- (GUTableViewCell *)dequeueCellWithNodeId:(NSString *)nodeId defaultAttributes:(NSDictionary *)attributes;

/// 根据节点id生成一个view，用于section header或者footer
- (UIView<GUNodeViewProtocol> *)generateViewWithNodeId:(NSString *)nodeId NS_SWIFT_NAME(generateView(nodeId:));

/// 将一个view指定为tablevie的header
@property (nonatomic, strong) NSString *headerViewNodeId;

/// 将一个view指定为tablevie的footer
@property (nonatomic, strong) NSString *footerViewNodeId;

/// 移除TableView下方的分割线
@property (nonatomic, getter=isRemoveRedundantSeparator) BOOL removeRedundantSeparator;

/// 自动反选Cell。设置为YES，当用户选中一个Cell时会自动反选
@property (nonatomic) BOOL autoDeselectCell;

/// 是否适应内容大小，保持tableview大小与contentsize一致
@property (nonatomic, getter=isFitConntent) BOOL fitContent;

/// 物理动画滚动
- (void)phyicalAnimatedScrollToContentOffset:(CGPoint)contentOffset velocity:(CGFloat)velocity;

@end
