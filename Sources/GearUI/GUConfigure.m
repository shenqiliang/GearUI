//
//  GUConfigure.m
//  GearUI
//
//  Created by 谌启亮 on 16/4/14.
//  Copyright © 2016年 谌启亮. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "GUConfigure.h"
#import "GUDebugClient.h"
#import <objc/runtime.h>

@interface GUConfigure ()
{
    NSDictionary *_nodeNameClassMap;
    NSDictionary *_nodeNameAttributesMap;
    NSMutableDictionary *_classEnumNameAndValueMap;
}

@end

@implementation GUConfigure

+ (instancetype)sharedInstance{
    static GUConfigure *g_GUConfigure = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_GUConfigure = [GUConfigure new];
    });
    return g_GUConfigure;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _nodeNameClassMap = @{@"View":[UIView class]};
        _nodeNameAttributesMap = @{};
        _classEnumNameAndValueMap = [NSMutableDictionary dictionary];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide) name:UIKeyboardDidHideNotification object:nil];
        
        
        [self setEnumeRepresentation:@{@"topLeft":@(kCALayerMinXMinYCorner),
                                       @"topRight":@(kCALayerMaxXMinYCorner),
                                       @"bottomLeft":@(kCALayerMinXMaxYCorner),
                                       @"bottomRight":@(kCALayerMaxXMaxYCorner),
                                       @"top":@(kCALayerMinXMinYCorner|kCALayerMaxXMinYCorner),
                                       @"bottom":@(kCALayerMinXMaxYCorner|kCALayerMaxXMaxYCorner),
                                       @"left":@(kCALayerMinXMinYCorner|kCALayerMinXMaxYCorner),
                                       @"right":@(kCALayerMaxXMinYCorner|kCALayerMaxXMaxYCorner)
                                       
        } forPropertyName:@"maskedCorners" ofClass:[UIView class]];
        

        [self setEnumeRepresentation:@{
            @"left":@(UIControlContentHorizontalAlignmentLeft),
            @"right":@(UIControlContentHorizontalAlignmentRight)
        } forPropertyName:@"contentHorizontalAlignment" ofClass:[UIControl class]];
        
    }
    
    return self;
}

- (void)registerNodeName:(NSString *)nodeName forClass:(Class)cls {
    if([nodeName length] == 0 || cls == nil) {
        return;
    }
    NSMutableDictionary *tmp = [_nodeNameClassMap mutableCopy];
    tmp[nodeName] = cls;
    _nodeNameClassMap = [tmp copy];
}

- (void)keyboardDidShow{
    _keyboardVisible = YES;
}

- (void)keyboardDidHide{
    _keyboardVisible = NO;
}


- (Class)classOfNodeName:(NSString *)nodeName{
    if ([nodeName length] == 0) {
        return nil;
    }
    Class result = _nodeNameClassMap[nodeName];
    if (result) {
        return result;
    }
//    if ([nodeName isEqualToString:@"CollectionViewCell"]) {
//        return nil;
//    }
    result = NSClassFromString([NSString stringWithFormat:@"GU%@", nodeName]);
    if(result) {
        return result;
    }
    result = NSClassFromString([NSString stringWithFormat:@"UI%@", nodeName]);
    return result;
}

- (BOOL)enableRuntimeDebug {
    [[GUDebugClient client] start];
    _isEnableRuntimeDebug = YES;
    return YES;
}

- (NSDictionary *)defaultAttributesForNodeName:(NSString *)nodeName {
    return _nodeNameAttributesMap[nodeName];
}

- (void)setDefaultAttributes:(NSDictionary *)attibutes forNodeName:(NSString *)nodeName {
    if (nodeName == nil || ![attibutes isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSMutableDictionary *map = [_nodeNameAttributesMap mutableCopy];
    NSMutableDictionary *savedAttributes = [map[nodeName] mutableCopy] ?: [NSMutableDictionary dictionary];
    [savedAttributes addEntriesFromDictionary:attibutes];
    map[nodeName] = [savedAttributes copy];
    _nodeNameAttributesMap = [map copy];
}

- (void)setEnumeRepresentation:(NSDictionary<NSString *, NSNumber *> *)enumNameAndValues forPropertyName:(NSString *)property ofClass:(Class)cls;{
    _classEnumNameAndValueMap[[NSString stringWithFormat:@"%@.%@", cls, property]] = enumNameAndValues;
}

- (NSNumber *)enumValueForRepresentation:(NSString *)enumRepresentation forPropertyName:(NSString *)property ofClass:(Class)cls {
    NSDictionary *enumNameAndValues = nil;
    while (enumNameAndValues == nil && cls != nil) {
        enumNameAndValues = _classEnumNameAndValueMap[[NSString stringWithFormat:@"%@.%@", cls, property]];
        cls = class_getSuperclass(cls);
    }
    if (enumNameAndValues != nil) {
        NSInteger option = 0;
        for (NSString *enumItem in [enumRepresentation componentsSeparatedByString:@"|"]) {
            option |= [enumNameAndValues[enumItem] integerValue];
        }
        return @(option);
    }
    else {
        return nil;
    }
}

@end
