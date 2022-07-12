//
//  GUViewController.m
//  GearUI
//
//  Created by 谌启亮 on 16/4/15.
//  Copyright © 2016年 谌启亮. All rights reserved.
//

#import "GUViewController.h"
#import "GUXMLParser.h"
#import "GULayoutView.h"
#import "GUDebugSession.h"
#import "GUDebugClient.h"
#import "UIResponder+GearUI.h"
#import <objc/runtime.h>
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "GUConfigure.h"
#import "NSObject+GUPrivate.h"
#import "GULayoutView+Private.h"
#import "GULog.h"

@interface GULayoutView ()

- (instancetype)initWithNode:(GUNode *)node owningViewController:(GUViewController *)owningViewController;

@end


@interface GUKeyboardHideGestureRecognizer: UITapGestureRecognizer <UIGestureRecognizerDelegate>
@end

@implementation GUKeyboardHideGestureRecognizer

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self) {
        self.delegate = self;
        self.cancelsTouchesInView = NO;
    }
    return self;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return [GUConfigure sharedInstance].keyboardVisible;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return ![touch.view canBecomeFirstResponder];
}

@end

@interface GUViewController () <GUDebugSessionDelegate>

@property (nonatomic, copy, readonly) NSArray<id<GUNodeProtocol>> *subnodes;
@property (nonatomic, strong) GUDebugSession *debugSession;

@end

@implementation GUViewController
{
    GUNode *_layoutNode;
    BOOL _animated;
    BOOL _isOffseted;
    CGRect _lastPreOffsetFrame;
    GUKeyboardHideGestureRecognizer *_cancelEditTapGestureRecognizer;
    NSString *_fileName;
}
@dynamic view;

+ (void)initialize {
    NSDictionary *enumRep = @{@"fullScreen":@(UIModalPresentationFullScreen)};
    [[GUConfigure sharedInstance] setEnumeRepresentation:enumRep forPropertyName:@"modalPresentationStyle" ofClass:self];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithNode:nil fileName:nil];
}

- (instancetype)init {
    return [self initWithNode:nil fileName:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithNode:nil fileName:nil];
}


- (GUNode *)__loadNodeFormFileName:(NSString *)fileName {
    CFAbsoluteTime current = CFAbsoluteTimeGetCurrent();
    GUNode *node = [GUNode nodeWithFileName:fileName];
    self.debugSession = [[GUDebugSession alloc] initWithName:fileName node:node];
    [[GUDebugClient client] addSession:self.debugSession];
    self.debugSession.delegate = self;
    GUDebug(@"[ViewController] load node from file %f", CFAbsoluteTimeGetCurrent() - current);
    return node;
}

- (instancetype)initWithNode:(GUNode *)node fileName:(NSString *)fileName;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _fileName = fileName;
        _layoutNode = [GUNode new];
        self.backgroundColor = [UIColor whiteColor];
        @try {
            if (node == nil) {
                if ([_fileName length] == 0) {
                    Class checkClass = self.class;
                    while (checkClass && checkClass != [GUViewController class]) {
                        _fileName = [NSStringFromClass(checkClass) componentsSeparatedByString:@"."].lastObject;
                        node = [self __loadNodeFormFileName:_fileName];
                        if (node != nil) {
                            break;
                        }
                        checkClass = class_getSuperclass(checkClass);
                    }
                }
                else {
                    node = [self __loadNodeFormFileName:_fileName];
                }
            }
            [node updateObject:self];
        } @catch (NSException *e) {
            [self showDebugErrorMessage:e.reason];
        }

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gu_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gu_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        
        _autoHideKeyboard = YES;
        
    }
    return self;
}

- (void)setAutoHideKeyboard:(BOOL)autoHideKeyboard {
    if (_autoHideKeyboard != autoHideKeyboard) {
        _autoHideKeyboard = autoHideKeyboard;
        _cancelEditTapGestureRecognizer.enabled = _autoHideKeyboard;
    }
}

- (NSArray<GUNode *> *)updateSubnodes:(NSArray<GUNode *> *)subnodes {
    _layoutNode.subNodes = subnodes;
    return [NSArray array];
}

- (void)cancelEditTapAction:(UITapGestureRecognizer *)gesture {
    [self.view endEditing:YES];
}

- (void)gu_keyboardWillShow:(NSNotification *)notification {
    if (_offsetViewWhenKeyboardShow) {
        UIView *firstResponder = (UIView *)[UIResponder gu_firstResponder];
        if ([firstResponder isKindOfClass:[UIView class]] && [firstResponder isDescendantOfView:self.view]) {
            UIWindow *window = self.view.window;
            CGRect keyboardFrame = [(NSValue *)notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
            CGRect firstResponderFrame = [firstResponder convertRect:firstResponder.bounds toView:window];
            if (CGRectIntersectsRect(keyboardFrame, firstResponderFrame)) {
                CGFloat offset = (keyboardFrame.origin.y-40-firstResponderFrame.size.height)-firstResponderFrame.origin.y;
                _isOffseted = YES;
                _lastPreOffsetFrame = self.view.frame;
                self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+offset, self.view.frame.size.width, self.view.frame.size.height);
            }
        }
    }
}

- (void)gu_keyboardWillHide:(NSNotification *)notification {
    if (_isOffseted) {
        __weak id weakSelf = self;
        [UIView animateWithDuration:0.3 animations:^{
            __strong GUViewController *self = weakSelf;
            self.view.frame = self->_lastPreOffsetFrame;
            self->_isOffseted = NO;
        }];
    }
}

- (id<GUNodeProtocol>)subnodeWithId:(NSString *)nodeId {
    return [self.view viewWithNodeId:nodeId];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)session:(id)session didUpdateNode:(GUNode *)node {
    [node updateObject:self];
    if (self.viewLoaded) {
        [_layoutNode updateObject:self.view];
        [self.view setNeedsUpdateConstraints];
        [self.view autoRunAnimation];
    }
}

- (void)session:(id)session didCatchException:(NSException *)exception {
    [self showDebugErrorMessage:exception.reason];
}

- (void)showDebugErrorMessage:(NSString *)message {
    GUNode *scrollNode = [GUNode new];
    scrollNode.name = @"ScrollView";
    scrollNode.attributes = @{@"backgroundColor":@"blue",@"top":@"0",@"bottom":@"0",@"left":@"0",@"right":@"0"};
    GUNode *textNode = [GUNode new];
    textNode.name = @"Label";
    textNode.attributes = @{@"text":message,@"font":@"Menlo;14",@"textColor":@"white",@"numberOfLines":@"100",@"left":@"20",@"top":@"safeArea.top+20",@"bottom":@"(=-10",@"right":@"20"};
    scrollNode.subNodes = @[textNode];
    _layoutNode.subNodes = @[scrollNode];
    if (self.viewLoaded) {
        [_layoutNode updateObject:self.view];
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (_backgroundColor != backgroundColor) {
        _backgroundColor = backgroundColor;
        if ([self isViewLoaded]) {
            [self.view setBackgroundColor:_backgroundColor];
        }
    }
}

- (void)loadView {
    @try {
        CFAbsoluteTime current = CFAbsoluteTimeGetCurrent();
        GULayoutView *view = [[GULayoutView alloc] initWithNode:_layoutNode owningViewController:self];
        GUDebug(@"[ViewController] layoutview init %f", CFAbsoluteTimeGetCurrent() - current);
        
        current = CFAbsoluteTimeGetCurrent();
        view.backgroundColor = self.backgroundColor;
        self.view = view;
        [view setNeedsUpdateConstraints];
        GUDebug(@"[ViewController] layoutview update contraints %f", CFAbsoluteTimeGetCurrent() - current);

        current = CFAbsoluteTimeGetCurrent();
        [self gu_bindPropertyForSubClassOf:[GUViewController class]];
        GUDebug(@"[ViewController] view binding %f", CFAbsoluteTimeGetCurrent() - current);

//        unsigned int outCount = 0;
//        objc_property_t *list = class_copyPropertyList(self.class, &outCount);
//        NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"T@\"([\\w\\.]+)\"" options:0 error:nil];
//        for (int i = 0; i < outCount; i++) {
//            objc_property_t property = list[i];
//            const char *name = property_getName(property);
//            if (name!= NULL) {
//                NSString *propertName = [NSString stringWithUTF8String:name];
//                NSString *nodeId = [NSString stringWithFormat:@"#%@", propertName];
//                UIView *outView = [self.view viewWithNodeId:nodeId];
//                if (outView != nil) {
//                    NSString *attribute = [NSString stringWithUTF8String:property_getAttributes(property)];
//                    NSTextCheckingResult *result = [re firstMatchInString:attribute options:0 range:NSMakeRange(0, attribute.length)];
//                    if (result.numberOfRanges == 2) {
//                        NSRange classNameRange = [result rangeAtIndex:1];
//                        NSString *className = [attribute substringWithRange:classNameRange];
//                        Class class = NSClassFromString(className);
//                        if (class && [outView isKindOfClass:class] && [propertName length] > 0 && outView) {
//                            [self setValue:outView forKey:propertName];
//                        }
//                        else {
//                            GUFail(@"Class(%@) define for property(%@) not match the instance class(%@).", class, propertName, outView.class);
//                        }
//                    }
//                }
//            }
//
//        }
//        free(list);
        
        current = CFAbsoluteTimeGetCurrent();
        if ([_fileName length]) {
            NSString *filePath = [[NSBundle mainBundle] pathForResource:_fileName ofType:@"js"];
            NSString *js = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
            if (js) {
                [view __runJavaScript:js withSourceURL:[NSURL URLWithString:filePath]];
            }
        }
        GUDebug(@"[ViewController] run js %f", CFAbsoluteTimeGetCurrent() - current);

    } @catch (NSException *exception) {
        self.view = [GULayoutView new];
        [self showDebugErrorMessage:exception.reason];
    } @finally {
        self.view.nodeViewDelegate = self;
    }
    
    _cancelEditTapGestureRecognizer = [[GUKeyboardHideGestureRecognizer alloc] initWithTarget:self action:@selector(cancelEditTapAction:)];
    _cancelEditTapGestureRecognizer.enabled = _autoHideKeyboard;
    [self.view addGestureRecognizer:_cancelEditTapGestureRecognizer];
    
}

- (BOOL)nodeView:(UIView<GUNodeProtocol> *)nodeView didTapNode:(id<GUNodeProtocol>)node {
    return NO;
}

- (void)dealloc {
    [[GUDebugClient client] removeSession:_debugSession];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_animated) {
        [self.view autoRunAnimation];
        _animated = YES;
    }
}

@end
