//
//  GUVisualEffectView.m
//  GearUI
//
//  Created by 谌启亮 on 24/10/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUVisualEffectView.h"
#import "GULayoutView.h"
#import "GUNode.h"
#import "NSObject+GUPrivate.h"

@interface GUVisualEffectView()<GUNodeProtocol>

@property (nonatomic, strong) GULayoutView *layoutView;

@end

@implementation GUVisualEffectView


- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _layoutView = [[GULayoutView alloc] initWithFrame:self.contentView.bounds];
        _layoutView.backgroundColor = [UIColor clearColor];
        _layoutView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_layoutView];
        [_layoutView setAttribute:@"0" forKeyPath:@"top"];
        [_layoutView setAttribute:@"0" forKeyPath:@"left"];
        [_layoutView setAttribute:@"0" forKeyPath:@"right"];
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:_layoutView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        bottomConstraint.priority = UILayoutPriorityDefaultLow;
        [self.contentView addConstraint:bottomConstraint];
    }
    return self;
}

- (void)setEffect:(id)effect {
    if ([effect isKindOfClass:[NSString class]]) {
        if ([effect isEqualToString:@"darkBlur"]) {
            effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        }
        else if ([effect isEqualToString:@"lightBlur"]) {
            effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        }
    }
    [super setEffect:effect];
}
#pragma mark - GUNodeProtocol ====
/**
 根据子对象更新视图
 
 @param children 子对象
 */
- (void)updateChildren:(NSArray *)children
{
    [_layoutView updateChildren:children];
    [self gu_bindPropertyForSubClassOf:[GUVisualEffectView class]];
}

- (UIView<GUNodeViewProtocol> *)viewWithNodeId:(NSString *)nodeId {
    return [_layoutView viewWithNodeId:nodeId];
}

@end
