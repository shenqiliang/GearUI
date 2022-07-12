//
//  GULog.m
//  GearUI
//
//  Created by 谌启亮 on 29/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GULog.h"

void __GUFail(char *file, int line, NSString *format, ...){
    va_list v;
    va_start(v, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:v];
    NSString *filePath = [NSString stringWithUTF8String:file];
    NSString *finalMessage = [NSString stringWithFormat:@"%@:%d %@", [filePath lastPathComponent], line, message];
    va_end(v);
    NSLog(@"%@", finalMessage);
}

void __GUError(char *file, int line, NSString *format, ...){
    va_list v;
    va_start(v, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:v];
    NSString *filePath = [NSString stringWithUTF8String:file];
    NSString *finalMessage = [NSString stringWithFormat:@"%@:%d %@", [filePath lastPathComponent], line, message];
    va_end(v);
    NSLog(@"%@", finalMessage);
}

void __GUWarn(char *file, int line, NSString *format, ...){
    va_list v;
    va_start(v, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:v];
    NSString *filePath = [NSString stringWithUTF8String:file];
    NSString *finalMessage = [NSString stringWithFormat:@"%@:%d %@", [filePath lastPathComponent], line, message];
    va_end(v);
    NSLog(@"%@", finalMessage);
}

void __GUDebug(char *file, int line, NSString *format, ...){
    va_list v;
    va_start(v, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:v];
    NSString *filePath = [NSString stringWithUTF8String:file];
    NSString *finalMessage = [NSString stringWithFormat:@"%@:%d %@", [filePath lastPathComponent], line, message];
    va_end(v);
    NSLog(@"%@", finalMessage);
}
