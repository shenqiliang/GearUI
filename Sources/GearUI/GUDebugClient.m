//
//  GUDebugClinet.m
//  GearUI
//
//  Created by 谌启亮 on 11/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUDebugClient.h"
#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "GUDebugSession_Private.h"
#import "NBCentral.h"
#import "NBTCPServer.h"
#import "GULog.h"

#define MTU 30

NSString *const GUServiceUUIDString = @"F5EEC0AE-25F0-495F-999B-E7F36C9CB9A8";
NSString *const GUSessionCharacteristic = @"B2E12CD5-F30B-43C3-AA50-57DFF633CD1C";
NSString *const GUDataCharacteristic = @"1A9C3B00-9C46-435D-97C6-5DDC9F208EB3";

@interface GUDebugClient () <NBTCPServerDelegate>

@end

@implementation GUDebugClient
{
    NBTCPServer *_server;
    NSMutableArray *_sessions;
    NSCache *_fileCache;
    NSTimer *_heartBeatTimer;
}

+ (instancetype)client {
    static GUDebugClient *g_client = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_client = [GUDebugClient new];
    });
    return g_client;
}

- (void)start {
    GUDebug(@"GUDebugClinet start");
#if TARGET_IPHONE_SIMULATOR
    _server = [[NBTCPServer alloc] initWithPort:6785];
#else
    _server = [[NBTCPServer alloc] init];
#endif
    _server.delegate = self;
    _sessions = [NSMutableArray array];
    _fileCache = [NSCache new];
}

- (NSString *)cachedDataForFileName:(NSString *)fileName {
    return [_fileCache objectForKey:fileName];
}

- (void)updateSessionValue {
    NSMutableSet *sessionNames = [NSMutableSet set];
    for (GUDebugSession *session in _sessions) {
        [sessionNames addObject:session.name];
        [sessionNames addObjectsFromArray:session.relatedFileNames];
    }
    NSString *value = [[sessionNames allObjects] componentsJoinedByString:@"|"];
    [_server writeData:[value dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)serverDidConnect:(NBTCPServer *)server {
    [_server writeData:[@"ACK" dataUsingEncoding:NSUTF8StringEncoding]];
    [self updateSessionValue];
}

- (void)server:(NBTCPServer *)server didReceiveData:(NSData *)data {
    NSString *receivedBuff = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"received %@", receivedBuff);
    NSRange sepRange = [receivedBuff rangeOfString:@":"];
    if (sepRange.location != NSNotFound) {
        NSString *key = [receivedBuff substringToIndex:sepRange.location];
        NSString *value = [receivedBuff substringFromIndex:sepRange.location+1];
        [_fileCache setObject:value forKey:key];
        for (GUDebugSession *session in [_sessions copy]) {
            if ([session.name isEqualToString:key]) {
                @try {
                    [session updateWithString:value];
                } @catch (NSException *exception) {
                    [session setException:exception];
                } @finally {
                    
                }
            }
            else if ([session.relatedFileNames containsObject:key]) {
                @try {
                    [session updateForReletedFileNames];
                } @catch (NSException *exception) {
                    [session setException:exception];
                } @finally {
                    
                }
            }

        }
    }

}

- (void)addSession:(GUDebugSession *)session {
    if (_server) {
        [_sessions addObject:session];
        [self updateSessionValue];
    }
}

- (void)removeSession:(GUDebugSession *)session {
    if (_server) {
        [_sessions removeObject:session];
        [self updateSessionValue];
    }
}

@end
