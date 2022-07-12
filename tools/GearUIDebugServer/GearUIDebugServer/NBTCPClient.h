//
//  NBTCPClient.h
//  GearUIDebugServer
//
//  Created by 谌启亮 on 24/07/2017.
//  Copyright © 2017 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *NBTCPClientDidChangeConnectionStatusNotification;

@class NBTCPClient;

@protocol NBTCPClientDelegate <NSObject>

- (void)client:(NBTCPClient *)client didReceivedData:(NSData *)data;

@end

@interface NBTCPClient : NSObject

- (instancetype)initWithPort:(int)port;

- (void)writeData:(NSData *)data;

@property(nonatomic, strong) id<NBTCPClientDelegate> delegate;

@property(nonatomic, readonly) BOOL isConnected;

@end
