//
//  GUSlideBarItem.h
//  GearUI
//
//  Created by harmanhuang on 2017/10/23.
//  Copyright © 2017年 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GUSlideBarItemDelegate;

@interface GUSlideBarItem : UIView

@property (assign, nonatomic) BOOL selected;
@property (weak, nonatomic) id<GUSlideBarItemDelegate> delegate;

- (void)setItemTitle:(NSString *)title;
- (void)setItemTitleFont:(CGFloat)fontSize;
- (void)setItemTitleColor:(UIColor *)color;
- (void)setItemSelectedTitleColor:(UIColor *)color;

- (CGFloat)widthForTitle:(NSString *)title;

@end

@protocol GUSlideBarItemDelegate <NSObject>

- (void)slideBarItemSelected:(GUSlideBarItem *)item;

@end

