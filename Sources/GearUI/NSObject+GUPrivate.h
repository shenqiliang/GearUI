//
//  NSObject+GUPrivate.h
//  GearUI
//
//  Created by 谌启亮 on 29/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (GUPrivate)

@property (nonatomic, strong) NSDictionary *gu_loadedAttributes;

//自定义属性更新
- (void)gu_setAttributeValue:(NSString *)value forName:(NSString *)name;
- (void)gu_setAttributeValues:(NSDictionary *)attributes;

- (NSArray *)gu_delayedUpdateAttributeNames;

- (void)gu_sendNodeDidTapAction;

- (void)gu_bindPropertyForSubClassOf:(Class)cls;

@end
