//
//  NBTCPClient.m
//  GearUIDebugServer
//
//  Created by 谌启亮 on 24/07/2017.
//  Copyright © 2017 Tencent. All rights reserved.
//

#import "NBTCPClient.h"
#import "GCDAsyncSocket.h"

NSString *NBTCPClientDidChangeConnectionStatusNotification = @"NBTCPClientDidChangeConnectionStatusNotification";

@interface NBTCPClient () <GCDAsyncSocketDelegate>

@end

@implementation NBTCPClient
{
    GCDAsyncSocket *_socket;
    int _port;
    BOOL _didReceivedData;
}

- (instancetype)init {
    return [self initWithPort:6783];
}

- (instancetype)initWithPort:(int)port
{
    self = [super init];
    if (self) {
        _port = port;
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self connect];
    }
    return self;
}

- (void)connect {
    if(!_socket.isConnected && ![_socket connectToHost:@"127.0.0.1" onPort:_port error:nil]) {
        __weak id weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf connect];
        });
    }
}

- (BOOL)isConnected {
    return _socket.isConnected && _didReceivedData;
}

- (void)writeData:(NSData *)data {
    uint32_t len = htonl([data length]);
    [_socket writeData:[NSData dataWithBytes:&len length:sizeof(len)] withTimeout:30 tag:0];
    [_socket writeData:data withTimeout:30 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [_socket readDataToLength:sizeof(uint32_t) withTimeout:30 tag:'leng'];
    [[NSNotificationCenter defaultCenter] postNotificationName:NBTCPClientDidChangeConnectionStatusNotification object:self];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    [self performSelector:@selector(connect) withObject:nil afterDelay:1];
    [[NSNotificationCenter defaultCenter] postNotificationName:NBTCPClientDidChangeConnectionStatusNotification object:self];
    _didReceivedData = NO;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    _didReceivedData = YES;
    if (tag == 'leng') {
        uint32_t len = *((uint32_t *)[data bytes]);
        len = ntohl(len);
        [_socket readDataToLength:len withTimeout:30 tag:'data'];
    }
    else if (tag == 'data') {
        [_delegate client:self didReceivedData:data];
        [_socket readDataToLength:sizeof(uint32_t) withTimeout:30 tag:'leng'];
    }
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    return 100;
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    return 100;
}

@end
