//
//  UIView+GUNode.h
//  GearUI
//
//  Created by 谌启亮 on 16/4/16.
//  Copyright © 2016年 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (GUPrivate)

@property (nonatomic, strong, readonly) NSMutableDictionary *gu_userInfo;
@property (nonatomic) BOOL disableLayout;
@property (nonatomic) UIEdgeInsets touchEdgeInsets;

@property (nonatomic, strong) UIColor *backgroundColor;

- (void)gu_handleViewTap;
- (void)gu_runAction:(NSString *)action;

@end
