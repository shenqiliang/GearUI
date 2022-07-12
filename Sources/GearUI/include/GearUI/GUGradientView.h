//
//  GUGradientView.h
//  GearUI
//
//  Created by 谌启亮 on 04/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "GUNodeViewProtocol.h"

// 渐变视图
@interface GUGradientView : UIView <GUNodeViewProtocol>
// 渐变颜色值数组
@property (copy, nonatomic) NSArray *colors;
// 渐变location【0-1】
@property (copy, nonatomic) NSArray<NSNumber *> *locations;
// 起点，坐标取值范围【0-1】
@property (nonatomic) CGPoint startPoint;
// 终点，坐标取值范围【0-1】
@property (nonatomic) CGPoint endPoint;
// layer
@property(nonatomic,readonly,strong) CAGradientLayer *layer;


@end
