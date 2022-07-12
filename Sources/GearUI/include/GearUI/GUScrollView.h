//
//  GUScrollView.h
//  GearUI
//
//  Created by 谌启亮 on 2017/7/1.
//  Copyright © 2017年 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUNodeViewProtocol.h"

// 提供更多精准控制ScrollView
@interface GUScrollView : UIScrollView

/// 是否固定content的宽度，设置为YES时，contentWidth和scroll view的宽度始终保持一致
@property (nonatomic) BOOL fixContentWidth;

/// 是否固定content的高度，设置为YES时，contentHeight和scroll view的高度始终保持一致
@property (nonatomic) BOOL fixContentHeight;

@property (nonatomic, assign) BOOL shouldBackByGesture;     // 是否可以滑动返回

/// 是否自动适应内容大小
@property (nonatomic, getter=isFitConntent) BOOL fitContent;


@end
