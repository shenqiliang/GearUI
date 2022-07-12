//
//  GUWeakProxy.h
//  GearUI
//
//  Created by 谌启亮 on 26/12/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GUWeakProxy : NSProxy

+ (instancetype)proxyWithObject:(id)obj;

@end
