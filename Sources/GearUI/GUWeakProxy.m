//
//  GUWeakProxy.m
//  GearUI
//
//  Created by 谌启亮 on 26/12/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUWeakProxy.h"

@implementation GUWeakProxy {
    __weak id _target;
}

+ (instancetype)proxyWithObject:(id)obj {
    return [[GUWeakProxy alloc] initWithObject:obj];
}

- (id)initWithObject:(id)object {
    _target = object;
    return self;
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [_target methodSignatureForSelector:selector];
}
- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:_target];
}


@end
