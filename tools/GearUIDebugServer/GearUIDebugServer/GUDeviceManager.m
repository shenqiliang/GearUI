//
//  GUDeviceManager.m
//  GearUIDebugServer
//
//  Created by 谌启亮 on 14/12/2017.
//  Copyright © 2017 Tencent. All rights reserved.
//

#import "GUDeviceManager.h"
#import "mobiledevice.h"
#import <dlfcn.h>

@interface GUDeviceManager ()
- (void)handleDeviceNotification:(struct am_device_notification_callback_info *)info;
@end
static void device_on_device(struct am_device_notification_callback_info *info, int cookie)
{
    [GUDeviceManager.manger handleDeviceNotification:info];
}


@implementation GUDeviceManager
{
    struct am_device_notification *device_notification;
}

+ (GUDeviceManager *)manager{
    static GUDeviceManager *g_GUDeviceManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_GUDeviceManager = [GUDeviceManager new];
    });
    return g_GUDeviceManager;
}

- (void)handleDeviceNotification:(struct am_device_notification_callback_info *)info {
    if (info->msg == ADNCI_MSG_CONNECTED)
    {
        NSString *deviceId = CFBridgingRelease(AMDeviceCopyDeviceIdentifier(info->dev));
        AMDeviceConnect(info->dev);
        NSString *osVersion = AMDeviceCopyValue(info->dev, NULL, CFSTR("ProductVersion"));
        NSString *deviceName = AMDeviceCopyValue(info->dev, NULL, CFSTR("DeviceName"));
    }
    else if (info->msg == ADNCI_MSG_DISCONNECTED)
    {
        NSLog(@"did disconnect");
    }
}

- (void)startMonitor {
    AMDeviceNotificationSubscribe(&device_on_device, 0, 0, (int)self, &device_notification);
}

- (void)stopMonitor {
    AMDeviceNotificationUnsubscribe(device_notification);
}

@end
