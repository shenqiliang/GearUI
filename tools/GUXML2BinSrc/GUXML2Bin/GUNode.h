//
//  GUNode.h
//  GUXML2Bin
//
//  Created by 谌启亮 on 03/04/2018.
//  Copyright © 2018 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GUNode : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *nodeId;

@property (nonatomic, strong) NSArray<GUNode *> *subNodes;

@property (nonatomic, strong) NSDictionary *attributes;
@property (nonatomic, strong) NSString *content;

@end
