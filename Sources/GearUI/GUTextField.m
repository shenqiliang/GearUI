//
//  GUTextField.m
//  GearUI
//
//  Created by 谌启亮 on 21/09/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUTextField.h"
#import "GUTextView.h"

@interface GUTextView()
+ (NSString *)filterString:(NSString *)text allowInputCharacterSet:(NSCharacterSet *)allowInputCharacterSet maxInputLength:(NSInteger)maxInputLength maxInputWidth:(NSInteger)maxInputWidth;
@end



@implementation GUTextField

- (void)setMaxInputWidth:(NSInteger)maxInputWidth {
    _maxInputWidth = maxInputWidth;
    _maxInputLength = 0;
}

- (void)setMaxInputLength:(NSInteger)maxInputLength {
    _maxInputWidth = 0;
    _maxInputLength = maxInputLength;
}

- (void)didUpdateAttributes {
    if (self.placeholderColor) {
        self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeholder attributes:@{NSForegroundColorAttributeName:self.placeholderColor}];
    }
    [self addTarget:self action:@selector(gu_EditChanged) forControlEvents:UIControlEventEditingChanged];
    [self addTarget:self action:@selector(gu_EditChanged) forControlEvents:UIControlEventEditingDidEnd];
}


- (NSString *)text {
    NSString *text = [super text];
    if (text!= nil) {
        text = [GUTextView filterString:text allowInputCharacterSet:_allowInputCharacterSet maxInputLength:_maxInputLength maxInputWidth:_maxInputWidth];
    }
    return text;
}

- (void)gu_EditChanged {
    NSString *text = [super text];
    if (text!= nil) {
        if (self.markedTextRange == nil || self.markedTextRange.isEmpty) {
            if (_allowInputCharacterSet || _maxInputLength > 0) {
                NSString *filterText = [GUTextView filterString:text allowInputCharacterSet:_allowInputCharacterSet maxInputLength:_maxInputLength maxInputWidth:_maxInputWidth];
                if (text.length != filterText.length) {
                    self.text = filterText;
                }
            }
        }
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (self.disableMenu) {
        return false;
    }
    return [super canPerformAction:action withSender:sender];
}

@end
