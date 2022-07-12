//
//  NBTCPServer.m
//  GearUI
//
//  Created by 谌启亮 on 24/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "NBTCPServer.h"
#import "GCDAsyncSocket.h"

@interface NBTCPServer () <GCDAsyncSocketDelegate>

@end

@implementation NBTCPServer
{
    GCDAsyncSocket *_serverSocket;
    GCDAsyncSocket *_socket;
}

- (instancetype)init
{
    return [self initWithPort:6783];
}

- (instancetype)initWithPort:(int)port
{
    self = [super init];
    if (self) {
        _serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_serverSocket acceptOnPort:port error:nil];
    }
    return self;
}

- (void)writeData:(NSData *)data {
    uint32_t len = htonl([data length]);
    [_socket writeData:[NSData dataWithBytes:&len length:sizeof(len)] withTimeout:30 tag:0];
    [_socket writeData:data withTimeout:30 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"accept");
    _socket = newSocket;
    [_delegate serverDidConnect:self];
    self.isConnected = YES;
    [_socket readDataToLength:sizeof(uint32_t) withTimeout:30 tag:'leng'];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    if (_socket == sock) {
        self.isConnected = NO;
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (tag == 'leng') {
        uint32_t len = *((uint32_t *)[data bytes]);
        len = ntohl(len);
        [_socket readDataToLength:len withTimeout:30 tag:'data'];
    }
    else if (tag == 'data') {
        [_delegate server:self didReceiveData:data];
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
