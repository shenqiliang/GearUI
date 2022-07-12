//
//  GUNode.m
//  GearUI
//
//  Created by 谌启亮 on 01/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUNode.h"
#import "GULog.h"
#import "GUNodeProtocol.h"
#import "GUConfigure.h"
#import "NSObject+GUPrivate.h"
#import "GUXMLParser.h"
#import "GUDebugClient.h"
#import "GUConfigure+Private.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonCrypto.h>

// 使用patchPath时是否加载不安全的布局文件（gbi,xml）
#define USE_UNSAFE_PATCH 1

NSString *GUNodeEscapeXML(NSString *content){
    content = [content stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
    content = [content stringByReplacingOccurrencesOfString:@"'" withString:@"&apos;"];
    content = [content stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    content = [content stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    content = [content stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    return content;
}

//static inline NSData *SHA1(NSData *inData){
//    unsigned char sha1[CC_SHA1_DIGEST_LENGTH] = {0};
//    CC_SHA1([inData bytes], (CC_LONG)[inData length], sha1);
//    return [NSData dataWithBytes:sha1 length:CC_SHA1_DIGEST_LENGTH];
//}

static NSCache *_nodesCache;

@implementation GUNode

+ (void)initialize {
    _nodesCache = [NSCache new];
    _nodesCache.totalCostLimit = 100;
}

+ (GUNode *)_loadNodeWithFileName:(NSString *)fileName {
    NSString *externPath = [GUConfigure sharedInstance].patchPath;
    if ([externPath length] > 0) {
//        NSString *gbxPath = [externPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.gbx", fileName]];
//        if ([[NSFileManager defaultManager] fileExistsAtPath:gbxPath]) {
//            NSData *gbxData = [NSData dataWithContentsOfFile:gbxPath];
//            NSData *sign = [gbxData subdataWithRange:NSMakeRange(0, 128)];
//            NSData *gbiData = [gbxData subdataWithRange:NSMakeRange(128, gbxData.length-128)];
//            static SecKeyRef pubkey = nil;
//            static dispatch_once_t onceToken;
//            dispatch_once(&onceToken, ^{
//                /// 签名Public Key
//                NSData *data = [[NSData alloc] initWithBase64EncodedString:
//                                @"MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDVOaft9Yljw8pCOP8Rpi9NmB8J"
//                                "23dChHS9fzsZr+LHwWcWg8o+mSs6dZbmE12aw59DWj0k8NM35fLVN+xIJtJJznIn"
//                                "jW29Sj49UCdlszeFM3apPydPRemBQ4IqW57Ca5qKuspw0b9MHphGjerLOboaFD0u"
//                                "uhCfyqgLmTKnOk5OjQIDAQAB" options:0];
//                NSDictionary *keyAttributes = @{(id)kSecAttrKeyType:(id)kSecAttrKeyTypeRSA,(id)kSecAttrKeyClass:(id)kSecAttrKeyClassPublic};
//                CFErrorRef error = nil;
//                pubkey = SecKeyCreateWithData((CFDataRef)data, (CFDictionaryRef)keyAttributes, &error);
//            });
//            if (pubkey != nil) {
//                CFErrorRef error = nil;
//                NSData *signedData = SHA1(gbiData);
//                Boolean ret = SecKeyVerifySignature(pubkey, kSecKeyAlgorithmRSASignatureDigestPKCS1v15Raw, (CFDataRef)signedData, (CFDataRef)sign, &error);
//                if (ret) {
//                    return [GUNodeBinCoder decodeWithData:gbiData];
//                }
//            }
//        }
#if USE_UNSAFE_PATCH
        NSString *gbiPath = [externPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.gbi", fileName]];
        if (([[NSFileManager defaultManager] fileExistsAtPath:gbiPath])) {
            return [GUNodeBinCoder decodeWithData:[NSData dataWithContentsOfFile:gbiPath]];
        }
        NSString *xmlPath = [externPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xml", fileName]];
        if (([[NSFileManager defaultManager] fileExistsAtPath:xmlPath])) {
            GUXMLParser *parser = [[GUXMLParser alloc] initWithRootNode:nil];
            [parser parserForXMLFile:xmlPath];
            return parser.rootNode;
        }
#endif
    }
    
    NSString *gbiPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"gbi"];
    if (gbiPath != nil) {
        return [GUNodeBinCoder decodeWithData:[NSData dataWithContentsOfFile:gbiPath]];
    }
    else {
        GUXMLParser *parser = [[GUXMLParser alloc] initWithRootNode:nil];
        [parser parserForXMLFile:[[NSBundle mainBundle] pathForResource:fileName ofType:@"xml"]];
        return parser.rootNode;
    }
    return nil;
}

+ (GUNode *)nodeWithFileName:(NSString *)fileName{
    NSString *cacheXML = [[GUDebugClient client] cachedDataForFileName:fileName];
    if (cacheXML) {
        GUXMLParser *parser = [[GUXMLParser alloc] initWithRootNode:nil];
        [parser parserForXMLString:cacheXML];
        return [parser.rootNode _expandFileNode];
    }
    else {
        GUNode *node = [_nodesCache objectForKey:fileName];
        if (node != nil && node != (id)[NSNull null]) {
            return [[node copy] _expandFileNode];
        }
        node = [self _loadNodeWithFileName:fileName];
        if (node) {
            [_nodesCache setObject:node forKey:fileName cost:1];
            return [[node copy] _expandFileNode];
        }
        else {
            [_nodesCache setObject:[NSNull null] forKey:fileName cost:1];
        }
    }
    return nil;
}

+ (GUNode *)nodeWithXMLString:(NSString *)xmlString
{
    GUXMLParser *parser = [[GUXMLParser alloc] initWithRootNode:nil];
    [parser parserForXMLString:xmlString];
    return [parser.rootNode _expandFileNode];
}

+ (GUNode *)nodeWithFilePath:(NSString *)filePath {
    if ([filePath.pathExtension isEqualToString:@"xml"]) {
        GUXMLParser *parser = [[GUXMLParser alloc] initWithRootNode:nil];
        [parser parserForXMLFile:filePath];
        return [parser.rootNode _expandFileNode];
    }
    else {
        return [[GUNodeBinCoder decodeWithData:[NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:NULL]] _expandFileNode];
    }
}

+ (GUNode *)nodeWithBinData:(NSData *)data {
    return [GUNodeBinCoder decodeWithData:data];
}

- (GUNode *)_expandFileNode {
    [self loadFileNode];
    for (GUNode *subNode in self.subNodes) {
        [subNode _expandFileNode];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    GUNode *newNode = [[self class] allocWithZone:zone];
    newNode.nodeId = _nodeId;
    newNode.name = _name;
    NSMutableArray *subNodes = [NSMutableArray array];
    for (GUNode *subNode in _subNodes) {
        [subNodes addObject:[subNode copyWithZone:zone]];
    }
    newNode.subNodes = [subNodes copy];
    newNode.attributes = [_attributes copy];
    newNode.content = _content;
    return newNode;
}

- (id)generateObject{
    return [self generateObjectFromRoot:nil];
}

- (void)updateObject:(id)rootObj{
    [self generateObjectFromRoot:rootObj];
}

- (void)loadFileNode {
    if (_fileNode != nil) {
        return;
    }
    NSString *loadedFileName = nil;
    if (_attributes[@"file"] != nil && _fileNode == nil) {
        loadedFileName = _attributes[@"file"];
        _fileNode = [GUNode nodeWithFileName:loadedFileName];
    }
    if (_attributes[@"file"] == nil && _attributes[@"class"] != nil && _fileNode == nil) {
        loadedFileName = _attributes[@"class"];
        _fileNode = [GUNode nodeWithFileName:loadedFileName];
    }
    if (_fileNode) {
        [_fileNode loadFileNode];
        if ([_fileNode.attributes count] > 0) {
            NSMutableDictionary *resultAttribtues = [NSMutableDictionary dictionaryWithDictionary:_fileNode.attributes];
            [resultAttribtues addEntriesFromDictionary:_attributes];
            _attributes = [resultAttribtues copy];
        }
        if ([_fileNode.subNodes count] > 0) {
            NSMutableArray *resultSubNodes = [NSMutableArray arrayWithArray:_fileNode.subNodes];
            [resultSubNodes addObjectsFromArray:_subNodes];
            _subNodes = [resultSubNodes copy];
        }
        if (_nodeId == nil) {
            _nodeId = _fileNode.nodeId;
        }
        if (_content == nil) {
            _content = _fileNode.content;
        }
        self.loadedFileName = loadedFileName;
    }
}

- (id)generateObjectFromRoot:(id)rootObj {
    NSMapTable *attributesMap = [NSMapTable strongToStrongObjectsMapTable];
    id<GUNodeProtocol> obj = [self generateObjectFromRoot:rootObj attributesMap:attributesMap];
    for (NSObject<GUNodeProtocol> *obj in attributesMap.keyEnumerator) {
        NSDictionary *attributes = [attributesMap objectForKey:obj];
        [obj gu_setAttributeValues:attributes];
    }
    for (NSObject<GUNodeProtocol> *obj in attributesMap.keyEnumerator) {
        if ([obj respondsToSelector:@selector(didUpdateAttributes)]) {
            [obj didUpdateAttributes];
        }
    }
    return obj;
}

- (BOOL)isEqual:(GUNode *)object {
    if ([object isKindOfClass:[GUNode class]]) {
        BOOL ret = (object.nodeId == _nodeId || [object.nodeId isEqual:_nodeId]) && (object.name == _name || [object.name isEqual:_name]) && (object.content == _content || [object.content isEqual:_content]) && ([object.attributes isEqual:_attributes] || ([object.attributes count] == 0 && [_attributes count] == 0)) && ([object.subNodes isEqualToArray:_subNodes] || ([object.subNodes count] == 0 && [_subNodes count] == 0));
        return ret;
    }
    return NO;
}

- (Class)objectClass {
    Class class = nil;
    Class nodeClass = [[GUConfigure sharedInstance] classOfNodeName:self.name];
    NSString *className = _attributes[@"class"];
    if (className) {
        class = NSClassFromString(className);
        if (class == nil) {
            NSString *classNameSwift = [NSString stringWithFormat:@"%@.%@", [[NSBundle mainBundle] infoDictionary][@"CFBundleName"], className];
            class = NSClassFromString(classNameSwift);
        }
        if (class == nil) {
            GUFail(@"Custom Class %@ not found", className);
            return nil;
        }
        if (![class isSubclassOfClass:nodeClass]) {
            GUFail(@"Custom class %@ of node %@ is not subclass of %@", className, self.name, nodeClass);
            return nil;
        }
    }
    else{
        class = nodeClass;
        if (class == nil) {
            return nil;
        }
    }
    return class;
}

- (id<GUNodeProtocol>)generateObjectFromRoot:(id<GUNodeProtocol>)rootObj attributesMap:(NSMapTable *)attributesMap {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSDictionary *defaultAttributes = [[GUConfigure sharedInstance] defaultAttributesForNodeName:self.name];
    [attributes addEntriesFromDictionary:defaultAttributes];
    [attributes addEntriesFromDictionary:_attributes];
    [attributes removeObjectForKey:@"file"];
    if (rootObj == nil) {
        Class class = [self objectClass];
        if (class == nil) {
            return (id)self;
        }
        if ([class respondsToSelector:@selector(initializedAttributeKeys)] && [class respondsToSelector:@selector(newObjectWithAttributes:)]) {
            NSMutableDictionary *initAttributes = [NSMutableDictionary new];
            for (NSString *key in [class initializedAttributeKeys]) {
                NSString *value = attributes[key];
                if (value) {
                    initAttributes[key] = value;
                    [attributes removeObjectForKey:key];
                }
            }
            rootObj = [class newObjectWithAttributes:initAttributes];
        }
        else {
            rootObj = [class new];
        }
    }
    [attributes removeObjectForKey:@"class"];
    NSString *nodeId = self.nodeId;
    if (nodeId) {
        rootObj.nodeId = nodeId;
    }
    
    NSMutableDictionary *delayedUpdateAttribute = [NSMutableDictionary new];
    
    NSMutableArray *delayedUpdateAttributeNames = [[(id)rootObj gu_delayedUpdateAttributeNames] mutableCopy];
    if ([rootObj respondsToSelector:@selector(delayedUpdateAttributeNames)]) {
        [delayedUpdateAttributeNames addObjectsFromArray:[rootObj delayedUpdateAttributeNames]];
    }
    for (NSString *attributeName in delayedUpdateAttributeNames) {
        if (attributes[attributeName]) {
            delayedUpdateAttribute[attributeName] = attributes[attributeName];
            [attributes removeObjectForKey:attributeName];
        }
    }
    [(NSObject *)rootObj gu_setAttributeValues:attributes];
    NSDictionary *remainAttributes = [delayedUpdateAttribute copy];

    NSArray<GUNode *> *subNodes = _subNodes;
    if ([rootObj respondsToSelector:@selector(updateSubnodes:)]) {
        subNodes = [rootObj updateSubnodes:subNodes];
    }

    NSMutableArray *array = [NSMutableArray array];
    for (GUNode *subNode in subNodes) {
        id<GUNodeProtocol> childNode = [subNode generateObjectFromRoot:nil attributesMap:attributesMap];
        if (childNode != nil) {
            [array addObject:childNode];
        }
    }
    if ([rootObj respondsToSelector:@selector(updateChildren:)]) {
        [rootObj updateChildren:array];
    }

    [attributesMap setObject:remainAttributes forKey:rootObj];
    if ([rootObj respondsToSelector:@selector(didLoadFromNode:)]) {
        [rootObj didLoadFromNode:self];
    }
    return rootObj;
}

- (NSString *)text{
    NSMutableString *string = [NSMutableString string];
    if (self.content) {
        [string appendString:self.content];
    }
    for (GUNode *node in _subNodes) {
        if ([node isKindOfClass:[GUNode class]]) {
            [string appendString:[node text]];
        }
    }
    return string;
}



@end


