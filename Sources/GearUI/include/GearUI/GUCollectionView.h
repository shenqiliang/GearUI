//
//  GUCollectionView.h
//  GearUI
//
//  Created by 谌启亮 on 05/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUNodeViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class GUCollectionViewCell, GUCollectionView;

// GUCollectionView布局Delegte
@protocol GUCollectionViewLayoutSubViewDelegate <NSObject>

@optional
- (void)collectionViewWillLayoutSubviews:(GUCollectionView *)collectionView; // 布局子视图回调

@end

// GUCollectionView，继承自UICollectionView
@interface GUCollectionView : UICollectionView <GUNodeViewProtocol>

// 滚动方向
@property (nonatomic) NSString *scrollDirection;
// 布局代理
@property (nonatomic, weak, nullable) id<GUCollectionViewLayoutSubViewDelegate> layoutSubViewDelegate;
// 行间距
@property (nonatomic) CGFloat minimumLineSpacing;
// item间距
@property (nonatomic) CGFloat minimumInteritemSpacing;
// item大小
@property (nonatomic) CGSize estimatedItemSize;
// 是否靠左对齐
@property (nonatomic) BOOL alignLeft;
// dequeue一个不显示cell用于复用
- (GUCollectionViewCell *)dequeueCellWithNodeId:(NSString *)nodeId forIndexPath:(NSIndexPath *)indexPath;
// 用户自定义信息
@property(nonatomic, strong) id userInfo;


@end

NS_ASSUME_NONNULL_END
