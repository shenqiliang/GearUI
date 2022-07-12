//
//  NBTCPServer.h
//  GearUI
//
//  Created by 谌启亮 on 24/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NBTCPServer;

@protocol NBTCPServerDelegate <NSObject>

- (void)serverDidConnect:(NBTCPServer *)server;
- (void)server:(NBTCPServer *)server didReceiveData:(NSData *)data;

@end


@interface NBTCPServer : NSObject

- (instancetype)initWithPort:(int)port;

- (void)writeData:(NSData *)data;

@property (nonatomic, weak) id<NBTCPServerDelegate> delegate;

@property (nonatomic) BOOL isConnected;

@end
