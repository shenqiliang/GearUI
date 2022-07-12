//
//  NBCentral.m
//  NSCentralApp
//
//  Created by 谌启亮 on 2017/7/15.
//  Copyright © 2017年 谌启亮. All rights reserved.
//

#import "NBCentral.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define CHARACTERISTIC_UUID_P2C @"D80B251F-413E-42B2-9E59-C6D128C5D856"
#define CHARACTERISTIC_UUID_C2P @"43E71349-E572-4019-AC49-BF478D3C5926"
//#define _serviceUUID @"C46CC2FB-CD5D-4670-BB0C-0473C36BFA49"
//#define CHARACTERISTIC_UUID @"E8E8CDAB-2710-4F8C-9BBA-1E8565346325"

#define MTU 20


@interface NBCentral () <CBCentralManagerDelegate, CBPeripheralDelegate>

@end


@implementation NBCentral
{
    CBCentralManager *_centralManager;
    CBPeripheral *_connectedPeripheral;
    CBPeripheral *_retryPeripheral;
    CBCharacteristic *_p2cCharacteristic;
    CBCharacteristic *_c2pCharacteristic;
    NSMutableArray *_writeChucks;
    NSMutableData *_receiveBuff;
    NSString *_serviceUUID;
}

- (void)dealloc {
    
}

- (instancetype)initWithUUID:(NSString *)uuid
{
    self = [super init];
    if (self) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        
        _writeChucks = [NSMutableArray array];
        
        _receiveBuff = [NSMutableData data];
        _serviceUUID = uuid;
    }
    return self;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (_centralManager.state) {
        case CBManagerStatePoweredOn:
            [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:_serviceUUID]] options:nil];
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"CBManagerStatePoweredOff");
            break;
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    if (_connectedPeripheral == nil) {
        _connectedPeripheral = peripheral;
        [_centralManager connectPeripheral:peripheral options:nil];
        [_centralManager stopScan];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"did connect %@", peripheral.name);
    _connectedPeripheral.delegate = self;
    [_centralManager stopScan];
    [_connectedPeripheral discoverServices:@[[CBUUID UUIDWithString:_serviceUUID]]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"didDiscoverServices %@", error);
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:_serviceUUID]]) {
            [_connectedPeripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CHARACTERISTIC_UUID_P2C], [CBUUID UUIDWithString:CHARACTERISTIC_UUID_C2P]] forService:service];
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"didDiscoverCharacteristicsForService %@", error);
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_UUID_P2C]]) {
            _p2cCharacteristic = characteristic;
            [_connectedPeripheral setNotifyValue:YES forCharacteristic:_p2cCharacteristic];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_UUID_C2P]]) {
            _c2pCharacteristic = characteristic;
        }
    }
    //[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(heartBeat) userInfo:nil repeats:YES];
}

- (void)heartBeat {
    [_connectedPeripheral writeValue:[@"SS" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:_p2cCharacteristic type:CBCharacteristicWriteWithResponse];
    [_connectedPeripheral writeValue:[@"SS" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:_c2pCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (memcmp(characteristic.value.bytes, "BOM", 3) == 0) {
        [_receiveBuff setLength:0];
    }
    else if (memcmp(characteristic.value.bytes, "EOM", 3) == 0) {
        [_connectedPeripheral writeValue:[@"ACK" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:_p2cCharacteristic type:CBCharacteristicWriteWithResponse];
        [_delegate central:self didReceiveData:[_receiveBuff copy]];
    }
    else {
        [_receiveBuff appendData:characteristic.value];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"disconnect %@", error);
    if (_connectedPeripheral == peripheral) {
        _retryPeripheral = _connectedPeripheral;
        _connectedPeripheral = nil;
        _p2cCharacteristic = nil;
        _c2pCharacteristic = nil;
        [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:_serviceUUID]] options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"didFailToConnectPeripheral %@", error);
    _retryPeripheral = nil;
    [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:_serviceUUID]] options:nil];
}

- (void)writeData:(NSData *)data {
    NSUInteger loc = 0;
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

- (void)sendData {
    if (_c2pCharacteristic == nil) {
        return;
    }
    if ([_writeChucks count] > 0) {
        [_connectedPeripheral writeValue:[_writeChucks firstObject] forCharacteristic:_c2pCharacteristic type:CBCharacteristicWriteWithResponse];
        [_writeChucks removeObjectAtIndex:0];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (characteristic == _c2pCharacteristic) {
        [self sendData];
    }
}

@end
