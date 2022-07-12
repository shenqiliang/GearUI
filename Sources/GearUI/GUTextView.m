//
//  GUTextView.m
//  GearUI
//
//  Created by 谌启亮 on 16/4/15.
//  Copyright © 2016年 谌启亮. All rights reserved.
//

#import "GUTextView.h"

@implementation GUTextView {
    UILabel *_placeholderLabel;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gu_textDidChanged:) name:UITextViewTextDidChangeNotification object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gu_textDidChanged:) name:UITextViewTextDidEndEditingNotification object:self];
        _placeholderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [self addSubview:_placeholderLabel];
        _placeholderLabel.font = self.font;
        _placeholderLabel.numberOfLines = 0;
        if (@available(iOS 13.0, *)) {
            _placeholderLabel.textColor = UIColor.placeholderTextColor;
        } else {
            _placeholderLabel.textColor = [UIColor colorWithRed:0.235294 green:0.235294 blue:0.262745 alpha:0.3];
        }
    }
    return self;
}

- (void)setMaxInputWidth:(NSInteger)maxInputWidth {
    _maxInputWidth = maxInputWidth;
    _maxInputLength = 0;
}

- (void)setPlaceholder:(NSString *)placeholder {
    _placeholderLabel.text = placeholder;
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [_placeholderLabel setHidden:text.length != 0];
}

- (void)setFont:(UIFont *)font {
    [super setFont:font];
    _placeholderLabel.font = font;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize size = CGSizeMake(self.bounds.size.width-(self.textContainerInset.left+4)*2, self.bounds.size.height);
    CGSize placeholderSize = [_placeholderLabel sizeThatFits:size];
    _placeholderLabel.frame = CGRectMake(self.textContainerInset.left+4, self.textContainerInset.top, size.width, placeholderSize.height);
}

- (void)setMaxInputLength:(NSInteger)maxInputLength {
    _maxInputWidth = 0;
    _maxInputLength = maxInputLength;
}

+ (NSString *)filterString:(NSString *)text  allowInputCharacterSet:(NSCharacterSet *)allowInputCharacterSet maxInputLength:(NSInteger)maxInputLength maxInputWidth:(NSInteger)maxInputWidth {
    if (allowInputCharacterSet) {
        NSMutableString *result = [NSMutableString string];
        NSString *rawText = text;
        NSRange range = [rawText rangeOfCharacterFromSet:allowInputCharacterSet];
        while (range.location != NSNotFound && range.length > 0) {
            [result appendString:[rawText substringWithRange:range]];
            rawText = [rawText substringFromIndex:NSMaxRange(range)];
            range = [rawText rangeOfCharacterFromSet:allowInputCharacterSet];
        }
        text = [result copy];
    }
    if (maxInputLength > 0) {
        NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
        [text enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
            [ranges addObject:[NSValue valueWithRange:substringRange]];
        }];
        if ([ranges count] > maxInputLength) {
            NSRange range = [ranges[maxInputLength-1] rangeValue];
            text = [text substringToIndex:range.location+range.length];
        }
    }
    else if (maxInputWidth > 0) {
        __block NSInteger inputWidth = 0;
        __block NSRange lastRange = NSMakeRange(0, text.length);
        [text enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
            if ([substring characterAtIndex:0] < 256) {
                inputWidth += 1;
            }
            else {
                inputWidth += 2;
            }
            if (inputWidth >= maxInputWidth) {
                lastRange.length = substringRange.location + substringRange.length;
                *stop = YES;
            }
        }];
        text = [text substringWithRange:lastRange];
    }
    return text;
}

- (void)gu_textDidChanged:(UITextView *)textView {
    NSString *text = [super text];
    [_placeholderLabel setHidden:text.length != 0];
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

- (NSString *)text {
    NSString *text = [super text];
    if (text!= nil) {
        text = [GUTextView filterString:text allowInputCharacterSet:_allowInputCharacterSet maxInputLength:_maxInputLength maxInputWidth:_maxInputWidth];
    }
    return text;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
