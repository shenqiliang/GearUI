//
//  GULabel.m
//  GearUI
//
//  Created by 谌启亮 on 30/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GULabel.h"
#import "GUNode.h"
#import "NSString+GUValue.h"
#import "UIView+GUPrivate.h"
#import "GUTextLayout.h"
#import "GULog.h"
#import "GUDefines.h"

NSAttributedStringKey const GUHighlightedTextColorAttributeName = @"GUHighlightTextColorAttributeName";
NSAttributedStringKey const GUHighlightedTextBackgroundColorAttributeName = @"GUHighlightedTextBackgroundColorAttributeName";

@implementation GULabel {
    GUTextLayout *_textLayout;
    CGSize _unrestrictSize;
    NSRange _highlightedTextRange;
}

FORWARD_PROPERTY(truncationString, setTruncationString:, truncationString, NSAttributedString *, _textLayout)

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _textLayout = [GUTextLayout new];
    }
    return self;
}

- (BOOL)updateAttributeValue:(NSString *)value forName:(NSString *)name {
    if ([name isEqualToString:@"truncationString"] && [value isKindOfClass:[NSString class]]) {
        self.truncationString = [[NSAttributedString alloc] initWithString:value attributes:nil];
        return YES;
    }
    return NO;
}

- (NSMutableAttributedString *)generateAttributeTextForGUTextSubNodes:(NSArray *)subNodes inheritAttributes:(NSDictionary *)inheritAttributes {
    NSMutableAttributedString *string = [NSMutableAttributedString new];
    for (GUNode *node in subNodes) {
        if ([node isKindOfClass:[GUNode class]]) {
            NSMutableDictionary *attributes = [inheritAttributes mutableCopy];
            if (node.attributes[@"tap"]) {
                self.userInteractionEnabled = YES;
                attributes[@"tap"] = node.attributes[@"tap"];
            }
            if (node.attributes[@"color"]) {
                UIColor *color = [node.attributes[@"color"] gu_UIColorValue];
                if (color != nil) {
                    attributes[NSForegroundColorAttributeName] = color;
                }
            }
            if (node.attributes[@"highlightedColor"]) {
                UIColor *color = [node.attributes[@"highlightedColor"] gu_UIColorValue];
                if (color != nil) {
                    attributes[GUHighlightedTextColorAttributeName] = color;
                }
            }
            if (node.attributes[@"highlightedBackgroundColor"]) {
                UIColor *color = [node.attributes[@"highlightedBackgroundColor"] gu_UIColorValue];
                if (color != nil) {
                    attributes[GUHighlightedTextBackgroundColorAttributeName] = color;
                }
            }
            if (node.attributes[@"underline"]) {
                int underline = [node.attributes[@"underline"] intValue];
                attributes[NSUnderlineStyleAttributeName] = @(underline);
            }
            if (node.attributes[@"underlineColor"]) {
                UIColor *color = [node.attributes[@"underlineColor"] gu_UIColorValue];
                if (color != nil) {
                    attributes[NSUnderlineColorAttributeName] = color;
                }
            }
            if (node.attributes[@"lineSpace"]) {
                NSString *lineSpace = node.attributes[@"lineSpace"];
                NSMutableParagraphStyle *paragraphStyle = attributes[NSParagraphStyleAttributeName];
                if (paragraphStyle == nil) {
                    paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                    paragraphStyle.alignment = self.textAlignment;
                    [paragraphStyle setLineSpacing:lineSpace.floatValue];
                }
                attributes[NSParagraphStyleAttributeName] = paragraphStyle;
            }
            if (node.attributes[@"paragraphSpace"]) {
                NSString *paragraphSpace = node.attributes[@"paragraphSpace"];
                NSMutableParagraphStyle *paragraphStyle = attributes[NSParagraphStyleAttributeName];
                if (paragraphStyle == nil) {
                    paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                    paragraphStyle.alignment = self.textAlignment;
                    [paragraphStyle setParagraphSpacing:paragraphSpace.floatValue];
                }
                attributes[NSParagraphStyleAttributeName] = paragraphStyle;
            }
            if (node.attributes[@"font"]) {
                attributes[NSFontAttributeName] = [node.attributes[@"font"] gu_UIFontValue];
            }
            else if ([node.name isEqualToString:@"b"]) {
                UIFontDescriptor *fontDescriptor = [attributes[NSFontAttributeName] fontDescriptor];
                attributes[NSFontAttributeName] = [UIFont fontWithDescriptor:[fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:-1];
            }
            else if ([node.name isEqualToString:@"i"]) {
                UIFontDescriptor *fontDescriptor = [attributes[NSFontAttributeName] fontDescriptor];
                attributes[NSFontAttributeName] = [UIFont fontWithDescriptor:[fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic] size:-1];
            }
            else if ([node.name isEqualToString:@"br"]) {
                [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:inheritAttributes]];
            }
            else if ([node.name isEqualToString:@"space"]) {
                [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n \n" attributes:attributes]];
            }
            
            NSDictionary *finalAttributes = [attributes copy];
            if ([node.name isEqualToString:@"image"] || [node.name isEqualToString:@"icon"]) {
                UIImage *image = [UIImage imageNamed:node.text];
                if (image) {
                    NSTextAttachment *icon = [NSTextAttachment new];
                    icon.image = image;
                    NSMutableAttributedString *attributedString = [[NSAttributedString attributedStringWithAttachment:icon] mutableCopy];
                    [attributedString addAttributes:finalAttributes range:NSMakeRange(0, attributedString.length)];
                    [string appendAttributedString:attributedString];
                }
            }
            else {
                if (node.content) {
                    [string appendAttributedString:[[NSAttributedString alloc] initWithString:node.content attributes:finalAttributes]];
                }
                [string appendAttributedString:[self generateAttributeTextForGUTextSubNodes:node.subNodes inheritAttributes:finalAttributes]];
            }
        }
    }
    return string;
}

- (NSDictionary *)gu_textAttributes {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                      NSFontAttributeName: self.font?:[UIFont systemFontOfSize:13],
                                                                                      NSForegroundColorAttributeName: self.textColor?:[UIColor blackColor],
                                                                                      }];
    NSMutableParagraphStyle *ps = [NSMutableParagraphStyle new];
    ps.lineBreakMode = self.lineBreakMode;
    ps.alignment = self.textAlignment;
    if (self.lineSpace > __FLT_EPSILON__) {
        ps.lineSpacing = self.lineSpace;
        attributes[NSParagraphStyleAttributeName] = ps;
    }
    return [attributes copy];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted) {
        if (self.highlightedTextColor) {
            NSMutableAttributedString *content = [self.attributedText mutableCopy];
            [content addAttribute:NSForegroundColorAttributeName value:self.highlightedTextColor range:NSMakeRange(0, [content length])];
            _textLayout.attributedString = content;
        }
    }
    else {
        _textLayout.attributedString = self.attributedText;
    }
}

- (NSArray<GUNode *> *)updateSubnodes:(NSArray<GUNode *> *)subnodes {
    if ([subnodes count] > 0) {
        self.attributedText = [self generateAttributeTextForGUTextSubNodes:subnodes inheritAttributes:[self gu_textAttributes]];
    }
    return nil;
}

- (void)setXml:(NSString *)xmlText {
    _xml = xmlText;
    self.text = nil;
    NSString *xmlString = [NSString stringWithFormat:@"<p>%@</p>", _xml];
    @try {
        GUNode *node = [GUNode nodeWithXMLString:xmlString];
        [node updateObject:self];

    } @catch (NSException *exception) {
        GUWarn(@"Label(%@)设置xml异常: %@\n替换为纯文本", self.nodeId, exception);
        self.text = xmlText;
    } @finally {
        
    }
}

- (void)setLineSpace:(CGFloat)lineSpace {
    if (_lineSpace != lineSpace) {
        _lineSpace = lineSpace;
        _textLayout.lineSpace = _lineSpace;
        [self invalidateIntrinsicContentSize];
    }
}

- (void)setLineHeight:(CGFloat)lineHeight {
    if (_textLayout.lineHeight != lineHeight) {
        _textLayout.lineHeight = lineHeight;
        [self invalidateIntrinsicContentSize];
    }
}

- (CGFloat)lineHeight {
    return _textLayout.lineHeight;
}


- (void)setAttributedText:(NSAttributedString *)attributedText {
    [super setAttributedText:attributedText];
    _textLayout.attributedString = self.attributedText;
    _unrestrictSize = CGSizeZero;
}

- (void)setAdjustsFontSizeToFitWidth:(BOOL)adjustsFontSizeToFitWidth {
    [super setAdjustsFontSizeToFitWidth:adjustsFontSizeToFitWidth];
    _textLayout.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth;
    _textLayout.attributedString = self.attributedText;
}

- (void)setText:(NSString *)text {
    [super setText:text];
    _textLayout.attributedString = self.attributedText;
    _unrestrictSize = CGSizeZero;
}

- (void)setTextColor:(UIColor *)textColor {
    [super setTextColor:textColor];
    _textLayout.attributedString = self.attributedText;
}
- (void) setFont:(UIFont *)font {
    [super setFont:font];
    _textLayout.attributedString = self.attributedText;
}

- (void)setNumberOfLines:(NSInteger)numberOfLines {
    [super setNumberOfLines:numberOfLines];
    _textLayout.numberOflines = numberOfLines;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    [super setTextAlignment:textAlignment];
    _textLayout.textAlignment = textAlignment;
}

- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode {
    [super setLineBreakMode:lineBreakMode];
    _textLayout.lineBreakMode = lineBreakMode;
}

- (void)highligtTouchedTextAtIndex:(NSUInteger)index {
    if (index < [self.attributedText length]) {
        if (!NSLocationInRange(index, _highlightedTextRange)) {
            NSRange range = NSMakeRange(0, 0);
            UIColor *color = [self.attributedText attribute:GUHighlightedTextColorAttributeName atIndex:index effectiveRange:&range];
            UIColor *backgroundColor = [self.attributedText attribute:GUHighlightedTextBackgroundColorAttributeName atIndex:index effectiveRange:&range];
            if ([color isKindOfClass:[UIColor class]]) {
                NSMutableAttributedString *highlightedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
                [highlightedText addAttributes:@{NSForegroundColorAttributeName: color} range:range];
                _textLayout.attributedString = [[NSAttributedString alloc] initWithAttributedString:highlightedText];
                _textLayout.highlightedTextRange = range;
                _textLayout.highlightedBackgroundColor = backgroundColor;
                [self setNeedsDisplay];
            }
            _highlightedTextRange = range;
        }
    }
    else {
        if (_textLayout.attributedString != self.attributedText) {
            _textLayout.attributedString = self.attributedText;
        }
        _highlightedTextRange = NSMakeRange(0, 0);
        _textLayout.highlightedTextRange = NSMakeRange(0, 0);
        _textLayout.highlightedBackgroundColor = nil;
        [self setNeedsDisplay];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    if (self.contentMode != UIViewContentModeTop) {
        point.y -= (self.bounds.size.height - _textLayout.contentSize.height)/2;
    }
    NSUInteger index = [_textLayout characterIndexAtPoint:point size:self.bounds.size];
    [self highligtTouchedTextAtIndex:index];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    if (self.contentMode != UIViewContentModeTop) {
        point.y -= (self.bounds.size.height - _textLayout.contentSize.height)/2;
    }
    NSUInteger index = [_textLayout characterIndexAtPoint:point size:self.bounds.size];
    [self highligtTouchedTextAtIndex:index];
}


- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    if (self.contentMode != UIViewContentModeTop) {
        point.y -= (self.bounds.size.height - _textLayout.contentSize.height)/2;
    }
    NSUInteger index = [_textLayout characterIndexAtPoint:point size:self.bounds.size];
    if (index < [self.attributedText length]) {
        id attribute = [self.attributedText attribute:@"tap" atIndex:index effectiveRange:NULL];
        if ([attribute isKindOfClass:[NSString class]]) {
            [self gu_runAction:attribute];
        }
        else if ([attribute isKindOfClass:[NSOperation class]])  {
            [(NSOperation *)attribute main];
        }
    }
    [self highligtTouchedTextAtIndex:NSNotFound];
}

- (CGSize)intrinsicContentSize {
    if (self.preferredMaxLayoutWidth <= __FLT_EPSILON__) {
        if (_unrestrictSize.width <= __FLT_EPSILON__ && _unrestrictSize.height <= __FLT_EPSILON__) {
            _textLayout.preferredMaxWidth = 10000;
            _unrestrictSize = _textLayout.contentSize;
        }
        return _unrestrictSize;
    }
    else {
        _textLayout.preferredMaxWidth = self.preferredMaxLayoutWidth;
        return _textLayout.contentSize;
    }
}

- (BOOL)isTruncated {
    return _textLayout.truncated;
}

- (NSUInteger)displayedNumberOfLines {
    return _textLayout.displayedNumberOfLines;
}

- (void)drawTextInRect:(CGRect)rect {
    _textLayout.preferredMaxWidth = self.bounds.size.width;
    CGFloat offsetY = 0;
    if (self.contentMode != UIViewContentModeTop) {
        offsetY = (self.bounds.size.height - _textLayout.contentSize.height)/2;
    }
    CGRect drawRect = CGRectMake(0, offsetY, self.bounds.size.width, _textLayout.contentSize.height);
    [_textLayout drawTextInRect:drawRect];
    [_textLayout drawTextAttachmentInRect:drawRect usingBlock:^(NSUInteger index, NSTextAttachment *attachment, CGRect frame, NSDictionary *attributes) {
        frame.origin.y += offsetY;
        [attachment.image drawInRect:frame];
    }];
}

@end
