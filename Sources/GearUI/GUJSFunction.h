//
//  GUJSValue.h
//  GearUI
//
//  Created by 谌启亮 on 14/12/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>

@interface GUJSFunction : NSObject

@property(nonatomic, assign) JSValueRef functionJSValue;
@property(nonatomic, assign) JSObjectRef functionJSObject;
@property(nonatomic, assign) JSContextRef jsContext;

- (void)doNothing;

@end
