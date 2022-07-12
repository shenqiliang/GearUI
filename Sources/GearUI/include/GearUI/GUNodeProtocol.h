//
//  GUNode.h
//  GearUI
//
//  Created by 谌启亮 on 16/4/14.
//  Copyright © 2016年 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "GUNode.h"
#import "GUJSObjectProtocol.h"

/// 节点对象Protocol。自定义的对象可实现此可选协议进行更精细化的控制对象生成。
@protocol GUNodeProtocol <NSObject>

@optional

/// 初始化需要的节点属性。一些对象初始化时有必须参数，可用此方法设置初始化需要的节点属性，然后用此属性在`newObjectWithAttributes:`方法中创建对象。
+ (NSArray *)initializedAttributeKeys;

/// 根据初始化属性生成一个对象
/// @param initializedAttributes 初始化属性，可由initializedAttributeKeys指定属性名
+ (id)newObjectWithAttributes:(NSDictionary *)initializedAttributes;

/**
 节点id
 */
@property (nonatomic, strong) NSString *nodeId;


/// 更新对象子节点。此方法用来实现子节点属性。
/// @param subnodes 子节点
/// @return 返回不支持的子节点。
- (NSArray<GUNode *> *)updateSubnodes:(NSArray<GUNode *> *)subnodes;


/**
 根据子对象更新视图

 @param children 子对象
 */
- (void)updateChildren:(NSArray *)children;


/// 需要延迟更新的节点属性。用于需要强制后更新的属性
- (NSArray *)delayedUpdateAttributeNames;

/**
 更新多个关联属性，updateChildren后更新属性

 @param attributes 全部属性
 @return 需要进一步处理的属性
 */
- (NSDictionary *)updateCombinedAttributes:(NSDictionary *)attributes;


/**
 更新单个属性

 @param value 属性值
 @param name 属性名称
 @return 是否已经处理。返回NO，进行继续处理（动态属性解析）
 */
- (BOOL)updateAttributeValue:(NSString *)value forName:(NSString *)name;

//可选方法
- (void)didLoadFromNode:(GUNode *)node;
- (void)didUpdateAttributes;

//接口方法，不需要实现
- (void)setKeyPathAttributes:(NSDictionary<NSString *, id> *)keyPathAttributes;
- (void)setAttribute:(id)attribute forKeyPath:(NSString *)keyPath;


//+ (NSSet *)initializeAttributeNames;
//+ (id)newObjectFormInitializeAttributes:(NSDictionary *)attributes;

- (id<GUNodeProtocol>)subnodeWithId:(NSString *)nodeId;

@end

@interface NSObject (GUNode) <GUJSObjectProtocol>

//节点ID
@property (nonatomic, strong) NSString *nodeId;

- (void)setKeyPathAttributes:(NSDictionary<NSString *, id> *)keyPathAttributes;
- (void)setAttribute:(id)attribute forKeyPath:(NSString *)keyPath;

@end


