#!/bin/sh

#  get_device.sh
#  GearUIDebugServer
#
#  Created by 谌启亮 on 11/07/2017.
#  Copyright © 2017 Tencent. All rights reserved.
instruments -s devices | grep `system_profiler SPUSBDataType | sed -n -E -e '/(iPhone|iPad)/,/Serial/s/ *Serial Number: *(.+)/\1/p'`
