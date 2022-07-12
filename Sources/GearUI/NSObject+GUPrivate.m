//
//  NSObject+GUPrivate.m
//  GearUI
//
//  Created by 谌启亮 on 29/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "NSObject+GUPrivate.h"
#import "NSString+GUValue.h"
#import "GUNodeProtocol.h"
#import <objc/runtime.h>
#import "GUDefines.h"
#import "GUConfigure.h"
#import "GULog.h"

NSMutableDictionary *_propertyInfoCache;

id __GU_COMMON_ENUM_VALUE(NSString *name, NSString *value){
    static NSDictionary *g_AllEnums = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *NSTextAligmentEnumInfos = @{
                                                @"left":@(NSTextAlignmentLeft),
                                                @"right":@(NSTextAlignmentRight),
                                                @"center":@(NSTextAlignmentCenter),
                                                };
        
        NSDictionary *NSLineBreakModeEnumInfo = @{
                                                  @"clip":@(NSLineBreakByClipping),
                                                  @"char":@(NSLineBreakByCharWrapping),
                                                  @"word":@(NSLineBreakByWordWrapping),
                                                  @"tail":@(NSLineBreakByTruncatingTail),
                                                  @"head":@(NSLineBreakByTruncatingHead),
                                                  @"middle":@(NSLineBreakByTruncatingMiddle),
                                                  @"clipping":@(NSLineBreakByClipping),
                                                  @"charWrapping":@(NSLineBreakByCharWrapping),
                                                  @"wordWrapping":@(NSLineBreakByWordWrapping),
                                                  @"truncatingTail":@(NSLineBreakByTruncatingTail),
                                                  @"truncatingHead":@(NSLineBreakByTruncatingHead),
                                                  @"truncatingMiddle":@(NSLineBreakByTruncatingMiddle),
                                                  };
        
        NSDictionary *UIBaselineAdjustmentEnumInfo = @{
                                                       @"none":@(UIBaselineAdjustmentNone),
                                                       @"baseline":@(UIBaselineAdjustmentAlignBaselines),
                                                       @"center":@(UIBaselineAdjustmentAlignCenters),
                                                       @"alignBaselines":@(UIBaselineAdjustmentAlignBaselines),
                                                       @"alignCenters":@(UIBaselineAdjustmentAlignCenters),
                                                       };
        
        NSDictionary *UIViewContentModeEnumInfo = @{
                                                    @"top":@(UIViewContentModeTop),
                                                    @"left":@(UIViewContentModeLeft),
                                                    @"bottom":@(UIViewContentModeBottom),
                                                    @"right":@(UIViewContentModeRight),
                                                    @"center":@(UIViewContentModeCenter),
                                                    @"scale":@(UIViewContentModeScaleToFill),
                                                    @"fit":@(UIViewContentModeScaleAspectFit),
                                                    @"fill":@(UIViewContentModeScaleAspectFill),
                                                    @"scaleToFill":@(UIViewContentModeScaleToFill),
                                                    @"scaleAspectFit":@(UIViewContentModeScaleAspectFit),
                                                    @"scaleAspectFill":@(UIViewContentModeScaleAspectFill),
                                                    @"redraw":@(UIViewContentModeRedraw),
                                                    @"topLeft":@(UIViewContentModeTopLeft),
                                                    @"topRight":@(UIViewContentModeTopRight),
                                                    @"bottomLeft":@(UIViewContentModeBottomLeft),
                                                    @"bottomRight":@(UIViewContentModeBottomRight),
                                                    };
        
        g_AllEnums = @{
            @"textAlignment":NSTextAligmentEnumInfos,
            @"lineBreakMode":NSLineBreakModeEnumInfo,
            @"baselineAdjustment":UIBaselineAdjustmentEnumInfo,
            @"contentMode":UIViewContentModeEnumInfo,
            };
    });
    return g_AllEnums[name][value];
}

id __GU_NUMBER_VALUE(Class cls, NSString *name, id value) {
    id result = value;
    id enumValue = __GU_COMMON_ENUM_VALUE(name, value);
    if (enumValue) {
        result = enumValue;
    }
    else {
        id convertedValue = [[GUConfigure sharedInstance] enumValueForRepresentation:value forPropertyName:name ofClass:cls];
        if (convertedValue != nil) {
            result = convertedValue;
        }
    }
    return result;
}

BOOL __GU__NodeSetValue(id obj, NSString *name, id value){
    
    Class cls = [obj class];
    
    if (value == [NSNull null]) {
        value = nil;
    }
    
    NSString *firstCharCapitalName = [NSString stringWithFormat:@"%@%@", [[name substringToIndex:1] uppercaseString], [name substringFromIndex:1]];
    NSString *setter = [NSString stringWithFormat:@"set%@:", firstCharCapitalName];

    SEL selector = NSSelectorFromString(setter);

    Method m = class_getInstanceMethod(cls, selector);
    if (m) {
        if (![value isKindOfClass:[NSString class]]) {
            if ([obj respondsToSelector:NSSelectorFromString(name)] || [obj respondsToSelector:NSSelectorFromString([NSString stringWithFormat:@"is%@", firstCharCapitalName])]) {
                [obj setValue:value forKey:name];
                return YES;
            }
            else {
                GUError(@"Unsupported kvc %@", name);
                return NO;
            }
        }
        const char *attr = method_copyArgumentType(m, 2);
        IMP imp = method_getImplementation(m);
        if (strcmp(attr, @encode(NSInteger)) == 0) {
            value = __GU_NUMBER_VALUE(cls, name, value);
            ((void (*)(id,SEL,NSInteger))imp)(obj, selector, (NSInteger)[value integerValue]);
        }
        if (strcmp(attr, @encode(NSUInteger)) == 0) {
            value = __GU_NUMBER_VALUE(cls, name, value);
            ((void (*)(id,SEL,NSUInteger))imp)(obj, selector, (NSUInteger)[value longLongValue]);
        }
        else if (strcmp(attr, @encode(char)) == 0) {
            char v = 0;
            const char *utf = [value UTF8String];
            if (strstr(utf, "t") != NULL || strstr(utf, "t") != NULL || strstr(utf, "Y") != NULL || strstr(utf, "y") != NULL) {
                v = 1;
            }
            else {
                v = (char)[value intValue];
            }
            ((void (*)(id,SEL,char))imp)(obj, selector, v);
        }
        else if (strcmp(attr, @encode(int)) == 0) {
            value = __GU_NUMBER_VALUE(cls, name, value);
            ((void (*)(id,SEL,int))imp)(obj, selector, [value intValue]);
        }
        else if (strcmp(attr, @encode(short)) == 0) {
            ((void (*)(id,SEL,short))imp)(obj, selector, (short)[value intValue]);
        }
        else if (strcmp(attr, @encode(long)) == 0) {
            ((void (*)(id,SEL,long))imp)(obj, selector, (long)[value longLongValue]);
        }
        else if (strcmp(attr, @encode(long)) == 0) {
            ((void (*)(id,SEL,long))imp)(obj, selector, (long)[value longLongValue]);
        }
        else if (strcmp(attr, @encode(long long)) == 0) {
            ((void (*)(id,SEL,long long))imp)(obj, selector, (long long)[value longLongValue]);
        }
        else if (strcmp(attr, @encode(unsigned char)) == 0) {
            ((void (*)(id,SEL,unsigned char))imp)(obj, selector, (unsigned char)[value intValue]);
        }
        else if (strcmp(attr, @encode(unsigned int)) == 0) {
            ((void (*)(id,SEL,unsigned int))imp)(obj, selector, (unsigned int)[value longLongValue]);
        }
        else if (strcmp(attr, @encode(unsigned short)) == 0) {
            ((void (*)(id,SEL,unsigned short))imp)(obj, selector, (unsigned short)[value longLongValue]);
            return YES;
        }
        else if (strcmp(attr, @encode(unsigned long)) == 0) {
            ((void (*)(id,SEL,unsigned long))imp)(obj, selector, (unsigned long)[value longLongValue]);
        }
        else if (strcmp(attr, @encode(unsigned long long)) == 0) {
            ((void (*)(id,SEL,unsigned long long))imp)(obj, selector, (unsigned long long)[value longLongValue]);
        }
        else if (strcmp(attr, @encode(float)) == 0) {
            ((void (*)(id,SEL,float))imp)(obj, selector, [value floatValue]);
        }
        else if (strcmp(attr, @encode(double)) == 0) {
            ((void (*)(id,SEL,double))imp)(obj, selector, [value doubleValue]);
        }
        else if (strcmp(attr, @encode(bool)) == 0) {
            ((void (*)(id,SEL,bool))imp)(obj, selector, (bool)[value boolValue]);
        }
        else if (strcmp(attr, @encode(CGRect)) == 0) {
            ((void (*)(id,SEL,CGRect))imp)(obj, selector, CGRectFromString(value));
        }
        else if (strcmp(attr, @encode(CGPoint)) == 0) {
            ((void (*)(id,SEL,CGPoint))imp)(obj, selector, CGPointFromString(value));
        }
        else if (strcmp(attr, @encode(CGVector)) == 0) {
            ((void (*)(id,SEL,CGVector))imp)(obj, selector, CGVectorFromString(value));
        }
        else if (strcmp(attr, @encode(CGSize)) == 0) {
            ((void (*)(id,SEL,CGSize))imp)(obj, selector, CGSizeFromString(value));
        }
        else if (strcmp(attr, @encode(UIEdgeInsets)) == 0) {
            ((void (*)(id,SEL,UIEdgeInsets))imp)(obj, selector, UIEdgeInsetsFromString(value));
        }
        else if (strcmp(attr, @encode(UIOffset)) == 0) {
            ((void (*)(id,SEL,UIOffset))imp)(obj, selector, UIOffsetFromString(value));
        }
        else if (strcmp(attr, @encode(CGAffineTransform)) == 0) {
            ((void (*)(id,SEL,CGAffineTransform))imp)(obj, selector, CGAffineTransformFromString(value));
        }
        else if (strcmp(attr, @encode(id)) == 0) {
            
            id param = value;

            if ([name hasSuffix:@"Color"] || [name isEqualToString:@"color"]) {
                param = [value gu_UIColorValue];
            }
            else if ([name hasSuffix:@"Font"] || [name isEqualToString:@"font"]) {
                param = [value gu_UIFontValue];
            }
            else if ([name hasSuffix:@"Image"] || [name isEqualToString:@"image"]) {
                param = [value gu_UIImageValue];
            }
            ((void (*)(id,SEL,id))imp)(obj, selector, param);
        }
        else {
            GUError(@"Unsupported encoding for attribute \"%@\" found encode: %s", name, attr);
            return NO;
        }
        free((void*)attr);
    }
    else{
        GUError(@"Unsupported attribute \"%@\" on %@", name, [obj class]);
        return NO;
    }
    return YES;
}

@implementation NSObject (GUPrivate)

SYNTHESIZE_CATEGORY_OBJ_PROPERTY(gu_loadedAttributes, setGu_loadedAttributes:)

- (void)gu_setAttributeValue:(NSString *)value forName:(NSString *)name{
    if (![self respondsToSelector:@selector(updateAttributeValue:forName:)] || ![(id)self updateAttributeValue:value forName:name]) {
        __GU__NodeSetValue(self, name, value);
    }
}

- (void)gu_setAttributeValues:(NSDictionary *)attributes {
    if ([self respondsToSelector:@selector(updateCombinedAttributes:)]) {
        attributes = [(id)self updateCombinedAttributes:attributes];
    }
    if ([attributes isKindOfClass:[NSDictionary class]]) {
        for (NSString *key in attributes) {
            [self gu_setAttributeValue:attributes[key] forName:key];
        }
    }
}

- (NSArray *)gu_delayedUpdateAttributeNames{
    return [NSArray array];
}

- (void)gu_sendNodeDidTapAction{
    
}

- (void)gu_bindPropertyForSubClassOf:(Class)cls {
    if (![self isKindOfClass:cls]) {
        GUError(@"[ERROR] binding when class not match.");
        return;
    }
    unsigned int outCount = 0;
    Class bindCheckClass = self.class;
    while (bindCheckClass && bindCheckClass != cls) {
        objc_property_t *list = class_copyPropertyList(bindCheckClass, &outCount);
        NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"T@\"([\\w\\.]+)\"" options:0 error:nil];
        for (int i = 0; i < outCount; i++) {
            objc_property_t property = list[i];
            const char *name = property_getName(property);
            if (name!= NULL) {
                NSString *propertName = [NSString stringWithUTF8String:name];
                NSString *nodeId = [NSString stringWithFormat:@"#%@", propertName];
                id outletObj = [(id<GUNodeProtocol>)self subnodeWithId:nodeId];
                if (outletObj != nil) {
                    NSString *attribute = [NSString stringWithUTF8String:property_getAttributes(property)];
                    NSTextCheckingResult *result = [re firstMatchInString:attribute options:0 range:NSMakeRange(0, attribute.length)];
                    if (result.numberOfRanges == 2) {
                        NSRange classNameRange = [result rangeAtIndex:1];
                        NSString *className = [attribute substringWithRange:classNameRange];
                        Class class = NSClassFromString(className);
                        if (class && [outletObj isKindOfClass:class] && [propertName length] > 0 && outletObj) {
                            [self setValue:outletObj forKey:propertName];
                        }
                        else {
                            GUFail(@"Class(%@) define for property(%@) not match the instance class(%@).", class, propertName, [outletObj class]);
                        }
                    }
                }
            }
            
        }
        free(list);
        bindCheckClass = class_getSuperclass(bindCheckClass);
    }
}

@end


__attribute__((constructor)) void __GearUILoadFunc__(void) {
    NSLog(@"Load");
//    const char *imageName = class_getImageName([GUConfigure class]);
//    unsigned int count = 0;
//    const char **classNames = objc_copyClassNamesForImage(imageName, &count);
//    for (int i = 0; i < count; i++) {
//        //NSLog(@"%s", classNames[i]);
//    }
}
