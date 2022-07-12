//
//  GUNodeBinCoder.m
//  GearUI
//
//  Created by 谌启亮 on 30/03/2018.
//  Copyright © 2018 谌启亮. All rights reserved.
//

#import "GUNodeBinCoder.h"
#import "GULog.h"

#define CODE_LOG NSLog

static NSString *attributeNameCommonValue[] = {
    @"left",
    @"top",
    @"right",
    @"height",
    @"backgroundColor",
    @"font",
    @"textColor",
    @"bottom",
    @"width",
    @"centerY",
    @"centerX",
    @"selectedBackgroundColor",
    @"textAlignment",
    @"hidden",
    @"tap",
    @"numberOfLines",
    @"image",
    @"class",
    @"title",
    @"separatorInset",
    @"cornerRadius",
    @"clipsToBounds",
    @"contentMode",
    @"delaysHighlighting",
    @"separatorColor",
    @"touchEdgeInsets",
    @"titleColor",
    @"op",
    @"backgroundImage",
    @"colors",
    @"startPoint",
    @"locations",
    @"endPoint",
    @"selectionStyle",
    @"highlightedBackgroundImage",
    @"removeRedundantSeparator",
    @"highlightedCoverColor",
    @"separatorStyle",
    @"hidesWhenStopped",
    @"showNavigationBarShadow",
    @"highlightedTitleColor",
    @"animationDuration",
    @"layoutType",
    @"highlightedImage",
    @"disableLayout",
    @"duration",
    @"a",
    @"color",
    @"contentInset",
    @"closeMuiscBarWhenPush",
    @"br",
    @"keyPath",
    @"toValue",
    @"target",
    @"lineSpace",
    @"pageControlId",
    @"borderColor",
    @"borderWidth",
    @"fromValue",
    @"useSafeAreaLayout",
    @"minimumLineSpacing",
    @"extendedLayoutIncludesOpaqueBars",
    @"action",
    @"minimumInteritemSpacing",
    @"timeFunction",
    @"alpha",
    @"imageEdgeInsets",
    @"allowsSelection",
    @"line",
    @"highlightedTextColor",
    @"beginTime",
    @"placeholder",
    @"fillColor",
    @"lineWidth",
    @"fixContentWidth",
    @"autoRun",
    @"rowHeight",
    @"placeholderColor",
    @"footerViewNodeId",
    @"circleColor",
    @"repeatCount",
    @"style",
    @"showsHorizontalScrollIndicator",
    @"headerViewNodeId",
    @"enabled",
    @"selectedImage",
    @"userInteractionEnabled",
    @"alwaysBounceVertical",
    @"icon",
    @"baselineOffset",
    @"scrollEnabled",
    @"fileName",
    @"selected",
    @"autoScroll",
    @"placeholderImage",
    @"hidesNavigationBarWhenPushed",
    @"offsetViewWhenKeyboardShow",
    @"alignLeft",
    @"progress",
    @"adjustsFontSizeToFitWidth",
    @"on",
    @"allowsMultipleSelection",
    @"trackHeight",
    @"estimatedSectionHeaderHeight",
    @"imagePaths",
    @"onTintColor",
    @"lineBreakMode",
    @"autoDeselectCell",
    @"contentEdgeInsets",
    @"numberOfPages",
    @"minimumTrackTintColor",
    @"delay",
    @"showsTouchWhenHighlighted",
    @"navigationBarTintColor",
    @"maximumTrackTintColor",
    @"disabledTitleColor",
    @"effect",
};


static NSString *nodeNameCommonValue[] = {
    @"Label",
    @"LayoutView",
    @"ImageView",
    @"Button",
    @"TableViewCell",
    @"ViewController",
    @"TableView",
    @"GradientView",
    @"CollectionViewCell",
    @"View",
    @"ActivityIndicatorView",
    @"CollectionView",
    @"Animation",
    @"PageControl",
    @"BannerView",
    @"TextField",
    @"TableViewSection",
    @"ScrollView",
    @"CircularProgressView",
    @"Component",
    @"UITableViewCell",
    @"Switch",
    @"PickerView",
    @"Slider",
    @"VideoView",
    @"DatePicker",
    @"Script",
    @"SlideBar",
    @"VisualEffectView",
    @"WebView",
};

typedef NS_ENUM(NSUInteger, GUValueType) {
    GUValueTypeNodeName = 1,
    GUValueTypeAttributeName = 2,
    GUValueTypeAttributeValue = 3,
    GUValueTypeContent = 4,
    GUValueTypeSubNode = 5,
};

typedef struct GUCompressType {
    unsigned char isCompressedAttributeName: 1;
    unsigned char isCompressedNodeName: 1;
    unsigned char reserv: 2;
    unsigned char uncompressValueType: 4;
} GUCompressType;

typedef struct GUCompressAttributNameValue {
    unsigned char isCompressedAttributeName: 1;
    unsigned char value : 7;
} GUCompressAttributNameValue;

typedef struct GUCompressNodeNameValue {
    unsigned char isCompressedAttributeName: 1;
    unsigned char isCompressedNodeName: 1;
    unsigned char value : 6;
} GUCompressNodeNameValue;

typedef union GUCompressValue {
    GUCompressType type;
    GUCompressAttributNameValue atributeNameValue;
    GUCompressNodeNameValue nodeNameValue;
} GUCompressValue;


GUNode *decodeFromBuffer(const unsigned char *buff, long length);

@implementation GUNodeBinCoder

+ (NSDictionary<NSString *, NSNumber *> *)attributeNameValueMap {
    static NSDictionary<NSString *, NSNumber *> *keyValueMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        for (int i = 0; i < sizeof(attributeNameCommonValue)/sizeof(NSString *); i++) {
            dictionary[attributeNameCommonValue[i]] = @(i);
        }
        keyValueMap = [dictionary copy];
    });
    return keyValueMap;
}

+ (NSDictionary<NSString *, NSNumber *> *)nodeNameValueMap {
    static NSDictionary<NSString *, NSNumber *> *keyValueMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        for (int i = 0; i < sizeof(nodeNameCommonValue)/sizeof(NSString *); i++) {
            dictionary[nodeNameCommonValue[i]] = @(i);
        }
        keyValueMap = [dictionary copy];
    });
    return keyValueMap;
}

+ (void)encodeString:(NSString *)string toBuff:(NSMutableData *)buff {
    const char nullChar = 0;
    const char *nodeNameUTF8 = [string UTF8String];
    [buff appendBytes:nodeNameUTF8 length:strlen(nodeNameUTF8)];
    [buff appendBytes:&nullChar length:1];
}

+ (NSData *)encodeWithNode:(GUNode *)node {
    const unsigned char nullChar = 0xFC;
    NSMutableData *data = [NSMutableData dataWithBytes:&nullChar length:1];
    NSData *result = [self gu_encodeWithNode:node level:@"[0]"];
    [data appendData:result];
    return [data copy];
}

+ (GUNode *)decodeWithData:(NSData *)data {
    if ([data length] > 2) {
        const unsigned char *buff = [data bytes];
        if (*buff == 0xFC) {
            GUNode *result = decodeFromBuffer(buff+1, [data length]-1);
            return result;
        }
    }
    return nil;
}

+ (NSData *)gu_encodeWithNode:(GUNode *)node level:(NSString *)level {
    
    NSMutableData *buff = [NSMutableData data];
    
    //encode name
    NSString *nodeName = node.name;
    if ([nodeName length] > 0) {
        NSNumber *indexObj = [self nodeNameValueMap][nodeName];
        if (indexObj != nil) {
            int index = [indexObj intValue];
            GUCompressValue value = {0};
            value.type.isCompressedNodeName = 1;
            value.nodeNameValue.value = index;
            [buff appendBytes:&value length:sizeof(value)];
            //CODE_LOG(@"[%@][%@]encode nameTypeValue at %d", level, nodeName, (int)buff.length);
        }
        else {
            GUCompressValue value = {0};
            value.type.uncompressValueType = GUValueTypeNodeName;
            [buff appendBytes:&value length:sizeof(value)];
            //CODE_LOG(@"[%@][%@]encode nameType at %d", level, nodeName, (int)buff.length);
            [self encodeString:nodeName toBuff:buff];
        }
    }
    
    //encode attribute
    NSMutableDictionary *encodedAttributes = [node.attributes mutableCopy];
    if (node.nodeId) {
        encodedAttributes[@"nodeId"] = node.nodeId;
    }
    for (NSString *attributeKey in encodedAttributes.allKeys) {
        NSString *attributeValue = encodedAttributes[attributeKey];
        NSNumber *indexObj = [self attributeNameValueMap][attributeKey];
        if (indexObj != nil) {
            int index = [indexObj intValue];
            GUCompressValue value = {0};
            value.type.isCompressedAttributeName = 1;
            value.atributeNameValue.value = index;
            [buff appendBytes:&value length:sizeof(value)];
            //CODE_LOG(@"[%@][%@]encode atributeNameTypeValue at %d", level, nodeName, (int)buff.length);
        }
        else {
            GUCompressValue value = {0};
            value.type.uncompressValueType = GUValueTypeAttributeName;
            [buff appendBytes:&value length:sizeof(value)];
            //CODE_LOG(@"[%@][%@]encode atributeNameType at %d", level, nodeName, (int)buff.length);
            [self encodeString:attributeKey toBuff:buff];
        }
        GUCompressValue value = {0};
        value.type.uncompressValueType = GUValueTypeAttributeValue;
        [buff appendBytes:&value length:sizeof(value)];
        //CODE_LOG(@"[%@][%@]encode atributeValueType at %d", level, nodeName, (int)buff.length);
        [self encodeString:attributeValue toBuff:buff];
    }
    
    //encode content
    NSString *content = node.content;
    if ([content length] > 0) {
        GUCompressValue value = {0};
        value.type.uncompressValueType = GUValueTypeContent;
        [buff appendBytes:&value length:sizeof(value)];
        //CODE_LOG(@"[%@][%@]encode contentType at %d", level, nodeName, (int)buff.length);
        [self encodeString:content toBuff:buff];
    }
    
    //encode subnode
    NSArray<GUNode *> *subNodes = node.subNodes;
    for (int i = 0; i < [subNodes count]; i++) {
        GUNode *subNode = subNodes[i];
        GUCompressValue value = {0};
        value.type.uncompressValueType = GUValueTypeSubNode;
        [buff appendBytes:&value length:sizeof(value)];
        //CODE_LOG(@"[%@][%@]encode subnodeType at %d", level, nodeName, (int)buff.length);
        NSData *data = [self gu_encodeWithNode:subNode level:[level stringByAppendingFormat:@"[%d]", i]];
        NSUInteger len = [data length];
        while (len != 0) {
            unsigned char component = len & 0x7F;
            if ((len >> 7) != 0) {
                component = component | 0x80;
            }
            [buff appendBytes:&component length:1];
            len = len >> 7;
        }
        [buff appendData:data];
    }
    
    return buff;
}

@end

NSString *decodeStringFromBuffer(const unsigned char *buff, long length, long *location) {
    buff += *location;
    const unsigned char *to = memmem(buff, length-*location, "\0", 1);
    if (to != NULL) {
        long len = to - buff;
        NSString *result = [[NSString alloc] initWithBytes:buff length:len encoding:NSUTF8StringEncoding];
        *location += (len+1);
        return result;
    }
    return @"";
}

GUNode *decodeFromBuffer(const unsigned char *buff, long length) {
    long cursor = 0;
    GUNode *node = [GUNode new];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSMutableArray *subNodes = [NSMutableArray array];
    while (cursor < length) {
        GUCompressValue value = *(GUCompressValue *)(buff+cursor);
        cursor += sizeof(value);
        
        NSString *attributeName = nil;
        
        if (value.type.isCompressedAttributeName) {
            int index = value.atributeNameValue.value;
            if (index < sizeof(attributeNameCommonValue)/sizeof(NSString *)) {
                attributeName = attributeNameCommonValue[index];
            }
        }
        else if (value.type.isCompressedNodeName) {
            int index = value.nodeNameValue.value;
            if (index < sizeof(nodeNameCommonValue)/sizeof(NSString *)) {
                node.name = nodeNameCommonValue[index];
                continue;
            }
        }
        else if (value.type.uncompressValueType == GUValueTypeNodeName) {
            node.name = decodeStringFromBuffer(buff, length, &cursor);
            continue;
        }
        else if (value.type.uncompressValueType == GUValueTypeAttributeName) {
            attributeName = decodeStringFromBuffer(buff, length, &cursor);
        }
        else if (value.type.uncompressValueType == GUValueTypeContent) {
            node.content = decodeStringFromBuffer(buff, length, &cursor);
            continue;
        }
        else if (value.type.uncompressValueType == GUValueTypeSubNode) {
            long nodeDataLength = 0;
            unsigned char c = *(buff+cursor);
            cursor += sizeof(c);
            nodeDataLength = (c & 0x7F);
            int shiftbit = 0;
            while (c & 0x80) {
                shiftbit += 7;
                c = *(buff+cursor);
                cursor += sizeof(c);
                nodeDataLength += ((c & 0x7F) << shiftbit);
            }
            [subNodes addObject:decodeFromBuffer(buff+cursor, nodeDataLength)];
            cursor += nodeDataLength;
            continue;
        }
        else {
            GUError(@"format error");
        }
        
        if (attributeName) {
            GUCompressValue value = *(GUCompressValue *)(buff+cursor);
            cursor += sizeof(value);
            if (value.type.uncompressValueType == GUValueTypeAttributeValue) {
                NSString *attributeValue = decodeStringFromBuffer(buff, length, &cursor);
                if (attributeValue) {
                    attributes[attributeName] = attributeValue;
                }
            }
        }
        
    }
    if (attributes[@"nodeId"]) {
        node.nodeId = attributes[@"nodeId"];
        [attributes removeObjectForKey:@"nodeId"];
    }
    node.attributes = [attributes copy];
    node.subNodes = [subNodes copy];
    return node;
}
