//
//  GUDefines.h
//  GearUI
//
//  Created by 谌启亮 on 29/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#ifndef GUDefines_h
#define GUDefines_h

#define SYNTHESIZE_CATEGORY_OBJ_PROPERTY(propertyGetter, propertySetter) \
- (id) propertyGetter { \
return objc_getAssociatedObject(self, @selector( propertyGetter )); \
} \
- (void) propertySetter (id)obj{ \
objc_setAssociatedObject(self, @selector( propertyGetter ), obj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);\
}


#define SYNTHESIZE_CATEGORY_VALUE_PROPERTY(valueType, propertyGetter, propertySetter) \
- (valueType) propertyGetter { \
valueType ret = {0}; \
[objc_getAssociatedObject(self, @selector( propertyGetter )) getValue:&ret]; \
return ret; \
} \
- (void) propertySetter (valueType)value{ \
NSValue *valueObj = [NSValue valueWithBytes:&value objCType:@encode(valueType)]; \
objc_setAssociatedObject(self, @selector( propertyGetter ), valueObj, OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
}


#define FORWARD_PROPERTY(getter, setter, name, type, target) \
- (type)getter { \
return target.name;\
}\
- (void)setter(type)name {\
target.name = name;\
}\


#define GU_ERROR NSLog

#endif /* GUDefines_h */
