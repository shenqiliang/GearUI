//
//  UIView+GUAttribute.m
//  GearUI
//
//  Created by 谌启亮 on 03/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "UIView+GUAttribute.h"
#import "GUDefines.h"

@implementation UIView (GUAttribute)
@dynamic disableLayout;

FORWARD_PROPERTY(shadowOpacity, setShadowOpacity:, shadowOpacity, float, self.layer)
FORWARD_PROPERTY(shadowOffset, setShadowOffset:, shadowOffset, CGSize, self.layer)
FORWARD_PROPERTY(shadowRadius, setShadowRadius:, shadowRadius, CGFloat, self.layer)

- (CGFloat)cornerRadius{
    return self.layer.cornerRadius;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.clipsToBounds = YES;
    self.layer.cornerRadius = cornerRadius;
}

- (CGFloat)borderWidth {
    return self.layer.borderWidth;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    self.layer.borderWidth = borderWidth;
}

- (void)setBorderColor:(UIColor *)borderColor {
    self.layer.borderColor = borderColor.CGColor;
}

- (UIColor *)borderColor {
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

- (void)setShadowColor:(UIColor *)shadowColor{
    self.layer.shadowColor = shadowColor.CGColor;
}

- (CACornerMask)maskedCorners {
    if (@available(iOS 11.0, *)) {
        return self.layer.maskedCorners;
    } else {
        // Fallback on earlier versions
        return 0;
    }
}

- (void)setMaskedCorners:(CACornerMask)maskedCorners {
    if (@available(iOS 11.0, *)) {
        self.layer.maskedCorners = maskedCorners;
    } else {
        // Fallback on earlier versions
    }
}

- (UIColor *)shadowColor {
    return [UIColor colorWithCGColor:self.layer.shadowColor];
}

- (void)setContentHuggingPriorityHorizontal:(UILayoutPriority)contentHuggingPriorityHorizontal {
    [self setContentHuggingPriority:contentHuggingPriorityHorizontal forAxis:UILayoutConstraintAxisHorizontal];
}

- (void)setContentHuggingPriorityVertical:(UILayoutPriority)contentHuggingPriorityVertical {
    [self setContentHuggingPriority:contentHuggingPriorityVertical forAxis:UILayoutConstraintAxisVertical];
}

- (UILayoutPriority)contentHuggingPriorityHorizontal {
    return [self contentHuggingPriorityForAxis:UILayoutConstraintAxisHorizontal];
}

- (UILayoutPriority)contentHuggingPriorityVertical {
    return [self contentHuggingPriorityForAxis:UILayoutConstraintAxisVertical];
}

- (void)setContentCompressionResistancePriorityHorizontal:(UILayoutPriority)contentCompressionResistancePriorityHorizontal {
    [self setContentCompressionResistancePriority:contentCompressionResistancePriorityHorizontal forAxis:UILayoutConstraintAxisHorizontal];
}

- (void)setContentCompressionResistancePriorityVertical:(UILayoutPriority)contentCompressionResistancePriorityVertical {
    [self setContentCompressionResistancePriority:contentCompressionResistancePriorityVertical forAxis:UILayoutConstraintAxisVertical];
}

- (UILayoutPriority)contentCompressionResistancePriorityHorizontal {
    return [self contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisHorizontal];
}

- (UILayoutPriority)contentCompressionResistancePriorityVertical {
    return [self contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisVertical];
}

- (void)setZPosition:(CGFloat)zPosition {
    self.layer.zPosition = zPosition;
}

- (CGFloat)zPosition {
    return self.layer.zPosition;
}

@end
