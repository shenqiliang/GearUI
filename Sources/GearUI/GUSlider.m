//
//  GUSlider.m
//  GearUI
//
//  Created by 谌启亮 on 16/11/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUSlider.h"

@implementation GUSlider

- (CGRect)trackRectForBounds:(CGRect)bounds {
    CGRect rect = [super trackRectForBounds:bounds];
    if (self.trackHeight > 0 && self.trackHeight < bounds.size.height) {
        rect.size.height = self.trackHeight;
        rect.origin.y = (bounds.size.height - rect.size.height) / 2;
    }
    return rect;
}

- (void)setThumbImage:(UIImage *)thumbImage {
    [self setThumbImage:thumbImage forState:UIControlStateNormal];
    [self setThumbImage:thumbImage forState:UIControlStateHighlighted];
}

- (UIImage *)thumbImage {
    return [self thumbImageForState:UIControlStateNormal];
}

@end
