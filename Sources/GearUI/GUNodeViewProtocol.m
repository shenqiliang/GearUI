//
//  GULabel.m
//  GearUI
//
//  Created by 谌启亮 on 30/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUNodeViewProtocol.h"
#import "NSObject+GUPrivate.h"
#import "UIView+GUPrivate.h"

@implementation UIView (GUNodeView)

- (UIView<GUNodeViewProtocol> *)subviewWithNodeId:(NSString *)nodeId {
    for (UIView<GUNodeViewProtocol> *subView in self.subviews) {
        if ([subView.nodeId isEqualToString:nodeId]) {
            return subView;
        }
    }
    return nil;
}

- (UIView<GUNodeViewProtocol> *)viewWithNodeId:(NSString *)nodeId {
    if ([self.nodeId isEqualToString:nodeId]) {
        return (id)self;
    }
    UIView<GUNodeViewProtocol> *view = (UIView<GUNodeViewProtocol> *)[self subnodeWithId:nodeId];
    if ([view isKindOfClass:[UIView class]]) {
        return view;
    }
    else {
        return nil;
    }
}

//- (void)setKeyPathAttributes:(NSDictionary *)keyPathAttributes {
//    [keyPathAttributes enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
//        [self setAttribute:obj forKeyPath:key];
//    }];
//}

- (id<GUNodeProtocol>)subnodeWithId:(NSString *)nodeId {
    if ([nodeId length] == 0) {
        return nil;
    }
    UIView<GUNodeViewProtocol> *view = [self subviewWithNodeId:nodeId];
    if (view != nil) {
        return view;
    }
    for (id subView in self.subviews) {
        id<GUNodeProtocol> view = [subView subnodeWithId:nodeId];
        if (view != nil) {
            return view;
        }
    }
    return nil;
}

//- (void)setAttribute:(id)attribute forKeyPath:(NSString *)keyPath {
//    NSArray *keyPaths = [keyPath componentsSeparatedByString:@"."];
//    if ([keyPaths count] > 1) {
//        NSMutableArray *viewPaths = [keyPaths mutableCopy];
//        [viewPaths removeLastObject];
//        id<GUNodeProtocol> view = [self viewWithNodeId:viewPaths.firstObject];
//        while ([viewPaths count] >= 2) {
//            [viewPaths removeObjectAtIndex:0];
//            view = [view viewWithNodeId:viewPaths.firstObject];
//        }
//        if ([view respondsToSelector:@selector(setAttribute:forKeyPath:)]) {
//            [view setAttribute:attribute forKeyPath:keyPaths.lastObject];
//        }
//    }
//    else if ([keyPaths count] == 1) {
//        [self gu_setAttributeValue:attribute forName:keyPath];
//    }
//}


@end
