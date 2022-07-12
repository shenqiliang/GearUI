//
//  GUConfigure+Private.h
//  GearUI
//
//  Created by 谌启亮 on 13/10/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <GearUI/GearUI.h>

@interface GUConfigure ()

- (Class)classOfNodeName:(NSString *)nodeName;
- (NSDictionary *)defaultAttributesForNodeName:(NSString *)nodeName;

@end
