//
//  GUDataBindingObserver.m
//  GearUI
//
//  Created by 谌启亮 on 2022/4/1.
//

#import "GUDataBindingObserver.h"
#import "GULayoutView.h"
#import <objc/runtime.h>

static const char *kGUDataBindingObservers = "kGUDataBindingObservers";
static NSMutableSet *GUHookedObserveClasses = nil;

@implementation GUDataBindingObserver {
    __weak GULayoutView *_layoutView;
    __unsafe_unretained NSObject *_obj;
    id(^_map)(id);
    BOOL _isRemoved;
}

+ (void)initialize {
    if (self == [GUDataBindingObserver self]) {
        GUHookedObserveClasses = [NSMutableSet new];
    }
}

- (instancetype)initWithLayoutView:(GULayoutView *)layoutView keyPath:(NSString *)keyPath object:(NSObject *)obj objectKeyPath:(NSString *)objectKeyPath map:(nullable id (^)(__nullable id value))map {
    self = [super init];
    if (self) {
        _layoutView = layoutView;
        _keyPath = keyPath;
        _obj = obj;
        _objectKeyPath = objectKeyPath;
        _map = map;
        id value = [_obj valueForKeyPath:_objectKeyPath];
        if (_map != nil) {
            value = _map(value);
        }
        [_layoutView setAttribute:value forKeyPath:_keyPath];
        [_obj addObserver:self forKeyPath:_objectKeyPath options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(self)];
        
        NSMutableArray *bindingObservers = objc_getAssociatedObject(obj, &kGUDataBindingObservers);
        if (![bindingObservers isKindOfClass:[NSMutableArray class]]) {
            bindingObservers = [NSMutableArray new];
            objc_setAssociatedObject(obj, &kGUDataBindingObservers, bindingObservers, OBJC_ASSOCIATION_RETAIN);
        }
        [bindingObservers addObject:self];
        
        [self hookDealloc:[_obj class]];

    }
    return self;
}

- (void)invalidate {
    if (!_isRemoved) {
        [_obj removeObserver:self forKeyPath:_objectKeyPath context:(__bridge void * _Nullable)(self)];
        _isRemoved = YES;
    }
}

// hook监听对象dealloc，防止kvo crash
- (void)hookDealloc:(Class)cls {
    if ([GUHookedObserveClasses containsObject:cls]) {
        return;
    }
    __block IMP orignImp = NULL;
    SEL deallocSel = NSSelectorFromString(@"dealloc");
    Method dellocMethod = class_getInstanceMethod(cls, deallocSel);
    void (^deallocBlock)(id obj) = ^void(__unsafe_unretained id obj) {
        NSMutableArray *bindingObservers = objc_getAssociatedObject(obj, &kGUDataBindingObservers);
        [bindingObservers makeObjectsPerformSelector:@selector(invalidate)];
        if (orignImp != NULL) {
            ((void (*)(id,SEL))orignImp)(obj, deallocSel);
        }
    };
    IMP deallocImp = imp_implementationWithBlock(deallocBlock);
    orignImp = class_replaceMethod(cls, deallocSel, deallocImp, method_getTypeEncoding(dellocMethod));
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    id value = [change objectForKey:NSKeyValueChangeNewKey];
    if (_map != nil) {
        value = _map(value);
    }
    [_layoutView setAttribute:value forKeyPath:_keyPath];
}

- (void)dealloc {
    if (!_isRemoved) {
        [_obj removeObserver:self forKeyPath:_objectKeyPath context:(__bridge void * _Nullable)(self)];
        _isRemoved = YES;
    }
}

@end
