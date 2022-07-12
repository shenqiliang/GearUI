//
//  GUConfigure.h
//  GearUI
//
//  Created by 谌启亮 on 16/4/14.
//  Copyright © 2016年 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GUImageLoadDelegate.h"
#import "GUURLHandleDelegate.h"
#import "GULogHandleDelegate.h"

@interface GUConfigure : NSObject

@property(class, nonatomic, readonly) GUConfigure *sharedInstance NS_SWIFT_NAME(shared);

/// 开启实时调试模式。调用后启动监听。
- (BOOL)enableRuntimeDebug;

/// 判断是否开启了实时调试。
@property (nonatomic, assign, readonly) BOOL isEnableRuntimeDebug;

/// 图片加载代理。设置后可会使用代理方法下载网络图片。
@property (nonatomic, strong) id<GUImageLoadDelegate> imageLoadDelegate;

/// URL处理代理。设置后当GearUI打开一个URL时，会使用此代理回调。如果没有设置则使用UIApplication.openURL方法
@property (nonatomic, strong) id<GUURLHandleDelegate> URLHandleDelegate;

/// 日志打印代码。设置后，GearUI将调用此代理方法打印日志
@property (nonatomic, strong) id<GULogHandleDelegate> logHandleDelegate;

/// 本地补丁路径，如果设置，会优先从此路径中寻找布局文件
@property (nonatomic, strong) NSString *patchPath;

/// 设置节点的默认属性，可用于整体工程风格化
- (void)setDefaultAttributes:(NSDictionary *)attibutes forNodeName:(NSString *)nodeName;

@property (nonatomic, assign, readonly, getter=isKeyboardVisible) BOOL keyboardVisible;

/// 设置枚举名称字符串
- (void)setEnumeRepresentation:(NSDictionary<NSString *, NSNumber *> *)enumNameAndValues forPropertyName:(NSString *)property ofClass:(Class)cls;

/// 获取枚举名称字符串对应的枚举值
- (NSNumber *)enumValueForRepresentation:(NSString *)enumRepresentation forPropertyName:(NSString *)property ofClass:(Class)cls;

/// 注册一个新节点
- (void)registerNodeName:(NSString *)nodeName forClass:(Class)cls;

@end
