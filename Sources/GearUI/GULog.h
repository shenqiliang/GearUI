//
//  GULog.h
//  GearUI
//
//  Created by 谌启亮 on 29/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>

void __GUFail(char *file, int line, NSString *format, ...);
void __GUError(char *file, int line, NSString *format, ...);
void __GUWarn(char *file, int line, NSString *format, ...);
void __GUDebug(char *file, int line, NSString *format, ...);

#define GUWarn(format, ...) __GUWarn(__FILE__, __LINE__, format, ##__VA_ARGS__)
#define GUError(format, ...) __GUError(__FILE__, __LINE__, format, ##__VA_ARGS__)
#define GUFail(format, ...) __GUFail(__FILE__, __LINE__, format, ##__VA_ARGS__)
#define GUDebug(format, ...) __GUDebug(__FILE__, __LINE__, format, ##__VA_ARGS__)
