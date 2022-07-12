//
//  UIView+GUNode.m
//  GearUI
//
//  Created by 谌启亮 on 16/4/16.
//  Copyright © 2016年 谌启亮. All rights reserved.
//

#import "UIView+GUPrivate.h"
#import "UIView+GULayout.h"
#import "NSObject+GUPrivate.h"
#import "GUNodeProtocol.h"
#import "GUDefines.h"
#import <objc/runtime.h>
#import "GUDefines.h"
#import "GUNodeViewDelegate.h"
#import "GUConfigure.h"
#import "GULayoutView.h"
#import "GULayoutView+Private.h"
#import "GULog.h"
#import "GULayoutConstraint.h"

@implementation UIView (GUPrivate)
@dynamic backgroundColor;

SYNTHESIZE_CATEGORY_VALUE_PROPERTY(BOOL, disableLayout, __setDisableLayout:)
SYNTHESIZE_CATEGORY_VALUE_PROPERTY(UIEdgeInsets, touchEdgeInsets, setTouchEdgeInsets:)

- (id<GUNodeViewDelegate>)nodeViewDelegate{
    return nil;
}

+ (void)load {
    Method origin = class_getInstanceMethod(self, @selector(pointInside:withEvent:));
    Method replace = class_getInstanceMethod(self, @selector(gu_pointInside:withEvent:));
    method_exchangeImplementations(origin, replace);
}


- (void)setDisableLayout:(BOOL)disableLayout{
    if (self.disableLayout != disableLayout) {
        [self __setDisableLayout:disableLayout];
        [self.gu_layoutInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSArray *constraints = obj;
            for (GULayoutConstraint *constraint in constraints) {
                if ([constraint isKindOfClass:[GULayoutConstraint class]]) {
                    constraint.priority = disableLayout ? UILayoutPriorityFittingSizeLevel : 999;
                }
            }
        }];
        [self.superview setNeedsUpdateConstraints];
    }
    self.hidden = disableLayout;
}

- (NSMutableDictionary *)gu_userInfo{
    static char gu_userInfo_key = 'a';
    NSMutableDictionary *cache = objc_getAssociatedObject(self, &gu_userInfo_key);
    if (cache == nil) {
        cache = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &gu_userInfo_key, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cache;
}

- (void)gu_setAttributeValue:(NSString *)value forName:(NSString *)name{
    NSLayoutAttribute layoutAttribute = NSLayoutAttributeFromString(name);
    if (layoutAttribute != NSLayoutAttributeNotAnAttribute) {
        [self gu_updateLayoutWithAttribute:layoutAttribute value:value];
    }
    else if ([name isEqualToString:@"tap"]) {
        NSString *tap = value;
        self.gu_userInfo[@"tap"] = value;
        if (self.gu_userInfo[@"tapGesture"]) {
            [self removeGestureRecognizer:self.gu_userInfo[@"tapGesture"]];
            [self.gu_userInfo removeObjectForKey:@"tapGesture"];
        }
        if (!([tap isEqualToString:@"false"] || [tap isEqualToString:@"0"] || [tap isEqualToString:@"no"] || [tap isEqualToString:@"n"])) {
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gu_tapGestureAction:)];
            self.gu_userInfo[@"tapGesture"] = tapGesture;
            [self addGestureRecognizer:tapGesture];
            self.userInteractionEnabled = YES;
            [self updateTapGuestureDependence];
        }
    }
    else if ([name isEqualToString:@"doubleTap"]) {
        NSString *tap = value;
        self.gu_userInfo[@"doubleTap"] = value;
        if (self.gu_userInfo[@"doubleTapGesture"]) {
            [self removeGestureRecognizer:self.gu_userInfo[@"doubleTapGesture"]];
            [self.gu_userInfo removeObjectForKey:@"doubleTap"];
        }
        if (!([tap isEqualToString:@"false"] || [tap isEqualToString:@"0"] || [tap isEqualToString:@"no"] || [tap isEqualToString:@"n"])) {
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gu_doubleTapGestureAction:)];
            tapGesture.numberOfTapsRequired = 2;
            self.gu_userInfo[@"doubleTapGesture"] = tapGesture;
            [self addGestureRecognizer:tapGesture];
            self.userInteractionEnabled = YES;
            [self updateTapGuestureDependence];
        }
    }
    else{
        [super gu_setAttributeValue:value forName:name];
    }
}

- (void)updateTapGuestureDependence {
    UITapGestureRecognizer *doubleTapGuesture = self.gu_userInfo[@"doubleTapGesture"];
    UITapGestureRecognizer *tapGuesture = self.gu_userInfo[@"tapGesture"];
    if (doubleTapGuesture != nil && tapGuesture != nil) {
        [tapGuesture requireGestureRecognizerToFail:doubleTapGuesture];
    }
}

- (BOOL)gu_pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    if (event.type == UIEventTypeTouches) {
        return CGRectContainsPoint(UIEdgeInsetsInsetRect(self.bounds, self.touchEdgeInsets), point);
    }
    else {
        return [self gu_pointInside:point withEvent:event];
    }
}

- (void)gu_runAction:(NSString *)action {
    if ([action hasPrefix:@"#"]) {
        SEL sel = NSSelectorFromString([action substringFromIndex:1]);
        UIResponder *responder = self;
        while (responder != nil) {
            if ([responder respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [responder performSelector:sel withObject:self];
#pragma clang diagnostic pop
                return;
            }
            else {
                responder = responder.nextResponder;
            }
        }
        GUWarn(@"Unhandled action %@ of nodeId %@", action, self.nodeId);
    }
    else if ([action hasPrefix:@"js:"]) {
        NSString *jsCode = [action substringFromIndex:3];
        UIView *view = self;
        while (view != nil) {
            if ([view isKindOfClass:[GULayoutView class]] && [(GULayoutView *)view __runJavaScript:jsCode]) {
                break;
            }
            view = view.superview;
        }
    }
    else {
        NSURL *actionURL = [NSURL URLWithString:action];
        if (actionURL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([[GUConfigure sharedInstance].URLHandleDelegate respondsToSelector:@selector(handleOpenURL:node:)]
                    && [[GUConfigure sharedInstance].URLHandleDelegate handleOpenURL:actionURL node:(id)self]) {
                }
                else if (![[UIApplication sharedApplication] openURL:actionURL]) {
                    GUWarn(@"Unhandled action %@ of nodeId %@", action, self.nodeId);
                }
            });
        }
        else {
            GUWarn(@"Unhandled action %@ of nodeId %@", action, self.nodeId);
        }
    }
}

- (void)gu_handleViewTap{
    UIView<GUNodeProtocol> *view = (UIView<GUNodeProtocol> *)self;
    while (view != nil) {
        id<GUNodeViewDelegate> delegate = [view nodeViewDelegate];
        if ([delegate respondsToSelector:@selector(nodeView:didTapNode:)] && [delegate nodeView:(UIView<GUNodeProtocol> *)view didTapNode:(id<GUNodeProtocol>)self]) {
            return;
        }
        view = (UIView<GUNodeProtocol> *)[view superview];
    }
    
    NSString *action = self.gu_userInfo[@"tap"];
    [self gu_runAction:action];
}

- (void)gu_handleViewDoubleTap{
    NSString *action = self.gu_userInfo[@"doubleTap"];
    [self gu_runAction:action];
}


- (void)gu_tapGestureAction:(UITapGestureRecognizer *)tap{
    [self gu_handleViewTap];
}

- (void)gu_doubleTapGestureAction:(UITapGestureRecognizer *)tap{
    [self gu_handleViewDoubleTap];
}


- (NSArray *)gu_delayedUpdateAttributeNames{
    static NSArray *viewConstraintAttributeNames = nil;
    if (viewConstraintAttributeNames == nil) {
        viewConstraintAttributeNames = @[@"left",@"right",@"bottom",@"top",@"centerX",@"centerY",@"width",@"height",@"lastBaseline",@"firstBaseline"];
    }
    return viewConstraintAttributeNames;
}

@end
