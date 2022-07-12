//
//  NBPeripheral.m
//  NBPeripheralApp
//
//  Created by 谌启亮 on 2017/7/14.
//  Copyright © 2017年 谌启亮. All rights reserved.
//

#import "NBPeripheral.h"
#import <CoreBluetooth/CoreBluetooth.h>

//#define SERVICE_UUID @"06BD"
//#define CHARACTERISTIC_UUID @"9C0F602C"
//#define SERVICE_UUID @"C46CC2FB-CD5D-4670-BB0C-0473C36BFA49"
//#define CHARACTERISTIC_UUID @"E8E8CDAB-2710-4F8C-9BBA-1E8565346325"
#define CHARACTERISTIC_UUID_P2C @"D80B251F-413E-42B2-9E59-C6D128C5D856"
#define CHARACTERISTIC_UUID_C2P @"43E71349-E572-4019-AC49-BF478D3C5926"
#define MTU 20

@interface NBPeripheral () <CBPeripheralManagerDelegate>

@end

@implementation NBPeripheral
{
    CBMutableService *_service;
    CBMutableCharacteristic *_p2cCharacteristic;
    CBMutableCharacteristic *_c2pCharacteristic;
    CBPeripheralManager *_peripheralManager;
    CBCentral *_connectedCentral;
    NSMutableArray *_writeChucks;
    NSMutableData *_receiveBuff;
    NSMutableArray *_cachedSendData;
    BOOL _isWaitingResp;
    NSString *_serviceUUID;
}

- (instancetype)initWithUUID:(NSString *)uuid
{
    self = [super init];
    if (self) {
        _p2cCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:CHARACTERISTIC_UUID_P2C] properties:CBCharacteristicPropertyRead|CBCharacteristicPropertyWrite|CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable|CBAttributePermissionsWriteable];
        _c2pCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:CHARACTERISTIC_UUID_C2P] properties:CBCharacteristicPropertyRead|CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsReadable|CBAttributePermissionsWriteable];
        _service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:uuid] primary:YES];
        _service.characteristics = @[_p2cCharacteristic, _c2pCharacteristic];
        
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        
        _writeChucks = [NSMutableArray array];
        //[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(heartBeat) userInfo:nil repeats:YES];
        
        _receiveBuff = [NSMutableData data];
        _cachedSendData = [NSMutableArray array];
        
        _serviceUUID = uuid;
        
    }
    return self;
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    switch (_peripheralManager.state) {
        case CBPeripheralManagerStatePoweredOn:
            [_peripheralManager addService:_service];
            break;
        default:
            NSLog(@"changed to other state");
            break;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (error == nil) {
        [_peripheralManager startAdvertising:@{CBAdvertisementDataLocalNameKey:@"NBPeripheral", CBAdvertisementDataServiceUUIDsKey:@[[CBUUID UUIDWithString:_serviceUUID]]}];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"didSubscribeToCharacteristic");
    if ([_p2cCharacteristic isEqual:characteristic]) {
        if (_connectedCentral == nil) {
            _connectedCentral = central;
            if ([_cachedSendData count]) {
                [_writeChucks replaceObjectsInRange:NSMakeRange(0, 0) withObjectsFromArray:_cachedSendData];
            }
            _isWaitingResp = NO;
            [self sendData];
        }
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"didUnsubscribeFromCharacteristic");
    if (_connectedCentral == central) {
        _connectedCentral = nil;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {
    for (CBATTRequest *request in requests) {
        if (request.characteristic == _c2pCharacteristic) {
            if (memcmp(request.value.bytes, "EOM", 3) == 0) {
                [_delegate peripheral:self didReceivedData:[_receiveBuff copy]];
                [_receiveBuff setLength:0];
            }
            else {
                [_receiveBuff appendData:request.value];
            }
        }
        else if (request.characteristic == _p2cCharacteristic) {
            if (memcmp(request.value.bytes, "ACK", 3) == 0) {
                _isWaitingResp = NO;
                [_cachedSendData removeAllObjects];
                [self sendData];
            }
        }
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

- (void)sendData {
    if (_connectedCentral == nil) {
        NSLog(@"_connectedCentral = nil");
        return;
    }
    if (_isWaitingResp) {
        NSLog(@"_isWaitingResp");
        return;
    }
    NSLog(@"sendData");
    while ([_writeChucks count] > 0) {
        NSData *data = [_writeChucks firstObject];
        if ([_peripheralManager updateValue:data forCharacteristic:_p2cCharacteristic onSubscribedCentrals:nil]) {
            [_writeChucks removeObjectAtIndex:0];
            [_cachedSendData addObject:data];
            if (memcmp(data.bytes, "EOM", 3) == 0) {
                _isWaitingResp = YES;
            }
        }
        else {
            break;
        }
    }
}

- (void)heartBeat {
    if (_connectedCentral && _p2cCharacteristic && _c2pCharacteristic) {
        [_peripheralManager updateValue:[@"SS" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:_p2cCharacteristic onSubscribedCentrals:@[_connectedCentral]];
        [_peripheralManager updateValue:[@"SS" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:_c2pCharacteristic onSubscribedCentrals:@[_connectedCentral]];
    }
}

- (void)writeData:(NSData *)data {
    NSUInteger loc = 0;
    [_writeChucks addObject:[@"BOM" dataUsingEncoding:NSUTF8StringEncoding]];
    while (loc + MTU < [data length]) {
        [_writeChucks addObject:[data subdataWithRange:NSMakeRange(loc, MTU)]];
        loc += MTU;
    }
    if (loc < [data length]) {
        [_writeChucks addObject:[data subdataWithRange:NSMakeRange(loc, [data length] - loc)]];
    }
    [_writeChucks addObject:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding]];
    [self sendData];
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    [self sendData];
}


@end
