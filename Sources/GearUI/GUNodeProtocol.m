//
//  GUNode.m
//  GearUI
//
//  Created by 谌启亮 on 16/4/15.
//  Copyright © 2016年 谌启亮. All rights reserved.
//

#import "GUNodeProtocol.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "NSString+GUValue.h"
#import "NSObject+GUPrivate.h"
#import "GUDefines.h"

@implementation NSObject (GUNode)

SYNTHESIZE_CATEGORY_OBJ_PROPERTY(nodeId, setNodeId:)
SYNTHESIZE_CATEGORY_OBJ_PROPERTY(subnodes, __setSubnodes:)

- (void)setSubnodes:(NSArray<id<GUNodeProtocol>> *)subnodes{
    [self __setSubnodes:subnodes];
}

- (id<GUNodeProtocol>)subnodeWithId:(NSString *)nodeId {
    return nil;
}

- (void)setAttribute:(NSString *)attribute forKeyPath:(NSString *)keyPath{
    NSArray *keyPaths = [keyPath componentsSeparatedByString:@"."];
    if ([keyPaths count] > 1) {
        NSMutableArray *viewPaths = [keyPaths mutableCopy];
        [viewPaths removeLastObject];
        id<GUNodeProtocol> subnode = [self subnodeWithId:viewPaths.firstObject];
        while ([viewPaths count] >= 2) {
            [viewPaths removeObjectAtIndex:0];
            subnode = [subnode subnodeWithId:viewPaths.firstObject];
        }
        if ([subnode respondsToSelector:@selector(setAttribute:forKeyPath:)]) {
            [subnode setAttribute:attribute forKeyPath:keyPaths.lastObject];
        }
    }
    else if ([keyPaths count] == 1) {
        [self gu_setAttributeValue:attribute forName:keyPath];
    }
}

- (void)setKeyPathAttributes:(NSDictionary<NSString *, id> *)attributes{
    if ([attributes isKindOfClass:[NSDictionary class]]) {
        for (NSString *key in attributes) {
            [self setAttribute:attributes[key] forKeyPath:key];
        }
    }
}

@end
