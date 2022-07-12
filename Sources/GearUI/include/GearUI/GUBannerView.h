//
//  GUBannerView.h
//  GearUI
//
//  Created by 谌启亮 on 13/09/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUNodeViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// 图片条幅视图
@interface GUBannerView : UIControl <GUNodeViewProtocol>

/// 全部图片路径
@property (nonatomic, strong, nullable) NSArray<NSString *> *imagePaths;

/// 当前页
@property (nonatomic) NSInteger currentPage;

/// 设置当前页
- (void)setCurrentPage:(NSInteger)currentPage animated:(BOOL)animated;

/// 绑定的UIPageControl的Id，当页数变化时，同步更新
@property (nonatomic, strong, nullable) NSString *pageControlId;

/// 是否自动滚动下一页
@property (nonatomic) BOOL autoScroll;

/// 自动滚动时间间隔
@property (nonatomic) NSTimeInterval scrollTimeInterval;

@end

NS_ASSUME_NONNULL_END
