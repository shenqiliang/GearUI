//
//  GULayoutConstraint.m
//  GearUI
//
//  Created by 谌启亮 on 29/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GULayoutConstraint.h"
#import "UIView+GULayout.h"

@implementation GULayoutConstraint


- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@.%@=\"%@\">", [super description], self.firstNodeId, NSStringFromLayoutAttribute(self.firstAttribute), self.attributeString];
    
}

@end
