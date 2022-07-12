//
//  UIView+GULayout.m
//  GearUI
//
//  Created by 谌启亮 on 29/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "UIView+GULayout.h"
#import "NSObject+GUPrivate.h"
#import "GULayoutConstraint.h"
#import <objc/runtime.h>
#import "GUNodeProtocol.h"
#import "GULayoutView.h"
#import "UIView+GUPrivate.h"
#import "GULog.h"

@interface GULayoutView ()

- (UILayoutGuide *)gu_safeAreaLayoutGuide;

@end


GULayoutConstraint *GULayoutConstraintsBestMatch(NSArray *constraints, NSUInteger *index){
    GULayoutConstraint *result = nil;
    NSUInteger i = 0;
    for (; i < constraints.count; i++) {
        GULayoutConstraint *constraint = constraints[i];
        UIView *secondItem = constraint.secondItem;
        if ([secondItem isKindOfClass:[UILayoutGuide class]]) {
            secondItem = [(UILayoutGuide *)secondItem owningView];
        }
        if (secondItem == nil) {
            result = constraint;
            break;
        }
        if (!secondItem.disableLayout || [constraint.firstItem isDescendantOfView:secondItem]) {
            result = constraint;
            break;
        }
    }
    if (index != NULL) {
        if (result) {
            *index = i;
        }
        else {
            *index = NSNotFound;
        }
    }
    return result;
}


NSLayoutAttribute NSLayoutAttributeFromString(NSString *attributeName){
    if ([attributeName isEqualToString:@"left"]) {
        return NSLayoutAttributeLeft;
    }
    else if ([attributeName isEqualToString:@"right"]) {
        return NSLayoutAttributeRight;
    }
    else if ([attributeName isEqualToString:@"top"]) {
        return NSLayoutAttributeTop;
    }
    else if ([attributeName isEqualToString:@"bottom"]) {
        return NSLayoutAttributeBottom;
    }
    else if ([attributeName isEqualToString:@"width"]) {
        return NSLayoutAttributeWidth;
    }
    else if ([attributeName isEqualToString:@"height"]) {
        return NSLayoutAttributeHeight;
    }
    else if ([attributeName isEqualToString:@"centerX"]) {
        return NSLayoutAttributeCenterX;
    }
    else if ([attributeName isEqualToString:@"centerY"]) {
        return NSLayoutAttributeCenterY;
    }
    else if ([attributeName isEqualToString:@"firstBaseline"]) {
        return NSLayoutAttributeFirstBaseline;
    }
    else if ([attributeName isEqualToString:@"lastBaseline"]) {
        return NSLayoutAttributeLastBaseline;
    }
    return NSLayoutAttributeNotAnAttribute;
}

NSString *NSStringFromLayoutAttribute(NSLayoutAttribute attribute){
    NSString *description = nil;
    switch (attribute) {
        case NSLayoutAttributeLeft:
            description = @"left";
            break;
        case NSLayoutAttributeRight:
            description = @"right";
            break;
        case NSLayoutAttributeTop:
            description = @"top";
            break;
        case NSLayoutAttributeBottom:
            description = @"bottom";
            break;
        case NSLayoutAttributeWidth:
            description = @"width";
            break;
        case NSLayoutAttributeHeight:
            description = @"height";
            break;
        case NSLayoutAttributeCenterX:
            description = @"centerX";
            break;
        case NSLayoutAttributeCenterY:
            description = @"centerY";
            break;
        case NSLayoutAttributeFirstBaseline:
            description = @"firstBaseline";
            break;
        case NSLayoutAttributeLastBaseline:
            description = @"lastBaseline";
            break;
        default:
            description = @"unsupported";
            break;
    }
    return description;
}

@interface GULayoutPlaceHolderInternal : NSObject
{
    id _target;
    UILayoutGuide *_tmp;
}

@property (nonatomic, strong) NSString *nodeId;

- (id)target;
- (void)updateTargetWithIdMap:(NSDictionary *)map;

@end

@implementation GULayoutPlaceHolderInternal

- (instancetype)init
{
    self = [super init];
    if (self) {
        _tmp = [UILayoutGuide new];
    }
    return self;
}

- (id)target{
    if (_target) {
        return _target;
    }
    else {
        return nil;
    }
}

- (void)updateTargetWithIdMap:(NSDictionary *)map{
    _target = map[_nodeId];
}

@end


@implementation GULayoutPlaceHolder {
    GULayoutPlaceHolderInternal *_internal;
}


+ (instancetype)placeHolderWithNodeId:(NSString *)nodeId {
    return [[self alloc] initWithNodeId:nodeId];
}

- (instancetype)initWithNodeId:(NSString *)nodeId
{
    _internal = [GULayoutPlaceHolderInternal new];
    _internal.nodeId = nodeId;
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    if (selector == @selector(updateTargetWithIdMap:)) {
        return [_internal methodSignatureForSelector:selector];
    }
    return [[_internal target] methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    if (invocation.selector == @selector(updateTargetWithIdMap:)) {
        [invocation invokeWithTarget:_internal];
    }
    else {
        [invocation invokeWithTarget:[_internal target]];
    }
}

- (void)updateTargetWithIdMap:(NSDictionary *)map{
    [_internal updateTargetWithIdMap:map];
}

@end

@implementation UIView (GULayout)

- (NSMutableDictionary *)gu_layoutInfo{
    static char gu_layoutInfo_key = 'a';
    NSMutableDictionary *cache = objc_getAssociatedObject(self, &gu_layoutInfo_key);
    if (cache == nil) {
        cache = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &gu_layoutInfo_key, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cache;
}

- (NSMutableDictionary *)gu_layoutFailInfo{
    static char gu_layoutFailInfo_key = 'a';
    NSMutableDictionary *cache = objc_getAssociatedObject(self, &gu_layoutFailInfo_key);
    if (cache == nil) {
        cache = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &gu_layoutFailInfo_key, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cache;
}

- (void)gu_updateLayoutWithAttribute:(NSLayoutAttribute)layoutAttribute value:(NSString *)value {
    value = [value stringByReplacingOccurrencesOfString:@"SCREEN_WIDTH" withString:[NSString stringWithFormat:@"%f", [UIScreen mainScreen].bounds.size.width]];
    value = [value stringByReplacingOccurrencesOfString:@"SCREEN_HEIGHT" withString:[NSString stringWithFormat:@"%f", [UIScreen mainScreen].bounds.size.height]];
    GULayoutView *superView = nil;
    if ([[self superview] isKindOfClass:[GULayoutView class]]) {
        superView = (GULayoutView *)[self superview];
    }
    NSArray *contraintStrings = [value componentsSeparatedByString:@"|"];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[contraintStrings count]];
    for (NSString *contraintString in contraintStrings) {
        if ([contraintString length] == 0) {
            continue;
        }
        
        NSScanner *scanner = [NSScanner scannerWithString:contraintString];
        scanner.charactersToBeSkipped = [NSCharacterSet whitespaceCharacterSet];
        NSLayoutRelation layoutRelation = NSLayoutRelationEqual;
        NSLayoutAttribute secondItemAttribute = NSLayoutAttributeNotAnAttribute;
        id secondItem = nil;
        CGFloat multiplier = 1;
        CGFloat constant = 0;
        
        //解析NSLayoutRelation
        if ([scanner scanString:@")=" intoString:nil]||[scanner scanString:@")" intoString:nil]) {
            layoutRelation = NSLayoutRelationGreaterThanOrEqual;
        }
        else if ([scanner scanString:@"(=" intoString:nil]||[scanner scanString:@"(" intoString:nil]){
            layoutRelation = NSLayoutRelationLessThanOrEqual;
        }

        //解析second item
        if ([contraintString rangeOfString:@"."].location != NSNotFound && ![[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[contraintString characterAtIndex:scanner.scanLocation]]) {
            NSString *secondItemId = nil;
            if([scanner scanUpToString:@"." intoString:&secondItemId]){
                if ([secondItemId isEqualToString:@"super"]) {
                    secondItem = [self superview];
                }
                else if ([secondItemId isEqualToString:@"safeArea"]) {
                    UIView *superView = [self superview];
                    UILayoutGuide *safeAreaLayoutGuide = nil;
                    if ([superView isKindOfClass:[GULayoutView class]]) {
                        safeAreaLayoutGuide = [(GULayoutView *)superView gu_safeAreaLayoutGuide];
                    }
                    else if (@available(iOS 11.0, *)) {
                        safeAreaLayoutGuide = superView.safeAreaLayoutGuide;
                    }
                    if (safeAreaLayoutGuide) {
                        secondItem = safeAreaLayoutGuide;
                    }
                    else {
                        secondItem = superView;
                    }
                }
                else {
                    if (superView == nil) {
                        GUError(@"%@ must layout in a LayoutView, superview must be a class of GULayoutView, but current superview is: %@", self.nodeId, self.superview);
                    }
                    secondItem = [superView subviewWithNodeId:secondItemId];
                }
                if (secondItem == nil) {
                    GUError(@"secondItemId: %@ did not found in view hierarchy", secondItemId);
                    continue;
                }
            }
            [scanner scanString:@"." intoString:NULL];
            NSString *secondNodeAttribute = nil;
            if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"+-*/"] intoString:&secondNodeAttribute]) {
                secondItemAttribute = NSLayoutAttributeFromString(secondNodeAttribute);
            }
            if ([scanner scanString:@"*" intoString:nil]) {
                float scanedMultiplier;
                [scanner scanFloat:&scanedMultiplier];
                multiplier = scanedMultiplier;
            }
            if ([scanner scanString:@"/" intoString:nil]) {
                float scanedMultiplierRev;
                [scanner scanFloat:&scanedMultiplierRev];
                multiplier = 1.0/scanedMultiplierRev;
            }
        }
        
        float scanedConstant = 0;
        if ([scanner scanFloat:&scanedConstant]) {
            constant = scanedConstant;
            if (constant < 0.9 && constant > 0.1) {
                constant = 1.0/[UIScreen mainScreen].scale;
            }
        }

        if (layoutAttribute != NSLayoutAttributeWidth && layoutAttribute != NSLayoutAttributeHeight && secondItem == nil) {
            secondItem = [self superview];
            if ([secondItem isKindOfClass:[GULayoutView class]]) {
                GULayoutView *superLayoutView = secondItem;
                if (superLayoutView.useSafeAreaLayout) {
                    UILayoutGuide *safeAreaLayoutGuide = [superLayoutView gu_safeAreaLayoutGuide];
                    if (safeAreaLayoutGuide != nil) {
                        secondItem = safeAreaLayoutGuide;
                    }
                }
            }
            if (secondItem == nil) {
                self.gu_layoutFailInfo[@(layoutAttribute)] = value;
                return;
            }
            if (layoutAttribute == NSLayoutAttributeCenterX) {
                secondItemAttribute = NSLayoutAttributeLeft;
            }
            else if (layoutAttribute == NSLayoutAttributeCenterY) {
                secondItemAttribute = NSLayoutAttributeTop;
            }
            else {
                secondItemAttribute = layoutAttribute;
            }
            if (layoutAttribute == NSLayoutAttributeBottom || layoutAttribute == NSLayoutAttributeRight) {
                constant = -constant;
            }
        }

        GULayoutConstraint *constraint = [GULayoutConstraint constraintWithItem:self attribute:layoutAttribute relatedBy:layoutRelation toItem:secondItem attribute:secondItemAttribute multiplier:multiplier constant:constant];
        constraint.priority = 999;
        constraint.firstNodeId = [self nodeId];
        constraint.attributeString = value;
        
        
        
        [array addObject:constraint];

    }
    
    NSUInteger index = 0;
    GULayoutConstraint *bestConstraint = GULayoutConstraintsBestMatch(array, &index);
    GULayoutConstraint *removeContraint = nil;
    
    for (GULayoutConstraint *constraint in self.gu_layoutInfo[@(layoutAttribute)]) {
        if (constraint.secondItem == nil) {
            if ([self.constraints containsObject:constraint]) {
                removeContraint = constraint;
            }
        }
        else {
            if ([self.superview.constraints containsObject:constraint]) {
                removeContraint = constraint;
            }
        }
    }
    [self.gu_layoutInfo removeObjectForKey:@(layoutAttribute)];
    

    if (bestConstraint) {
        if (bestConstraint.firstItem == removeContraint.firstItem
            && bestConstraint.secondItem == removeContraint.secondItem
            && bestConstraint.firstAttribute == removeContraint.firstAttribute
            && bestConstraint.secondAttribute == removeContraint.secondAttribute
            && bestConstraint.relation == removeContraint.relation) {
            removeContraint.constant = bestConstraint.constant;
            [array replaceObjectAtIndex:index withObject:removeContraint];
        }
        else {
            if (removeContraint.secondItem == nil) {
                [self removeConstraint:removeContraint];
            }
            else {
                [self.superview removeConstraint:removeContraint];
            }
            if (bestConstraint.secondItem == nil) {
                [self addConstraint:bestConstraint];
            }
            else {
                [self.superview addConstraint:bestConstraint];
            }
        }
    }
    
    self.gu_layoutInfo[@(layoutAttribute)] = [array copy];

}

@end
