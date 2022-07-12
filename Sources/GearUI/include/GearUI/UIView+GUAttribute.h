//
//  UIView+GUAttribute.h
//  GearUI
//
//  Created by 谌启亮 on 03/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>

/// 一些通用的View属性
@interface UIView (GUAttribute)

@property (nonatomic) BOOL disableLayout;

@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic, strong) UIColor *borderColor;

@property (nonatomic) CGFloat zPosition;

@property (nonatomic, strong) UIColor *shadowColor;
@property (nonatomic) float shadowOpacity;
@property (nonatomic) CGSize shadowOffset;
@property (nonatomic) CGFloat shadowRadius;
@property (nonatomic) CACornerMask maskedCorners;

@property (nonatomic) UILayoutPriority contentHuggingPriorityHorizontal;
@property (nonatomic) UILayoutPriority contentHuggingPriorityVertical;

@property (nonatomic) UILayoutPriority contentCompressionResistancePriorityHorizontal;
@property (nonatomic) UILayoutPriority contentCompressionResistancePriorityVertical;

@end
