//
//  GUAnimation+GUPrivate.h
//  GearUI
//
//  Created by 谌启亮 on 07/09/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUAnimation.h"
#import "GULayoutView.h"

@interface GUAnimation () <CAAnimationDelegate>

@property (nonatomic, weak) GULayoutView *layoutView;

@end
