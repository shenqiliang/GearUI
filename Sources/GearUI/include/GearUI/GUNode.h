//
//  GUNode.h
//  GearUI
//
//  Created by 谌启亮 on 01/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol GUNodeProtocol;

OBJC_EXTERN NSString *GUNodeEscapeXML(NSString *content);

/// 节点类。XML解析后生成的产物。
__attribute__((objc_subclassing_restricted)) @interface GUNode : NSObject <NSCopying>

/// 通过XML文件名生成节点
/// @param fileName main bundle中XML文件名
+ (GUNode *)nodeWithFileName:(NSString *)fileName;

/// 通过XML字符串生成节点
/// @param xmlString xml字符串
+ (GUNode *)nodeWithXMLString:(NSString *)xmlString;

/// 通过xml文件路径生成节点
/// @param filePath xml文件路径
+ (GUNode *)nodeWithFilePath:(NSString *)filePath;

/// 通过二进制数据生成节点。二进制数据存在高压缩率和解析快的特点。
/// @param data 二进制数据
+ (GUNode *)nodeWithBinData:(NSData *)data;


/// 节点名
@property (nonatomic, strong) NSString *name;

/// 节点id。可通过xml中`id="xxx"`设置。
@property (nonatomic, strong) NSString *nodeId;

/// 所有子节点
@property (nonatomic, strong) NSArray<GUNode *> *subNodes;

/// 全部属性
@property (nonatomic, strong) NSDictionary *attributes;

/// 节点内容
@property (nonatomic, strong) NSString *content;

/// 节点的file应用节点。可通过xml中`file="filename"`属性将另一个文件包含进来。
@property (nonatomic, strong) GUNode *fileNode;

/// 已加载合并的文件节点
@property (nonatomic, strong) NSString *loadedFileName;

/// 节点内容纯文本
@property (nonatomic, strong, readonly) NSString *text;

/// 加载合并文件节点
- (void)loadFileNode;

/// 根据节点生成一个对象
- (id)generateObject;

/// 根据节点更新一个对象
/// @param rootObj 需要更新的对象
- (void)updateObject:(id)rootObj;

/// 节点对应对象的类型
- (Class)objectClass;

@end
