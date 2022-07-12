//
//  GUCollectionViewCell.h
//  GearUI
//
//  Created by 谌启亮 on 05/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUNodeViewProtocol.h"
@class GULayoutView;

@interface GUCollectionViewCell : UICollectionViewCell <GUNodeViewProtocol>

/// node id
@property (nonatomic, strong) NSString *nodeId;

/// 用户自定义信息
@property (nonatomic, strong) id userInfo;

/// 内容布局根视图
@property (nonatomic, strong, readonly) GULayoutView *layoutView;

@end
