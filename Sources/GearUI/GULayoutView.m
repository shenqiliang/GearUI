//
//  GULayout.m
//  GearUI
//
//  Created by 谌启亮 on 16/4/15.
//  Copyright © 2016年 谌启亮. All rights reserved.
//

#import "GULayoutView.h"
#import "GUDefines.h"
#import "UIView+GULayout.h"
#import "UIView+GUPrivate.h"
#import "GULayoutConstraint.h"
#import "GUConfigure.h"
#import "NSString+GUValue.h"
#import "GUDebugSession.h"
#import "GUDebugClient.h"
#import "GUAnimation+GUPrivate.h"
#import "GUViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "GUJavaScriptManager.h"
#import <objc/runtime.h>
#import "GUWeakProxy.h"
#import "NSObject+GUPrivate.h"
#import "GULog.h"
#import "GUDataBindingObserver.h"

@interface GULayoutView () <GUDebugSessionDelegate>

@property(nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, copy) NSArray<id<GUNodeProtocol>> *subnodes;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

- (UILayoutGuide *)gu_safeAreaLayoutGuide;
- (instancetype)initWithNode:(GUNode *)node owningViewController:(GUViewController *)owningViewController;

@property (nonatomic, weak) GUViewController *owningViewController;

@property (nonatomic, strong) JSContext *jsContext;

@end


@implementation GULayoutView
{
    NSDictionary *_nodeIdViewMap;
    NSString *_fileName;
    GUDebugSession *_debugSession;
    
    NSArray *_animations;
    
    UILayoutGuide *_gu_safeAreaLayoutGuide;
    NSLayoutConstraint *_gu_safeAreaTopConstraint;
    NSLayoutConstraint *_gu_safeAreaBottomConstraint;
    
    NSHashTable<GUDataBindingObserver *> *_databindingObservers;
}

- (void)__commonDesignetedInitialize {
    _databindingObservers = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:100];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSString *fileName = [NSStringFromClass(self.class) componentsSeparatedByString:@"."].lastObject;
        GUNode *node = nil;
        NSException *exception = nil;
        @try {
            node = [GUNode nodeWithFileName:fileName];
            [node updateObject:self];
        } @catch (NSException *e) {
            exception = e;
        } @finally {
            
        }
        if (![fileName isEqualToString:@"GULayoutView"]) {
            _debugSession = [[GUDebugSession alloc] initWithName:fileName node:node];
            [[GUDebugClient client] addSession:_debugSession];
            _debugSession.delegate = self;
        }
        if (exception) {
            [self showDebugErrorMessage:exception.reason];
        }
        [self __commonDesignetedInitialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [self initWithFileName:[NSStringFromClass(self.class) componentsSeparatedByString:@"."].lastObject];
    self.frame = frame;
    return self;
}

- (instancetype)initWithFileName:(NSString *)fileName
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        GUNode *node = nil;
        if (![fileName isEqualToString:@"GULayoutView"]) {
            NSException *exception = nil;
            @try {

                CFAbsoluteTime current = CFAbsoluteTimeGetCurrent();
                node = [GUNode nodeWithFileName:fileName];
                [node updateObject:self];
                GUDebug(@"[ViewController] load node from file %f", CFAbsoluteTimeGetCurrent() - current);

            } @catch (NSException *e) {
                exception = e;
            } @finally {
                
            }
            _debugSession = [[GUDebugSession alloc] initWithName:fileName node:node];
            [[GUDebugClient client] addSession:_debugSession];
            _debugSession.delegate = self;
            if (exception) {
                [self showDebugErrorMessage:exception.reason];
            }
        }
        [self __commonDesignetedInitialize];
    }
    return self;
}

- (instancetype)initWithNode:(GUNode *)node owningViewController:(GUViewController *)owningViewController {
    _owningViewController = owningViewController;
    _useSafeAreaLayout = owningViewController.useSafeAreaLayout;
    return [self initWithNode:node];
}

- (instancetype)initWithNode:(GUNode *)node
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        if (node) {
            @try {
                [node updateObject:self];
            }
            @catch (NSException *exception) {
                [self showDebugErrorMessage:exception.reason];
            }
        }
        [self __commonDesignetedInitialize];
    }
    return self;
}

- (void)bind:(NSObject *)obj keyPath:(NSString *)keyPath toKeyPath:(NSString *)toKeyPath map:(id (^)(id))map {
    GUDataBindingObserver *observer = [[GUDataBindingObserver alloc] initWithLayoutView:self keyPath:toKeyPath object:obj objectKeyPath:keyPath map:map];
    [_databindingObservers addObject:observer];
}

- (void)bind:(NSObject *)obj keyPath:(NSString *)keyPath toKeyPath:(NSString *)toKeyPath {
    [self bind:obj keyPath:keyPath toKeyPath:toKeyPath map:nil];
}

- (void)removeBindingToKeyPath:(NSString *)toKeyPath {
    for (GUDataBindingObserver *observer in [_databindingObservers allObjects]) {
        if ([observer.keyPath isEqual:toKeyPath]) {
            [_databindingObservers removeObject:observer];
            [observer invalidate];
        }
    }
}

- (void)removeAllBindings {
    for (GUDataBindingObserver *observer in [_databindingObservers allObjects]) {
        [observer invalidate];
    }
}

- (void)session:(id)session didUpdateNode:(GUNode *)node {
    [node updateObject:self];
    [self setNeedsUpdateConstraints];
}

- (void)session:(id)session didCatchException:(NSException *)exception {
    [self showDebugErrorMessage:exception.reason];
}

- (void)showDebugErrorMessage:(NSString *)message {
    GUNode *scrollNode = [GUNode new];
    scrollNode.name = @"ScrollView";
    scrollNode.attributes = @{@"backgroundColor":@"blue"};
    GUNode *textNode = [GUNode new];
    textNode.name = @"Label";
    textNode.attributes = @{@"text":message,@"font":@"Menlo;14",@"textColor":@"white",@"numberOfLines":@"100",@"left":@"20",@"top":@"safeArea.top+20",@"bottom":@"(=-10",@"right":@"20"};
    scrollNode.subNodes = @[textNode];
    GUNode *node = [GUNode new];
    node.subNodes = @[scrollNode];
    node.name = @"LayoutView";
    [node updateObject:self];
}

- (void)setupJSContext {
    if (_jsContext == nil) {
        _jsContext = [GUJavaScriptManager.sharedInstance genContextInLayoutView:self];
        _jsContext.exceptionHandler = ^(JSContext *context, JSValue *exception) {
            NSLog(@"%@", exception);
        };
    }
}

- (void)setValue:(id)value forKeyPath:(NSString *)keyPath {
#if DEBUG
    GUError(@"Please use setKeyPathAttributes: method!");
#endif
    [super setValue:value forKeyPath:keyPath];
}

- (BOOL)__runJavaScript:(NSString *)js {
    BOOL ret = [self __runJavaScript:js withSourceURL:nil];
    [[GUJavaScriptManager sharedInstance] garbageCollectContext:_jsContext];
    return ret;
}

- (BOOL)__runJavaScript:(NSString *)js withSourceURL:(NSURL *)url {
    if (_jsContext) {
        [_jsContext evaluateScript:js withSourceURL:url];
    }
    return _jsContext != nil;
}

- (void)gu_updateJSEnvInContext:(JSContext *)context {
//    for (NSString *nodeId in [_nodeIdViewMap keyEnumerator]) {
//        [GUJavaScriptManager.sharedInstance setGlobalVar:_nodeIdViewMap[nodeId] forName:nodeId inContext:_jsContext];
//    }
    if (_owningViewController) {
        [GUJavaScriptManager.sharedInstance setGlobalVar:[GUWeakProxy proxyWithObject:_owningViewController] forName:@"self" inContext:_jsContext];
    }
}

- (void)updateChildren:(NSArray *)subNodes {
    if ([_nodeIdViewMap count]) {
        for (UIView<GUNodeViewProtocol> *view in _nodeIdViewMap.allValues) {
            [view removeFromSuperview];
        }
    }
    NSMutableDictionary *nodeIdViewMap = [NSMutableDictionary dictionary];
    NSMutableArray *animations = [NSMutableArray array];
    NSMutableArray *jsCodes = [NSMutableArray array];
    for (UIView<GUNodeViewProtocol> *view in subNodes) {
        if ([view isKindOfClass:[GUAnimation class]]) {
            GUAnimation *animation = (GUAnimation *)view;
            animation.layoutView = self;
            [animations addObject:animation];
            continue;
        }
        if ([view isKindOfClass:[GUNode class]]) {
            GUNode *node = (GUNode *)view;
            if ([node.name caseInsensitiveCompare:@"Script"] == NSOrderedSame) {
                NSString *jsCode = node.text;
                [self setupJSContext];
                if (jsCode) {
                    [jsCodes addObject:jsCode];
                }
            }
            else {
                GUFail(@"layout view(%@) does not support subnode(%@) as a child node.", self.nodeId?:@"", node.name);
            }
            continue;
        }
        if (![view isKindOfClass:[UIView class]]) {
            GUFail(@"layout view(%@)'s subnode(id:%@) is not a subclass of UIView!", self.nodeId?:@"", view.nodeId);
            break;
        }
        if (view.nodeId) {
            nodeIdViewMap[view.nodeId] = view;
        }
        else {
            nodeIdViewMap[[[NSUUID UUID] UUIDString]] = view;
        }
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:view];
    }
    
    _nodeIdViewMap = [nodeIdViewMap copy];
    _animations = [animations copy];
    
    if (_jsContext) {
        [self gu_updateJSEnvInContext:_jsContext];
    }
    
    for (int i = 0; i < [jsCodes count]; i++) {
        NSString *jsCode = jsCodes[i];
        NSString *filePath = [NSString stringWithFormat:@"/xml_embed_%d.js", i];
        [_jsContext evaluateScript:jsCode withSourceURL:[NSURL URLWithString:filePath]];
    }
    
    [self gu_bindPropertyForSubClassOf:[GULayoutView class]];

}

- (UIView<GUNodeProtocol> *)subviewWithNodeId:(NSString *)nodeId {
    return _nodeIdViewMap[nodeId];
}

- (void)updateConstraints {
    
    if ([[_nodeIdViewMap allValues] count] == 1) {
        UIView<GUNodeProtocol> *view = [[_nodeIdViewMap allValues] lastObject];
        if ([view.gu_layoutInfo count] == 0 && [view.gu_layoutFailInfo count] == 0) {
            [view setAttribute:@"0" forKeyPath:@"left"];
            [view setAttribute:@"0" forKeyPath:@"right"];
            [view setAttribute:@"0" forKeyPath:@"top"];
            [view setAttribute:@"0" forKeyPath:@"bottom"];
        }
    }
    if (_gu_safeAreaLayoutGuide != nil) {
        if (_gu_safeAreaTopConstraint.secondItem == self && _owningViewController.topLayoutGuide != nil) {
            [self removeConstraint:_gu_safeAreaTopConstraint];
            _gu_safeAreaTopConstraint = [NSLayoutConstraint constraintWithItem:_gu_safeAreaLayoutGuide attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_owningViewController.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
            [self addConstraint:_gu_safeAreaTopConstraint];
        }
        if (_gu_safeAreaBottomConstraint.secondItem == self && _owningViewController.bottomLayoutGuide != nil) {
            [self removeConstraint:_gu_safeAreaBottomConstraint];
            _gu_safeAreaBottomConstraint = [NSLayoutConstraint constraintWithItem:_gu_safeAreaLayoutGuide attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_owningViewController.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0];
            [self addConstraint:_gu_safeAreaBottomConstraint];
        }
    }

    NSArray *subviews = [_nodeIdViewMap allValues];
    
    NSMutableDictionary *nodeIdViewMap = [_nodeIdViewMap mutableCopy];
    nodeIdViewMap[@"super"] = self;
    
    if (self.superview) {
        [self.gu_layoutFailInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [self gu_updateLayoutWithAttribute:[key intValue] value:obj];
        }];
        [self.gu_layoutFailInfo removeAllObjects];
    }
    
    
    for (UIView<GUNodeProtocol> *view in subviews) {
        [view.gu_layoutInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSArray *constraints = obj;
            GULayoutConstraint *bestConstraint = GULayoutConstraintsBestMatch(constraints, NULL);
            if (bestConstraint && ![self.constraints containsObject:bestConstraint] && ![view.constraints containsObject:bestConstraint]) {

                [self removeConstraints:constraints];
                [view removeConstraints:constraints];
                
                if (bestConstraint.secondItem == nil) {
                    [view addConstraint:bestConstraint];
                }
                else {
                    [self addConstraint:bestConstraint];
                }
            }
        }];
    }
    
    [super updateConstraints]; //final step
}


- (void)autoRunAnimation {
    for (GUAnimation *animation in _animations) {
        if (animation.autoRun) {
            [animation runWithCompletion:nil];
        }
    }
    for (GULayoutView *layoutView in [_nodeIdViewMap allValues]) {
        if ([layoutView isKindOfClass:[GULayoutView class]]) {
            [layoutView autoRunAnimation];
        }
    }
}

- (void)runAnimationWithNodeId:(NSString *)nodeId completion:(void(^)(BOOL))completion {
    for (GUAnimation *animation in _animations) {
        if ([animation.nodeId isEqualToString:nodeId]) {
            [animation runWithCompletion:completion];
        }
    }
    for (GULayoutView *layoutView in [_nodeIdViewMap allValues]) {
        if ([layoutView isKindOfClass:[GULayoutView class]]) {
            [layoutView runAnimationWithNodeId:nodeId completion:completion];
        }
    }
}

- (void)runAnimationWithNodeId:(NSString *)nodeId {
    [self runAnimationWithNodeId:nodeId completion:nil];
}

- (void)stopAnimationWithNodeId:(NSString *)nodeId {
    for (GUAnimation *animation in _animations) {
        if ([animation.nodeId isEqualToString:nodeId]) {
            [animation stop];
        }
    }
    for (GULayoutView *layoutView in [_nodeIdViewMap allValues]) {
        if ([layoutView isKindOfClass:[GULayoutView class]]) {
            [layoutView stopAnimationWithNodeId:nodeId];
        }
    }
}

- (UILayoutGuide *)gu_safeAreaLayoutGuide {
    if (@available(iOS 11.0, *)) {
        return self.safeAreaLayoutGuide;
    } else {
        GUViewController *owningViewController = self.owningViewController;
        if (owningViewController == nil) {
            return nil;
        }
        
        if (_gu_safeAreaLayoutGuide == nil) {
            _gu_safeAreaLayoutGuide = [[UILayoutGuide alloc] init];
            [self addLayoutGuide:_gu_safeAreaLayoutGuide];
            if (owningViewController.topLayoutGuide != nil) {
                _gu_safeAreaTopConstraint = [NSLayoutConstraint constraintWithItem:_gu_safeAreaLayoutGuide attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:owningViewController.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
            }
            else {
                _gu_safeAreaTopConstraint = [NSLayoutConstraint constraintWithItem:_gu_safeAreaLayoutGuide attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0];
            }
            NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_gu_safeAreaLayoutGuide attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
            NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_gu_safeAreaLayoutGuide attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0];
            if (owningViewController.bottomLayoutGuide != nil) {
                _gu_safeAreaBottomConstraint = [NSLayoutConstraint constraintWithItem:_gu_safeAreaLayoutGuide attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:owningViewController.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0];
            }
            else {
                _gu_safeAreaBottomConstraint = [NSLayoutConstraint constraintWithItem:_gu_safeAreaLayoutGuide attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
            }
            [self addConstraints:@[_gu_safeAreaTopConstraint, left, _gu_safeAreaBottomConstraint, right]];
            
        }

        return _gu_safeAreaLayoutGuide;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
}

- (void)dealloc {
    [self removeAllBindings];
    if (_jsContext != nil) {
        [[GUJavaScriptManager sharedInstance] deleteContext:_jsContext];
        _jsContext = nil;
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if (_highlightContentWhenTouch) {
        self.highlighted = YES;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (_highlightContentWhenTouch) {
        self.highlighted = NO;
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    if (_highlightContentWhenTouch) {
        self.highlighted = NO;
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    if (_highlighted != highlighted) {
        _highlighted = highlighted;
        for (UIView *view in self.subviews) {
            if ([view respondsToSelector:@selector(setHighlighted:)]) {
                [(id)view setHighlighted:highlighted];
            }
        }
    }
}

@end
