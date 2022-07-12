//
//  GUDebugSession.m
//  GearUI
//
//  Created by 谌启亮 on 11/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUDebugSession.h"
#import "GUDebugSession_Private.h"
#import "GUNode.h"
#import "GUXMLParser.h"

@interface GUNode()
- (GUNode *)_expandFileNode;
@end

@implementation GUDebugSession
{
    NSString *_xml;
}

- (instancetype)initWithName:(NSString *)name node:(GUNode *)node
{
    self = [super init];
    if (self) {
        _name = name;
        _relatedFileNames = [NSMutableArray array];
        [self updateRelatedFileNamesFromNode:node];
    }
    return self;
}

- (void)updateRelatedFileNamesFromNode:(GUNode *)node {
    if (node.loadedFileName != nil) {
        [self.relatedFileNames addObject:node.loadedFileName];
    }
    for (GUNode *subNode in node.subNodes) {
        [self updateRelatedFileNamesFromNode:subNode];
    }
}

- (void)setException:(NSException *)exception{
    [_delegate session:self didCatchException:exception];
}

- (void)updateWithString:(NSString *)string {
    GUXMLParser *parser = [GUXMLParser new];
    @try {
        [parser parserForXMLString:string];
    } @catch (NSException *exception) {
        [self setException:exception];
    }
    GUNode *node = [parser.rootNode _expandFileNode];
    [self.relatedFileNames removeAllObjects];
    [self updateRelatedFileNamesFromNode:node];
    if (node) {
        [_delegate session:self didUpdateNode:node];
    }
}

- (void)updateForReletedFileNames {
    GUNode *node = [GUNode nodeWithFileName:_name];
    [self.relatedFileNames removeAllObjects];
    [self updateRelatedFileNamesFromNode:node];
    if (node) {
        [_delegate session:self didUpdateNode:node];
    }
}

@end
