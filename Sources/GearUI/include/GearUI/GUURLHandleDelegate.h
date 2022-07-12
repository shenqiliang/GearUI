//
//  GUURLHandleDelegate.h
//  GearUI
//
//  Created by 谌启亮 on 19/10/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GUNodeProtocol.h"

/// GearUI框架的URL处理代理。用于精细化处理URL打开方式
@protocol GUURLHandleDelegate <NSObject>

@optional

/// 打开一个URL
/// @param url 打开的url
/// @param node 触发的节点
- (BOOL)handleOpenURL:(NSURL *)url node:(id<GUNodeProtocol>)node;

@end
