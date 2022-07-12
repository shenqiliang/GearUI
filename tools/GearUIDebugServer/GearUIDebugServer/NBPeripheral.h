//
//  NBPeripheral.h
//  NBPeripheralApp
//
//  Created by 谌启亮 on 2017/7/14.
//  Copyright © 2017年 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NBPeripheral;

@protocol NBPeripheralDelegate <NSObject>

- (void)peripheral:(NBPeripheral *)peripheral didReceivedData:(NSData *)data;

@end

@interface NBPeripheral : NSObject

- (instancetype)initWithUUID:(NSString *)uuid;

- (void)writeData:(NSData *)data;

@property (nonatomic, strong) id<NBPeripheralDelegate> delegate;

@end
