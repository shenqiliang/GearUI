//
//  UIResponder+GearUI.m
//  GearUI
//
//  Created by 谌启亮 on 01/11/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "UIResponder+GearUI.h"

__weak static UIResponder *firstResponder = nil;

@implementation UIResponder (GearUI)

+ (UIResponder *)gu_firstResponder{
    firstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(gu_findFirstResponderAction:) to:nil from:nil forEvent:nil];
    return firstResponder;
}

- (void)gu_findFirstResponderAction:(id)sender {
    firstResponder = self;
}

@end
