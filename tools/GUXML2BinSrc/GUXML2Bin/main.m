//
//  main.m
//  GUXML2Bin
//
//  Created by 谌启亮 on 03/04/2018.
//  Copyright © 2018 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GUXMLParser.h"
#import "GUNodeBinCoder.h"


void convertAtPath(NSString *path) {
    NSArray<NSString *> *xmlFiles = [[NSFileManager defaultManager] subpathsAtPath:path];
    for (NSString *xmlFile in xmlFiles) {
        if ([xmlFile hasSuffix:@".xml"]) {
            @try {
                NSString *filePath = [path stringByAppendingPathComponent:xmlFile];
                NSString *xmlString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
                if ([xmlString hasPrefix:@"<LayoutView"] || [xmlString hasPrefix:@"<ViewController"]) {
                    GUXMLParser *parser = [GUXMLParser new];
                    if (xmlString) {
                        [parser parserForXMLString:xmlString];
                    }
                    GUNode *rootNode = parser.rootNode;
                    if ([rootNode.name length]) {
                        NSData *binData = [GUNodeBinCoder encodeWithNode:rootNode];
                        NSString *fileName = [[xmlFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"gbi"];
                        [binData writeToFile:[path stringByAppendingPathComponent:fileName] atomically:YES];
                        [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
                    }
                }
            }
            @catch (NSException *e) {
                NSLog(@"%@", e);
            }
        }
    }
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        for (int i = 0; i < argc; i++) {
            if (strcmp(argv[i], "-p") == 0) {
                i++;
                if (i < argc) {
                    const char *path = argv[i];
                    convertAtPath([NSString stringWithUTF8String:path]);
                }
                continue;
            }
        }
    }
    return 0;
}


