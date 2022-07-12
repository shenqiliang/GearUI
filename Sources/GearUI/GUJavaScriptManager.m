//
//  GUJavaScriptManager.m
//  GearUI
//
//  Created by 谌启亮 on 14/12/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUJavaScriptManager.h"
#import "GUConfigure.h"
#import <objc/runtime.h>
#import "GUButton.h"
#import "GUWeakProxy.h"
#import "GULayoutView.h"
#import "GULog.h"
#import "GUJSFunction.h"

//JS_EXPORT void JSSynchronousGarbageCollectForDebugging(JSContextRef ctx);

// array 转化成CG结构（CGRect/CGPoint....）
NSValue *NSArrayToCGNSValue(NSArray *array, const char *objcType) {
    CGFloat *buffer = malloc(sizeof(CGFloat)*array.count);
    for (int i = 0; i < array.count; i++) {
        buffer[i] = [array[i] doubleValue];
    }
    return [NSValue valueWithBytes:buffer objCType:objcType];
}


@interface NSObject (JSSupport)

- (Class)gu_Class;

@end

@implementation NSObject (JSSupport)
- (Class)gu_Class {
    return [self class];
}
@end


@interface GUBlockJSValueProtector: NSObject

@property(nonatomic, assign) JSValueRef value;
@property(nonatomic, assign) JSObjectRef object;
@property(nonatomic, assign) JSContextRef context;


- (instancetype)initWithJSValueRef:(JSValueRef)ref objectRef:(JSObjectRef)objref context:(JSContextRef)context;

@end

@implementation GUBlockJSValueProtector

- (instancetype)initWithJSValueRef:(JSValueRef)ref objectRef:(JSObjectRef)objref context:(JSContextRef)context {
    self = [super init];
    if (self) {
        _value = ref;
        _object = objref;
        _context = context;
        JSValueProtect(context, ref);
    }
    return self;
}


- (void)dealloc {
    JSValueUnprotect(_context, _value);
}


@end


@interface GUJavaScriptManager ()

- (JSClassRef)jsMetaClassForClassName:(NSString *)className;
- (void)addManagedObject:(id)obj;
- (void)removeManagedObject:(id)obj;
- (void)importClassIfNeeded:(Class)class;
- (JSClassRef)jsClassForClass:(Class)class;
- (JSClassRef)jsClassForClassName:(NSString *)className;

@end

static JSClassRef methodClass = NULL;
static JSClassRef globalClass = NULL;

/// 将Objective-C对象转化成JavaScript对象
JSValueRef JSValueMakeWithObject(JSContextRef context, id obj) {
    if (obj == nil) {
        return JSValueMakeNull(context);
    }
    else if ([obj isKindOfClass:[NSString class]]) {
        JSStringRef stringRef = JSStringCreateWithCFString((__bridge CFStringRef)(obj));
        JSValueRef ret = JSValueMakeString(context, stringRef);
        JSStringRelease(stringRef);
        return ret;
    }
    else if ([obj isKindOfClass:[NSNumber class]]) {
        NSNumber *num = obj;
        if (strcmp(num.objCType, @encode(bool)) == 0) {
            return JSValueMakeBoolean(context, [num boolValue]);
        }
        else {
            return JSValueMakeNumber(context, [num doubleValue]);
        }
    }
    Class class = [obj gu_Class];
    JSObjectRef jsObject = JSObjectMake(context, [GUJavaScriptManager.sharedInstance jsClassForClass:class], (__bridge void *)(obj));
    return jsObject;
}

/// 将JavaScript对象转化成Objective-C对象
id NSObjectFromJSValue(JSContextRef context, JSValueRef value) {
    if (JSValueIsNull(context, value)) {
        return nil;
    }
    else if (JSValueIsNumber(context, value)) {
        return @(JSValueToNumber(context, value, NULL));
    }
    else if (JSValueIsBoolean(context, value)) {
        return @(JSValueToBoolean(context, value));
    }
    else if (JSValueIsString(context, value)) {
        JSStringRef stringRef = JSValueToStringCopy(context, value, NULL);
        if (stringRef) {
            NSString *ret = CFBridgingRelease(JSStringCopyCFString(NULL, stringRef));
            JSStringRelease(stringRef);
            return ret;
        }
    }
    else if (JSValueIsArray(context, value)) {
        id ret = (__bridge id)(JSObjectGetPrivate((JSObjectRef)value));
        if (ret != nil) {
            return ret;
        }
        JSObjectRef jsObj = JSValueToObject(context, value, NULL);
        NSMutableArray *array = [NSMutableArray array];
        JSPropertyNameArrayRef jsPropertys = JSObjectCopyPropertyNames(context, jsObj);
        for (int i = 0; i < JSPropertyNameArrayGetCount(jsPropertys); i++) {
            JSValueRef jsProperty = JSObjectGetPropertyAtIndex(context, jsObj, i, NULL);
            id propertyValue = NSObjectFromJSValue(context, jsProperty);
            [array addObject:propertyValue];
        }
        JSPropertyNameArrayRelease(jsPropertys);
        return [array copy];
        
    }
    else if (JSValueIsObject(context, value)) {
        id ret = (__bridge id)(JSObjectGetPrivate((JSObjectRef)value));
        if (ret != nil) {
            return ret;
        }
        
        JSObjectRef jsObj = JSValueToObject(context, value, NULL);
        
        if (JSObjectIsFunction(context, jsObj)) {
            GUJSFunction *function = [GUJSFunction new];
            function.functionJSObject = jsObj;
            function.functionJSValue = value;
            return function;
        }
        else {
            NSMutableDictionary *jsObjInfo = [NSMutableDictionary dictionary];
            JSPropertyNameArrayRef jsPropertys = JSObjectCopyPropertyNames(context, jsObj);
            for (int i = 0; i < JSPropertyNameArrayGetCount(jsPropertys); i++) {
                JSStringRef jsPropertyName = JSPropertyNameArrayGetNameAtIndex(jsPropertys, i);
                JSValueRef jsProperty = JSObjectGetProperty(context, jsObj, jsPropertyName, NULL);
                NSString *propertyName = CFBridgingRelease(JSStringCopyCFString(NULL, jsPropertyName));
                id propertyValue = NSObjectFromJSValue(context, jsProperty);
                if (propertyName != nil && propertyValue != nil) {
                    jsObjInfo[propertyName] = propertyValue;
                }
            }
            JSPropertyNameArrayRelease(jsPropertys);
            return [jsObjInfo copy];
        }
    }
    return nil;
}

// JavaScript函数对象发生调用，执行Objective-C调用
static JSValueRef ObjectCallAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    id obj = (__bridge id)(JSObjectGetPrivate(thisObject));
    SEL sel = JSObjectGetPrivate(function);
    NSMethodSignature *sig = [obj methodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    invocation.selector = sel;
    invocation.target = obj;
    NSMutableArray *argument = [NSMutableArray array];
    for (int i = 0; i < argumentCount; i++) {
        id arg = NSObjectFromJSValue(ctx, arguments[i]);
        if (arg != nil) {
            const char *argType = [sig getArgumentTypeAtIndex:i+2];
            
            // 系统结构先转成NSValue处理
            if ([arg isKindOfClass:[NSArray class]]) {
                NSValue *value = NSArrayToCGNSValue(arg, argType);
                if (value != nil) {
                    arg = value;
                }
            }
            
            // 类型适配
            if (strcmp(argType,  @encode(id)) == 0) {
                [argument addObject:arg];
                [invocation setArgument:&arg atIndex:i+2];
            }
            else if (strcmp(argType, @encode(dispatch_block_t)) == 0) {
                [argument addObject:arg];
                [invocation setArgument:&arg atIndex:i+2];
            }
            else if ([arg isKindOfClass:[NSValue class]]) {
                if (strcmp(argType, @encode(BOOL)) == 0) {
                    BOOL v = [arg boolValue];
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(char)) == 0) {
                    char v = [arg charValue];
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(unsigned char)) == 0) {
                    unsigned char v = [arg unsignedCharValue];
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(int16_t)) == 0) {
                    int16_t v = 0;
                    if (@available(iOS 11.0, *)) {
                        [arg getValue:&v size:sizeof(int16_t)];
                    } else {
                        [arg getValue:&v];
                    }
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(uint16_t)) == 0) {
                    uint16_t v = 0;
                    if (@available(iOS 11.0, *)) {
                        [arg getValue:&v size:sizeof(uint16_t)];
                    } else {
                        [arg getValue:&v];
                    }
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(int32_t)) == 0) {
                    int32_t v = 0;
                    if (@available(iOS 11.0, *)) {
                        [arg getValue:&v size:sizeof(int32_t)];
                    } else {
                        [arg getValue:&v];
                    }
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(uint32_t)) == 0) {
                    uint32_t v = 0;
                    if (@available(iOS 11.0, *)) {
                        [arg getValue:&v size:sizeof(uint32_t)];
                    } else {
                        [arg getValue:&v];
                    }
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(int64_t)) == 0) {
                    int64_t v = 0;
                    if (@available(iOS 11.0, *)) {
                        [arg getValue:&v size:sizeof(int64_t)];
                    } else {
                        [arg getValue:&v];
                    }
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(uint64_t)) == 0) {
                    uint64_t v = 0;
                    if (@available(iOS 11.0, *)) {
                        [arg getValue:&v size:sizeof(uint64_t)];
                    } else {
                        [arg getValue:&v];
                    }
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(float)) == 0) {
                    float v = [arg floatValue];
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(double)) == 0) {
                    double v = [arg doubleValue];
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(CGRect)) == 0) {
                    CGRect v = [arg CGRectValue];
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(CGPoint)) == 0) {
                    CGPoint v = [arg CGPointValue];
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(CGVector)) == 0) {
                    CGVector v = [arg CGVectorValue];
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(CGSize)) == 0) {
                    CGSize v = [arg CGSizeValue];
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(UIEdgeInsets)) == 0) {
                    UIEdgeInsets v = [arg UIEdgeInsetsValue];
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(UIOffset)) == 0) {
                    UIOffset v = [arg UIOffsetValue];
                    [invocation setArgument:&v atIndex:i+2];
                }
                else if (strcmp(argType, @encode(CGAffineTransform)) == 0) {
                    CGAffineTransform v = [arg CGAffineTransformValue];
                    [invocation setArgument:&v atIndex:i+2];
                }
                else {
                    GUError(@"[ERROR] javascript undefined value %@ type %s", arg, argType);
                    return JSValueMakeUndefined(ctx);
                }
            }
            else {
                GUError(@"[ERROR] javascript undefined value %@ type %s", arg, argType);
                return JSValueMakeUndefined(ctx);
            }

        }
    }
    [invocation invoke];
    if (strcmp(sig.methodReturnType, @encode(void)) == 0) {
        return JSValueMakeUndefined(ctx);
    }
    else if (strcmp(sig.methodReturnType, @encode(id)) == 0) {
        void *ret = NULL;
        [invocation getReturnValue:&ret];
        id obj = nil;
        if (sel == @selector(alloc) || sel == @selector(allocWithZone:)) { // 如果是alloc方法，持有关系要transfer一下
            obj = (__bridge_transfer id)ret;
        }
        else {
            obj = (__bridge id)ret;
        }
        return JSValueMakeWithObject(ctx, obj);
    }
    else {
        NSUInteger length = [sig methodReturnLength];
        void *buffer = (void *)malloc(length);
        [invocation getReturnValue:buffer];
        JSValueRef ret = JSValueMakeWithObject(ctx, [NSValue value:buffer withObjCType:sig.methodReturnType]);
        free(buffer);
        return ret;
    }
}


/// JavaScript调用类构造方法，调用ObjC的alloc+init
static JSObjectRef ClassCallAsConstructor(JSContextRef ctx, JSObjectRef constructor, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    Class class = (__bridge Class)(JSObjectGetPrivate(constructor));
    NSString *className = NSStringFromClass(class);
    id obj = [[class alloc] init];
    return JSObjectMake(ctx, [GUJavaScriptManager.sharedInstance jsClassForClassName:className], (__bridge void *)obj);
}

/// 返回私有数据
static JSValueRef ReturnPrivateData(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    id obj = (__bridge id)(JSObjectGetPrivate(function));
    return JSValueMakeWithObject(ctx, obj);
}

/// 将JavaScript方法名转化成ObjC方法名
static NSString *convertToSelString(NSString *property) {
    property = [property stringByReplacingOccurrencesOfString:@"_" withString:@":"];
    property = [property stringByAppendingString:@":"];
    return property;
}

/// JavaScript调用属性（点操作符）
static JSValueRef ObjectGetProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception) {
    NSString *property = CFBridgingRelease((JSStringCopyCFString(NULL, propertyName)));
    id obj = (__bridge id)(JSObjectGetPrivate(object));
    Class clz = [obj gu_Class];
    objc_property_t property_oc = class_getProperty(clz, [property UTF8String]);
    SEL sel = NSSelectorFromString(property);
    SEL sel2 = NSSelectorFromString(convertToSelString(property));
    if (property_oc) {
        return JSValueMakeWithObject(ctx, [obj valueForKey:property]);
    }
    else if ([obj respondsToSelector:sel]) {
        JSObjectRef ret = JSObjectMake(ctx, methodClass, sel);
        return ret;
    }
    else if ([obj respondsToSelector:sel2]) {
        JSObjectRef ret = JSObjectMake(ctx, methodClass, sel2);
        return ret;
    }
    return NULL;
}

/// JavaScript设置属性/Setter（点操作符+赋值）
static bool ObjectSetProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSValueRef* exception) {
    NSString *property = CFBridgingRelease((JSStringCopyCFString(NULL, propertyName)));
    id obj = (__bridge id)(JSObjectGetPrivate(object));
    @try {
        [obj setValue:NSObjectFromJSValue(ctx, value) forKey:property];
    } @catch (NSException *e) {
        *exception = JSValueMakeWithObject(ctx, [NSString stringWithFormat:@"[ERROR]%@", e]);
    } @finally { }
    return true;
}

/// JavaScript对象初始化，此时将JavaScript对象对应OC对象加入内存管理。
static void ObjectInitialize(JSContextRef ctx, JSObjectRef object) {
    void *privateData = JSObjectGetPrivate(object);
    if (privateData != NULL) {
        id obj = (__bridge id)privateData;
        [GUJavaScriptManager.sharedInstance addManagedObject:obj];
    }
}


/// JavaScript对象释放，此时将JavaScript对象对应OC对象移出内存管理
static void ObjectFinalize(JSObjectRef object) {
    void *privateData = JSObjectGetPrivate(object);
    if (privateData != NULL) {
        id obj = (__bridge id)privateData;
        [GUJavaScriptManager.sharedInstance removeManagedObject:obj];
    }
}

/// 类获取属性，OC类本身就是对象，同对象处理
static JSValueRef ClassGetProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception) {
    return ObjectGetProperty(ctx, object, propertyName, exception);
}

/// 类设置属性，OC类本身就是对象，同对象处理
static bool ClassSetProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSValueRef* exception) {
    return ObjectSetProperty(ctx, object, propertyName, value, exception);
}

/// 全局变量/属性是否存在回调，当JavaScript中出现一个全新的标识符时会用此回调判断
static bool GlobalHasProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName) {
    NSString *property = CFBridgingRelease((JSStringCopyCFString(NULL, propertyName)));
    if ([property isEqualToString:@"Object"]) {
        return false;
    }
    
    // 全局函数
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"javascript:call_%@:", property]);
    if ([[GUJavaScriptManager sharedInstance] respondsToSelector:sel]) {
        return YES;
    }

    JSObjectRef globalObject = JSContextGetGlobalObject(ctx);
    if (globalObject) {
        GULayoutView *view = (__bridge GULayoutView *)(JSObjectGetPrivate(globalObject));
        if ([view isKindOfClass:[GULayoutView class]]) {
            if ([view viewWithNodeId:property] != nil) {
                return true;
            }
        }
    }
    
    Class class = NSClassFromString(property);
    if (class == nil) {
        NSString *classNameSwift = [NSString stringWithFormat:@"%@.%@", [[NSBundle mainBundle] infoDictionary][@"CFBundleName"], property];
        class = NSClassFromString(classNameSwift);
    }
    if (class) {
        [GUJavaScriptManager.sharedInstance importClassIfNeeded:class];
        return true;
    }
    return false;
}

/// 获取全局变量/属性
static JSValueRef GlobalGetProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception) {
    NSString *property = CFBridgingRelease((JSStringCopyCFString(NULL, propertyName)));
    
    JSObjectRef globalObject = JSContextGetGlobalObject(ctx);
    if (globalObject) {
        GULayoutView *view = (__bridge GULayoutView *)(JSObjectGetPrivate(globalObject));
        if ([view isKindOfClass:[GULayoutView class]]) {
            id subNodeObj = [view viewWithNodeId:property];
            if (subNodeObj != nil) {
                return JSValueMakeWithObject(ctx, subNodeObj);
            }
        }
    }
    
    // 全局函数
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"javascript:call_%@:", property]);
    if ([[GUJavaScriptManager sharedInstance] respondsToSelector:sel]) {
        return JSObjectMake(ctx, globalClass, sel);;
    }


    NSString *className = property;
    JSClassRef classMetaRef = [GUJavaScriptManager.sharedInstance jsMetaClassForClassName:className];
    if (classMetaRef != NULL) {
        Class class = NSClassFromString(className);
        if (class == nil) {
            className = [NSString stringWithFormat:@"%@.%@", [[NSBundle mainBundle] infoDictionary][@"CFBundleName"], className];
            class = NSClassFromString(className);
        }
        JSObjectRef metaClass = JSObjectMake(ctx, classMetaRef, (__bridge void *)(class));
        return metaClass;
    }
    else {
        return NULL;
    }
}

/// 设置全局变量/属性
static bool GlobalSetProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSValueRef* exception) {
    return false;
}

// 全局函数调用
static JSValueRef GlobalCallAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    SEL sel = JSObjectGetPrivate(function);
    NSMutableArray *argument = [NSMutableArray array];
    for (int i = 0; i < argumentCount; i++) {
        id arg = NSObjectFromJSValue(ctx, arguments[i]);
        if (arg == nil) {
            arg = [NSNull null];
        }
        [argument addObject:arg];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id obj = [[GUJavaScriptManager sharedInstance] performSelector:sel withObject:(__bridge id)ctx withObject:argument];
#pragma clang diagnostic pop
    return JSValueMakeWithObject(ctx, obj);
}



/// 对象类型转换回调，目前支持String
JSValueRef ObjectConvertToType(JSContextRef ctx, JSObjectRef object, JSType type, JSValueRef* exception) {
    if (JSValueIsObject(ctx, object)) {
        id obj = NSObjectFromJSValue(ctx, object);
        NSString *description = [obj description];
        JSStringRef stringRef = JSStringCreateWithCFString((__bridge CFStringRef)(description));
        JSValueRef ret = JSValueMakeString(ctx, stringRef);
        JSStringRelease(stringRef);
        return ret;
    }
    return NULL;
}


const void *retainJSClass(CFAllocatorRef allocator, const void *value) {
    return JSClassRetain((JSClassRef)value);
}
void  releaseJSClass(CFAllocatorRef allocator, const void *value) {
    return JSClassRelease((JSClassRef)value);
}

__attribute__((constructor)) void __GUJavaScriptLoad__(void) {
    JSClassDefinition methodDef = {
        .version = 0,
        .callAsFunction = ObjectCallAsFunction
    };
    methodClass = JSClassCreate(&methodDef);
    
    JSClassDefinition globalDef = {
        .version = 0,
        .callAsFunction = GlobalCallAsFunction
    };
    globalClass = JSClassCreate(&globalDef);

}


// JavaScript Runtime Manager
@implementation GUJavaScriptManager {
    
    CFMutableDictionaryRef _ocJSClassMap; // OC类映射的JS类缓存
    CFMutableDictionaryRef _ocJSMetaClassMap; // OC元类映射的JS类缓存
    
    NSMutableArray *_managedObjCObjects; // JS环境持有的OC对象

    JSContextGroupRef _contextGroupRef; // JS context Group
}


// 获取单例对象
+ (instancetype)sharedInstance{
    static GUJavaScriptManager *g_GUJavaScriptManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_GUJavaScriptManager = [GUJavaScriptManager new];
    });
    return g_GUJavaScriptManager;
}


// 初始化
- (instancetype)init
{
    self = [super init];
    if (self) {
        
        // 创建OC类映射的JS类缓存，使用CFDictionary控制对象引用计数
        CFDictionaryValueCallBacks valueCallBacks;
        valueCallBacks.version = 0;
        valueCallBacks.retain = retainJSClass;
        valueCallBacks.release = releaseJSClass;
        _ocJSClassMap = CFDictionaryCreateMutable(NULL, 0, &kCFCopyStringDictionaryKeyCallBacks, &valueCallBacks);
        _ocJSMetaClassMap = CFDictionaryCreateMutable(NULL, 0, &kCFCopyStringDictionaryKeyCallBacks, &valueCallBacks);
        
        // 使用可变数据将JS引用的OC对象持有，防止执行时释放
        _managedObjCObjects = [NSMutableArray new];
        
        // JS Context Group
        _contextGroupRef = JSContextGroupCreate();
        
        
#if DEBUG | TEST
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        // 开启Safari调试
        [NSClassFromString(@"WebView") performSelector:@selector(_enableRemoteInspector)];
#pragma clang diagnostic pop

#endif
        
    }
    return self;
}


// 增加JS环境OC对象持有
- (void)addManagedObject:(id)obj {
    [_managedObjCObjects addObject:obj];
}

// 移除JS环境OC对象持有
- (void)removeManagedObject:(id)obj {
    NSUInteger index = [_managedObjCObjects indexOfObject:obj];
    if (index != NSNotFound) {
        [_managedObjCObjects removeObjectAtIndex:index];
    }
    else {
        GUWarn(@"Not found managed object %@", obj);
    }
}

// 获取OC元类的JS类定义。使用类名
- (JSClassRef)jsMetaClassForClassName:(NSString *)className {
    JSClassRef ref = (JSClassRef)CFDictionaryGetValue(_ocJSMetaClassMap, (__bridge const void *)(className));
    if (ref == NULL) {
        className = [NSString stringWithFormat:@"%@.%@", [[NSBundle mainBundle] infoDictionary][@"CFBundleName"], className];
        ref = (JSClassRef)CFDictionaryGetValue(_ocJSMetaClassMap, (__bridge const void *)(className));
    }
    return ref;
}

// 获取OC元类的JS类定义。使用类
- (JSClassRef)jsMetaClassForClass:(Class)class {
    return [self jsMetaClassForClassName:NSStringFromClass(class)];
}

// 获取OC类的JS类定义。使用类名
- (JSClassRef)jsClassForClassName:(NSString *)className {
    JSClassRef ref = (JSClassRef)CFDictionaryGetValue(_ocJSClassMap, (__bridge const void *)(className));
    if (ref == NULL) {
        className = [NSString stringWithFormat:@"%@.%@", [[NSBundle mainBundle] infoDictionary][@"CFBundleName"], className];
        ref = (JSClassRef)CFDictionaryGetValue(_ocJSClassMap, (__bridge const void *)(className));
    }
    return ref;
}

// 获取OC类的JS类定义。使用类
- (JSClassRef)jsClassForClass:(Class)class {
    if (class) {
        [self importClassIfNeeded:class];
        return [self jsClassForClassName:NSStringFromClass(class)];
    }
    else {
        return NULL;
    }
}


// 导入OC类
- (void)importClassIfNeeded:(Class)class {
    NSString *className = NSStringFromClass(class);
    if ([self jsClassForClassName:className] == nil) {
        const Class superClass = class_getSuperclass(class);
        if (superClass != nil && class != [NSObject class]) {
            [self importClassIfNeeded:superClass];
        }
        JSClassDefinition classMetaDef = kJSClassDefinitionEmpty;
        classMetaDef.version = 0;
        classMetaDef.attributes = kJSClassAttributeNone;
        classMetaDef.parentClass = [self jsMetaClassForClass:superClass];
        classMetaDef.getProperty = ClassGetProperty;
        classMetaDef.setProperty = ClassSetProperty;
        classMetaDef.callAsConstructor = ClassCallAsConstructor;
        classMetaDef.callAsFunction = ReturnPrivateData;
        classMetaDef.convertToType = ObjectConvertToType;
        JSClassRef jsMetaClass = JSClassCreate(&classMetaDef);
        CFDictionarySetValue(_ocJSMetaClassMap, (__bridge const void *)(className), jsMetaClass);
        
        JSClassDefinition classDef = kJSClassDefinitionEmpty;
        classDef.version = 0;
        classDef.attributes = kJSClassAttributeNone;
        classDef.className = [className UTF8String];
        classDef.parentClass = [self jsClassForClass:superClass];
        classDef.getProperty = ObjectGetProperty;
        classDef.setProperty = ObjectSetProperty;
        classDef.initialize = ObjectInitialize;
        classDef.finalize = ObjectFinalize;
        classDef.callAsFunction = ReturnPrivateData;
        classDef.convertToType = ObjectConvertToType;
        JSClassRef jsClass = JSClassCreate(&classDef);
        CFDictionarySetValue(_ocJSClassMap, (__bridge const void *)(className), jsClass);
    }
}


// 根据LayoutView创建一个JS上下文
- (JSContext *)genContextInLayoutView:(GULayoutView *)layoutView {
    JSClassDefinition classDef = kJSClassDefinitionEmpty;
    classDef.version = 0;
    classDef.attributes = kJSClassAttributeNone;
    classDef.hasProperty = GlobalHasProperty;
    classDef.getProperty = GlobalGetProperty;
    classDef.setProperty = GlobalSetProperty;
    JSClassRef globalObjectClass = JSClassCreate(&classDef);
    JSGlobalContextRef globalContext = JSGlobalContextCreateInGroup(_contextGroupRef, globalObjectClass);
    JSObjectRef globalObject = JSContextGetGlobalObject(globalContext);
    JSObjectSetPrivate(globalObject, (__bridge void *)(layoutView));
    JSContext *jsContext = [JSContext contextWithJSGlobalContextRef:globalContext];
    JSClassRelease(globalObjectClass);
    jsContext[@"GULog"] = ^(NSString *msg) {
        NSLog(@"%@", msg);
    };
    return jsContext;
}


// 执行垃圾回收
- (void)garbageCollectContext:(JSContext *)context {
    if (context == nil) {
        return;
    }
    JSGlobalContextRef globalContext = context.JSGlobalContextRef;
    JSGarbageCollect(globalContext);
//    JSSynchronousGarbageCollectForDebugging(globalContext);
}

// 删除JS上下文
- (void)deleteContext:(JSContext *)context {
    if (context == nil) {
        return;
    }
    JSGlobalContextRef globalContext = context.JSGlobalContextRef;
    JSGarbageCollect(globalContext);
//    JSSynchronousGarbageCollectForDebugging(globalContext);
    JSObjectRef globalObject = JSContextGetGlobalObject(globalContext);
    if (globalObject) {
        JSObjectSetPrivate(globalObject, NULL);
    }
    JSGlobalContextRelease(globalContext);
}


// 设置全局变量
- (void)setGlobalVar:(id)var forName:(NSString *)name inContext:(JSContext *)context {
    JSValueRef value = JSValueMakeWithObject(context.JSGlobalContextRef, var);
    context[name] = [JSValue valueWithJSValueRef:value inContext:context];
}

#pragma mark 支持Block
// Block结构layout
struct Block_literal_1 {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void);             // IFF (1<<25)
    struct Block_descriptor_1 {
    unsigned long int reserved;         // NULL
        unsigned long int size;         // sizeof(struct Block_literal_1)
        // optional helper functions
        void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
        void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        const char *signature;                         // IFF (1<<30)
    } *descriptor;
};

// JSValue保护对象AssociatedObjectKey
static const char *kProtector = "kProtector";

// 参数签名AssociatedObjectKey
static const char *kArgumentSign = "kArgumentSign";

// 替换的Block函数指针声明
void __GU_VOID_BLOCK_FUNCTION__(struct Block_literal_1 *block, ...);

// 全局函数OCBlock()，生成Block对象
//   eg: var block = OCBlock(["@", B], function(obj, isOk) {} )
- (id)javascript:(JSContextRef)context call_OCBlock:(NSArray *)arguments {
    // 获取参数
    NSArray *argementSign = arguments[0]; // 第一个参数：参数签名列表
    GUJSFunction *function = arguments[1];  // 第二个参数：JS函数
    
    function.jsContext = JSContextGetGlobalContext(context); // 设置函数的js context
    
    // 生成一个占位Block
    dispatch_block_t block = ^() {
        [function doNothing]; // 捕获一个变量，防止编译器优化成静态化的Block
    };
    
    // 将block强制转换成结构指针，以访问其内部成员
    struct Block_literal_1 *blockS = (__bridge struct Block_literal_1 *)block;
    // 将Block的运行的函数指针替换成我们通用的block执行函数
    blockS->invoke = (void *)__GU_VOID_BLOCK_FUNCTION__;
    
    // 生成JS对象保护对象。由于Block可能是异步执行的，需要保证JS对象在异步运行时依然有效
    GUBlockJSValueProtector *protector = [[GUBlockJSValueProtector alloc] initWithJSValueRef:function.functionJSValue objectRef:function.functionJSObject context:function.jsContext];
    
    // 将保护对象和参数签名列表绑定到block对象上
    objc_setAssociatedObject(block, kProtector, protector, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(block, kArgumentSign, argementSign, OBJC_ASSOCIATION_RETAIN);
    return block;
}

@end

void __GU_VOID_BLOCK_FUNCTION__(struct Block_literal_1 *block, ...) {
    NSLog(@"__GU_VOID_BLOCK_FUNCTION__ begin");
    NSArray *argumentSign = objc_getAssociatedObject((__bridge id)block, kArgumentSign);
    size_t argumentCount = argumentSign.count;
    GUBlockJSValueProtector *protector = objc_getAssociatedObject((__bridge id)block, kProtector);
    if (argumentCount > 0) {
        va_list ap;
        va_start(ap, block);
        JSValueRef *arguments = malloc(argumentCount * sizeof(JSValueRef));
        for (int i = 0; i < argumentCount; i++) {
            const char *argSign = [argumentSign[i] UTF8String];
            if (strcmp(argSign, @encode(BOOL)) == 0) {
                BOOL arg = va_arg(ap, int);
                arguments[i] = JSValueMakeBoolean(protector.context, arg);
            }
            else if (strcmp(argSign, @encode(id)) == 0) {
                id arg = va_arg(ap, id);
                arguments[i] = JSValueMakeWithObject(protector.context, arg);
            }
            else if (strcmp(argSign, @encode(char)) == 0) {
                char arg = va_arg(ap, int);
                arguments[i] = JSValueMakeNumber(protector.context, arg);
            }
            else if (strcmp(argSign, @encode(unsigned char)) == 0) {
                unsigned char arg = va_arg(ap, int);
                arguments[i] = JSValueMakeNumber(protector.context, arg);
            }
            else if (strcmp(argSign, @encode(int16_t)) == 0) {
                int16_t arg = va_arg(ap, int);
                arguments[i] = JSValueMakeNumber(protector.context, arg);
            }
            else if (strcmp(argSign, @encode(uint16_t)) == 0) {
                uint16_t arg = va_arg(ap, unsigned int);
                arguments[i] = JSValueMakeNumber(protector.context, arg);
            }
            else if (strcmp(argSign, @encode(int32_t)) == 0) {
                int32_t arg = va_arg(ap, int32_t);
                arguments[i] = JSValueMakeNumber(protector.context, arg);
            }
            else if (strcmp(argSign, @encode(uint32_t)) == 0) {
                uint32_t arg = va_arg(ap, uint32_t);
                arguments[i] = JSValueMakeNumber(protector.context, arg);
            }
            else if (strcmp(argSign, @encode(int64_t)) == 0) {
                int64_t arg = va_arg(ap, int64_t);
                arguments[i] = JSValueMakeNumber(protector.context, arg);
            }
            else if (strcmp(argSign, @encode(uint64_t)) == 0) {
                uint64_t arg = va_arg(ap, uint64_t);
                arguments[i] = JSValueMakeNumber(protector.context, arg);
            }
            else if (strcmp(argSign, @encode(float)) == 0) {
                float arg = va_arg(ap, double);
                arguments[i] = JSValueMakeNumber(protector.context, arg);
            }
            else if (strcmp(argSign, @encode(double)) == 0) {
                double arg = va_arg(ap, double);
                arguments[i] = JSValueMakeNumber(protector.context, arg);
            }
            else {
                argumentCount = i;
                break;
            }
        }
        va_end(ap);
        JSObjectCallAsFunction(protector.context, protector.object, NULL, argumentCount, arguments, NULL);
    }
    else {
        JSObjectCallAsFunction(protector.context, protector.object, NULL, 0, NULL, NULL);
    }
    NSLog(@"__GU_VOID_BLOCK_FUNCTION__ end");
}


