//
//  GUDeviceManager.h
//  GearUIDebugServer
//
//  Created by 谌启亮 on 14/12/2017.
//  Copyright © 2017 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GUDevice.h"

@interface GUDeviceManager : NSObject

@property (class, nonatomic, strong) GUDeviceManager *manger;

- (void)startMonitor;

@property (nonatomic, strong) NSArray<GUDevice *> *devices;

@end
