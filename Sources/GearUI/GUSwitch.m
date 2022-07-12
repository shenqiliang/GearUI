//
//  GUSwitch.m
//  GearUI
//
//  Created by 谌启亮 on 09/03/2018.
//  Copyright © 2018 谌启亮. All rights reserved.
//

#import "GUSwitch.h"
#import "UIView+GUPrivate.h"

@implementation GUSwitch

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addTarget:self action:@selector(gu_valueChanged) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void)gu_valueChanged {
    if ([_action isKindOfClass:[NSString class]] && [_action length]) {
        [self gu_runAction:_action];
    }
}

@end
