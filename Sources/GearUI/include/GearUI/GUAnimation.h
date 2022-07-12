//
//  GUAnimation.h
//  GearUI
//
//  Created by 谌启亮 on 07/09/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GUNodeProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface GUAnimation : NSObject <GUNodeProtocol>

@property (nonatomic, strong, nullable) NSString *nodeId;

// 动画目标视图的node id
@property (nonatomic, strong, nullable) NSString *target;

// 动画的属性keypath
@property (nonatomic, strong, nullable) NSString *keyPath;

// 动画的唯一Key
@property (nonatomic, strong, nullable) NSString *animationKey;

// 动画属性的起始值
@property (nonatomic, strong, nullable) id fromValue;

// 动画属性的终值
@property (nonatomic, strong, nullable) id toValue;

// 动画持续时间
@property (nonatomic) NSTimeInterval duration;

// 是否自动运行，如果设置为YES，view appear时会自动运行动画
@property (nonatomic) BOOL autoRun;

// 动画的重复次数
@property (nonatomic) float repeatCount;

// 动画开始时间
@property (nonatomic) NSTimeInterval beginTime;

// 动画时间偏移
@property (nonatomic) NSTimeInterval timeOffset;

// 动画运行延迟
@property (nonatomic) NSTimeInterval delay;

// 动画时间函数
@property (nonatomic, strong, nullable) NSString *timeFunction;

// 动画结束时是否保留终值，会更新相关属性到终值
@property (nonatomic) BOOL updateToValue;

// 单独运行动画
- (void)runWithCompletion:(void(^ __nullable)(BOOL))completion;

// 停止动画
- (void)stop;

@end

NS_ASSUME_NONNULL_END
