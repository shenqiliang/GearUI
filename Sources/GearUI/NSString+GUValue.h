//
//  NSString+GUValue.h
//  GearUI
//
//  Created by 谌启亮 on 16/4/16.
//  Copyright © 2016年 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//将String转成其他对象
@interface NSString (GUValue)

- (UIColor *)gu_UIColorValue;
- (UIFont *)gu_UIFontValue;
- (UIImage *)gu_UIImageValue;

@end
