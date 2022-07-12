//
//  GUNodeBinCoder.h
//  GearUI
//
//  Created by 谌启亮 on 30/03/2018.
//  Copyright © 2018 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GUNode.h"

/// 节点二进制编解码器
@interface GUNodeBinCoder : NSObject

/// 编码节点。生成二进制数据
/// @param node 要编码的节点
+ (NSData *)encodeWithNode:(GUNode *)node;

/// 解码节点
/// @param data 要解码的二进制数据
+ (GUNode *)decodeWithData:(NSData *)data;

@end
