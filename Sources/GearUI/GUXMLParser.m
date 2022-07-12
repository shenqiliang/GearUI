//
//  GUXMLParser.m
//  GearUI
//
//  Created by 谌启亮 on 16/4/14.
//  Copyright © 2016年 谌启亮. All rights reserved.
//

#import "GUXMLParser.h"
#include <stdio.h>
#include <libxml/parser.h>
#include <libxml/tree.h>
#import "GULog.h"

void GUXMLParserError(void *ctx, const char *msg, ...) {
    va_list arg_ptr;
    va_start(arg_ptr, msg);
    NSString *message = [[NSString alloc] initWithFormat:[NSString stringWithUTF8String:msg] arguments:arg_ptr];
    va_end(arg_ptr);
    
    NSMutableString *errorDescription = (__bridge NSMutableString *)ctx;
    [errorDescription appendString:message];
    return;
}


@implementation GUXMLParser

- (instancetype)initWithRootNode:(GUNode *)rootNode{
    self = [super init];
    if (self) {
        _rootNode = rootNode;
    }
    return self;
}

- (void)parserForXMLString:(NSString *)xmlString{
    if ([xmlString length] == 0) {
        GUError(@"XML is empty");
        return;
    }
    NSMutableString *errorDescription = [NSMutableString new];
    xmlSetGenericErrorFunc((__bridge void *)(errorDescription), GUXMLParserError);
    xmlDocPtr doc = xmlReadMemory([xmlString UTF8String], (int)[xmlString lengthOfBytesUsingEncoding:NSUTF8StringEncoding], NULL, "utf-8", XML_PARSE_NOBLANKS);
    if (doc == NULL) {
        xmlErrorPtr err = xmlGetLastError();
        if (err != NULL) {
            GUFail(@"Failed to parse XML: %s \n%@", err->message, errorDescription);
        }
        return;
    }
    xmlNodePtr rootNode = xmlDocGetRootElement(doc);
    if (rootNode) {
        _rootNode = [self parserXMLNode:rootNode rootNode:_rootNode];
    }
    
    xmlFreeDoc(doc);
}

- (void)parserForXMLFile:(NSString *)filePath{
    NSString *xmlString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    if (xmlString) {
        [self parserForXMLString:xmlString];
    }
}

- (instancetype)initWithXMLFile:(NSString *)filePath {
    NSString *xmlString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    return [self initWithXMLString:xmlString];
}

- (instancetype)initWithXMLString:(NSString *)xmlString
{
    self = [self initWithRootNode:nil];
    [self parserForXMLString:xmlString];
    return self;
}

- (GUNode *)parserXMLNode:(xmlNodePtr)xmlNode rootNode:(GUNode *)rootNode{
    if (xmlNode->type == XML_COMMENT_NODE) {
        return nil;
    }
    if (rootNode == nil) {
        rootNode = [GUNode new];
    }
    if (xmlNode->type == XML_TEXT_NODE || xmlNode->type == XML_CDATA_SECTION_NODE) {
        rootNode.content = [NSString stringWithUTF8String:(const char*)xmlNode->content];
        if ([[rootNode.content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
            return nil;
        }
    }
    else{
        if (xmlNode->name) {
            rootNode.name = [NSString stringWithUTF8String:(const char*)xmlNode->name];
        }
        xmlAttrPtr attribute = xmlNode->properties;
        NSMutableDictionary *attributes = [NSMutableDictionary new];
        NSMutableArray *subNodes = [NSMutableArray array];
        for (; attribute; attribute = attribute->next) {
            NSString *attributeName = [NSString stringWithUTF8String:(const char*)attribute->name];
            NSString *attributeValue = [NSString stringWithUTF8String: (const char*)attribute->children->content];
            if ([attributeName isEqualToString:@"id"]) {
                rootNode.nodeId = attributeValue;
            }
            else{
                attributes[attributeName] = attributeValue;
            }
        }
        
        xmlNodePtr subnode = xmlNode->children;
        for (; subnode; subnode = subnode->next) {
            GUNode *node = [self parserXMLNode:subnode rootNode:nil];
            if (node) {
                [subNodes addObject:node];
            }
        }
        
        rootNode.subNodes = [subNodes copy];
        rootNode.attributes = attributes;
    }
    return rootNode;
}

@end
