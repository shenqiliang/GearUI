//
//  GULog.m
//  GearUI
//
//  Created by 谌启亮 on 29/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GULog.h"
#import "GUConfigure.h"

void __GUFail(char *file, int line, NSString *format, ...){
    va_list v;
    va_start(v, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:v];
    NSString *filePath = [NSString stringWithUTF8String:file];
    NSString *finalMessage = [NSString stringWithFormat:@"%@:%d %@", [filePath lastPathComponent], line, message];
    va_end(v);
    if ([GUConfigure sharedInstance].logHandleDelegate) {
        [[GUConfigure sharedInstance].logHandleDelegate fail:finalMessage];
    }
    else {
        NSLog(@"%@", finalMessage);
    }
    @throw [NSException exceptionWithName:@"GearUIFatalException" reason:message userInfo:nil];
}

void __GUError(char *file, int line, NSString *format, ...){
    va_list v;
    va_start(v, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:v];
    NSString *filePath = [NSString stringWithUTF8String:file];
    NSString *finalMessage = [NSString stringWithFormat:@"%@:%d %@", [filePath lastPathComponent], line, message];
    va_end(v);
    if ([GUConfigure sharedInstance].logHandleDelegate) {
        [[GUConfigure sharedInstance].logHandleDelegate error:finalMessage];
    }
    else {
        NSLog(@"%@", finalMessage);
    }
#if DEBUG
    @throw [NSException exceptionWithName:@"GearUIFatalException" reason:message userInfo:nil];
#endif
}

void __GUWarn(char *file, int line, NSString *format, ...){
    va_list v;
    va_start(v, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:v];
    NSString *filePath = [NSString stringWithUTF8String:file];
    NSString *finalMessage = [NSString stringWithFormat:@"%@:%d %@", [filePath lastPathComponent], line, message];
    va_end(v);
    if ([GUConfigure sharedInstance].logHandleDelegate) {
        [[GUConfigure sharedInstance].logHandleDelegate warning:finalMessage];
    }
    else {
        NSLog(@"%@", finalMessage);
    }
}

void __GUDebug(char *file, int line, NSString *format, ...){
    va_list v;
    va_start(v, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:v];
    NSString *filePath = [NSString stringWithUTF8String:file];
    NSString *finalMessage = [NSString stringWithFormat:@"%@:%d %@", [filePath lastPathComponent], line, message];
    va_end(v);
    if ([GUConfigure sharedInstance].logHandleDelegate) {
        [[GUConfigure sharedInstance].logHandleDelegate debug:finalMessage];
    }
    else {
        NSLog(@"%@", finalMessage);
    }
}
