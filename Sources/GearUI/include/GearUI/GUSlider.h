//
//  GUSlider.h
//  GearUI
//
//  Created by 谌启亮 on 16/11/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>

// Slider控件，提供更多控制
@interface GUSlider : UISlider

@property (nonatomic, assign) CGFloat trackHeight; // 中间滑动条的大小

@property (nonatomic, strong) UIImage *thumbImage;

@end
