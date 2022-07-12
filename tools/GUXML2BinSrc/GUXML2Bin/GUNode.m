//
//  GUNode.m
//  GUXML2Bin
//
//  Created by 谌启亮 on 03/04/2018.
//  Copyright © 2018 谌启亮. All rights reserved.
//

#import "GUNode.h"

@implementation GUNode

- (BOOL)isEqual:(GUNode *)object {
    if ([object isKindOfClass:[GUNode class]]) {
        BOOL ret = (object.nodeId == _nodeId || [object.nodeId isEqual:_nodeId]) && (object.name == _name || [object.name isEqual:_name]) && (object.content == _content || [object.content isEqual:_content]) && ([object.attributes isEqual:_attributes] || ([object.attributes count] == 0 && [_attributes count] == 0)) && ([object.subNodes isEqualToArray:_subNodes] || ([object.subNodes count] == 0 && [_subNodes count] == 0));
        return ret;
    }
    return NO;
}

@end
