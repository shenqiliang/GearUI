//
//  GUJavaScriptManager.h
//  GearUI
//
//  Created by 谌启亮 on 14/12/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
@class GULayoutView;

@interface GUJavaScriptManager : NSObject
/// 单例对象
@property (class, nonatomic, readonly) GUJavaScriptManager *sharedInstance NS_SWIFT_NAME(shared);

/// JavaScript虚拟机
@property (nonatomic, strong, readonly) JSVirtualMachine *virtualMachine;

/// 生成一个JS运行环境
/// @param layoutView JS运行环境的LayoutView
- (JSContext *)genContextInLayoutView:(GULayoutView *)layoutView;

/// 执行垃圾回收，不建议使用
/// @param context 目标Context
- (void)garbageCollectContext:(JSContext *)context;

/// 删除JS运行环境。当调用genContextInLayoutView:时生成一个Context，如果不再使用需要删除它。
/// @param context JS运行环境的Contxt
- (void)deleteContext:(JSContext *)context;

/// 设置全局变量
/// @param var 变量值
/// @param name 变量名
/// @param context 变量所在的Context
- (void)setGlobalVar:(id)var forName:(NSString *)name inContext:(JSContext *)context;

@end
