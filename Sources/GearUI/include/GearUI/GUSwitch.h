//
//  GUSwitch.h
//  GearUI
//
//  Created by 谌启亮 on 09/03/2018.
//  Copyright © 2018 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUNodeViewProtocol.h"

@interface GUSwitch : UISwitch <GUNodeViewProtocol>

/// 响应方法名
@property (nonatomic, strong) NSString *action;

@end
