//
//  GUXMLParser.h
//  GearUI
//
//  Created by 谌启亮 on 16/4/14.
//  Copyright © 2016年 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GUNode.h"
@protocol GUNodeProtocol;

/// XML解析器
@interface GUXMLParser : NSObject

/// 初始化
/// @param rootNode 用于更新的rootNode
- (instancetype)initWithRootNode:(GUNode *)rootNode;

/// 从XML字符串中解析并更新rootnode
- (void)parserForXMLString:(NSString *)xmlString;

/// 从XML文件中解析并更新rootnode
- (void)parserForXMLFile:(NSString *)filePath;

/// 从XML文件中初始化
- (instancetype)initWithXMLFile:(NSString *)filePath;

/// 从XML字符串中初始化
- (instancetype)initWithXMLString:(NSString *)xmlString;

/// 解析后的root node
@property (nonatomic, strong, readonly) GUNode *rootNode;

@end
