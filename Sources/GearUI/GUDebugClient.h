//
//  GUDebugClinet.h
//  GearUI
//
//  Created by 谌启亮 on 11/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>
@class GUDebugSession;

@interface GUDebugClient : NSObject
+ (instancetype)client;
- (void)start;

- (void)addSession:(GUDebugSession *)session;
- (void)removeSession:(GUDebugSession *)session;

- (NSString *)cachedDataForFileName:(NSString *)fileName;

@end
