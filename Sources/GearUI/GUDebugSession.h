//
//  GUDebugSession.h
//  GearUI
//
//  Created by 谌启亮 on 11/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>
@class GUDebugSession, GUNode;

@protocol GUDebugSessionDelegate <NSObject>

- (void)session:(id)session didUpdateNode:(GUNode *)node;
- (void)session:(id)session didCatchException:(NSException *)exception;

@end

@interface GUDebugSession : NSObject

@property (nonatomic, weak) id<GUDebugSessionDelegate> delegate;
- (instancetype)initWithName:(NSString *)name node:(GUNode *)node;
- (void)setException:(NSException *)exception;
@end
