//
//  GUTextLayout.m
//  TBText
//
//  Created by 谌启亮 on 15/9/17.
//  Copyright (c) 2015年 谌启亮. All rights reserved.
//

#import "GUTextLayout.h"
#import <CoreText/CoreText.h>

// 表情缩放
#define FACE_SCALE 1.0

// CTRunCallbacks, 使用Dict保存CTRun的的ascent、descent、width
static void TTElementNodeRunDelegateDeallocCallback(void *ref) {
    CFRelease(ref);
}
static CGFloat TTElementNodeRunDelegateAscentCallback(void *ref) {
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"ascent"] floatValue];
}
static CGFloat TTElementNodeRunDelegateDescentCallback(void *ref) {
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"descent"] floatValue];
}
static CGFloat TTElementNodeRunDelegateWidthCallback(void *ref) {
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"width"] floatValue];
    
}
static CTRunDelegateCallbacks callbacks = {kCTRunDelegateCurrentVersion, TTElementNodeRunDelegateDeallocCallback, TTElementNodeRunDelegateAscentCallback, TTElementNodeRunDelegateDescentCallback, TTElementNodeRunDelegateWidthCallback};

CTRunDelegateCallbacks *TTElementNodeDefaultRunDelegateCallbacksRef = &callbacks;


static CGFloat scale = 1;
static inline CGFloat guceil(CGFloat value) {
    return ceil(value*scale)/scale;
}


@interface GUTextLayout ()

@property(nonatomic, getter=isTruncated, readwrite) BOOL truncated;

@end

@implementation GUTextLayout{
    CFMutableArrayRef _lines;
    CTTypesetterRef _typesetter;
    BOOL _needUpdateLines;
    CGSize _cacheContentSize;
    CGFloat _capHeight;
    CGFloat _ascent;
    CGFloat _descent;
    CGFloat _fistLineAscent;
    CGFloat _fontPointSize;
    CGFloat _lastLineDescent;
    CGFloat _fontLineHeight;
    NSMutableAttributedString *_attributedString;
    NSMutableIndexSet *_textAttachmentIndexs;
}

+ (void)initialize {
    scale = [UIScreen mainScreen].scale;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lines = CFArrayCreateMutable(NULL, 10, &kCFTypeArrayCallBacks);
        _textAttachmentIndexs = [NSMutableIndexSet new];
        _lineBreakMode = NSLineBreakByTruncatingTail;
        _numberOflines = 1;
    }
    return self;
}

- (void)setAttributedString:(NSAttributedString *)attributedString{
    [_textAttachmentIndexs removeAllIndexes];
    CFArrayRemoveAllValues(_lines);
    _attributedString = [attributedString mutableCopy];
    if ([_attributedString length]) {
        NSDictionary *attribute = [_attributedString attributesAtIndex:0 effectiveRange:NULL];
        UIFont *font = (UIFont *)attribute[NSFontAttributeName];
        _fontLineHeight = [font lineHeight];
        _capHeight = [font capHeight];
        _ascent = font.ascender;
        _descent = ABS(font.descender);
        _fontPointSize = font.pointSize;
        _fistLineAscent = 0;
        _lastLineDescent = 0;
        [self invalidLines];
        [_attributedString beginEditing];
        [attributedString enumerateAttribute:@"NSAttachment" inRange:NSMakeRange(0, [attributedString length]) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
            if ([value isKindOfClass:[NSTextAttachment class]]) {
                NSTextAttachment *textAttachment = value;
                CGFloat height = textAttachment.image.size.height;
                CGFloat decent = (height-_capHeight)/2;
                CTRunDelegateRef delegate = CTRunDelegateCreate(TTElementNodeDefaultRunDelegateCallbacksRef, (void *)CFBridgingRetain(@{@"width":@(textAttachment.image.size.width), @"ascent":@(height-decent), @"descent":@(decent)}));
                [_attributedString addAttribute:(NSString *)kCTRunDelegateAttributeName value:CFBridgingRelease(delegate) range:range];
                [_textAttachmentIndexs addIndex:range.location];
            }
        }];
        [_attributedString endEditing];
    }
    if(_typesetter) CFRelease(_typesetter);
    _typesetter = nil;
}

- (NSAttributedString *)attributedString {
    return _attributedString;
}

- (void)invalidLines {
    _needUpdateLines = YES;
}

- (void)setPreferredMaxWidth:(CGFloat)preferredMaxWidth{
    if (ABS(_preferredMaxWidth-preferredMaxWidth)>__FLT_EPSILON__) {
        if (_truncated) {
            [self invalidLines];
        }
        else{
            if (preferredMaxWidth > _cacheContentSize.width && _cacheContentSize.width > __FLT_EPSILON__) { //变宽
                if (CFArrayGetCount(_lines) > 1) {
                    [self invalidLines];
                }
            }
            else{ //变窄
                if (preferredMaxWidth < _cacheContentSize.width) {
                    [self invalidLines];
                }
            }
        }
        _preferredMaxWidth = preferredMaxWidth;
    }
}

- (void)setNumberOflines:(NSUInteger)numberOflines{
    if (_numberOflines != numberOflines) {
        _numberOflines = numberOflines;
        if (CFArrayGetCount(_lines) != numberOflines) {
            [self invalidLines];
        }
    }
}

- (void)adjustFromFontSize:(CGFloat)fromFontSize toFontSize:(CGFloat)toFontSize {
    CGFloat delta = (fromFontSize-toFontSize)/2;
    CGFloat checkFontSize = toFontSize + delta;
    if (![self fitWidthTestForFontSize:checkFontSize]) { //显示不下
        _typesetter = nil;
        [self adjustFromFontSize:checkFontSize toFontSize:toFontSize];
    }
    else {
        if (fromFontSize/toFontSize < 1.1) {
            return;
        }
        else {
            _typesetter = nil;
            [self adjustFromFontSize:fromFontSize toFontSize:checkFontSize];
        }
    }
}

- (BOOL)fitWidthTestForFontSize:(CGFloat)fontSize {
    NSAttributedString *attributeText = [_attributedString copy];
    [attributeText enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, attributeText.length) options:NSAttributedStringEnumerationReverse usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        UIFont *font = value;
        [_attributedString removeAttribute:NSFontAttributeName range:range];
        [_attributedString addAttribute:NSFontAttributeName value:[font fontWithSize:fontSize] range:range];
    }];
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)_attributedString);
    CFIndex count = CTTypesetterSuggestLineBreak(typesetter, 0, _preferredMaxWidth);
    return [attributeText length] <= count;
}

- (void)setAdjustsFontSizeToFitWidth:(BOOL)adjustsFontSizeToFitWidth {
    if (_adjustsFontSizeToFitWidth != adjustsFontSizeToFitWidth) {
        _adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth;
        [self invalidLines];
    }
}

- (void)buildLines{
    
    _truncated = NO;
    
    CFArrayRemoveAllValues(_lines);

    NSString *string = [_attributedString string];
    
    NSUInteger stringLength = [_attributedString length];
    if (stringLength) {
        
        if (_adjustsFontSizeToFitWidth && _numberOflines == 1 && _fontPointSize > 1 && _preferredMaxWidth < 10000) {
            if (![self fitWidthTestForFontSize:_fontPointSize]) {
                [_attributedString beginEditing];
                [self adjustFromFontSize:_fontPointSize toFontSize:1];
                [_attributedString endEditing];
            }
        }
        

        if (_typesetter == nil) {
            _typesetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)_attributedString);
        }
        
        CGFloat maxWidth = _preferredMaxWidth;
        if (maxWidth < __FLT_EPSILON__) {
            maxWidth = 100000;
        }
        
        NSInteger maxLines = _numberOflines;
        if (_numberOflines <= 0) {
            maxLines = 10000;
        }
        
        CFIndex startIndex = 0;
        BOOL isBreakByLineWarp = NO;
        
        CGFloat maxLineWidth = 0;
        
        int i = 0;
        
        _fistLineAscent = _lastLineDescent = 0;
        
        for (; i < maxLines; i++) {
            if (startIndex < stringLength) {
                CFIndex count = 0;
                if (_lineBreakMode == NSLineBreakByCharWrapping) {
                    count = CTTypesetterSuggestClusterBreak(_typesetter, startIndex, maxWidth);
                }
                else{
                    count = CTTypesetterSuggestLineBreak(_typesetter, startIndex, maxWidth);
                }
                
                unichar c = [string characterAtIndex:startIndex+count-1];
                if (![[NSCharacterSet newlineCharacterSet] characterIsMember:c] && startIndex < stringLength) {
                    isBreakByLineWarp = YES;
                }

                CTLineRef line = NULL;
                
                if (i == maxLines-1 && startIndex+count < stringLength) { //最后一行, 并且显示不下
                    CTLineRef rawLine = CTTypesetterCreateLine(_typesetter, CFRangeMake(startIndex, stringLength-startIndex));
                    NSAttributedString *truncatedString = _truncationString;
                    if (_truncationString == nil) {
                        truncatedString = [[NSAttributedString alloc] initWithString:@"…" attributes:nil];
                    }
                    NSDictionary *attributes = [truncatedString attributesAtIndex:0 effectiveRange:NULL];
                    NSDictionary *lastCharecterAttributes = [_attributedString attributesAtIndex:startIndex+count-1 effectiveRange:NULL];
                    NSMutableDictionary *resultAttributes = [NSMutableDictionary dictionaryWithDictionary:lastCharecterAttributes];
                    [resultAttributes addEntriesFromDictionary:attributes];
                    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithAttributedString:truncatedString];
                    [attrString setAttributes:resultAttributes range:NSMakeRange(0, [attrString length])];
                    truncatedString = [[NSAttributedString alloc] initWithAttributedString:attrString];
                    CTLineRef truncatedLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncatedString);
                    line = CTLineCreateTruncatedLine(rawLine, maxWidth, kCTLineTruncationEnd, truncatedLine);
                    if (line == nil) {
                        line = CFRetain(rawLine);
                    }
                    else{
                        _truncated = YES;
                    }
                    CFRelease(rawLine);
                    CFRelease(truncatedLine);
                }
                else {
                    if (isBreakByLineWarp || count <= 1) {
                        line = CTTypesetterCreateLine(_typesetter, CFRangeMake(startIndex, count));
                    }
                    else {
                        line = CTTypesetterCreateLine(_typesetter, CFRangeMake(startIndex, count - 1));
                    }
                }
                
                if (i == 0 && (count == stringLength || maxLines==1)) { //第一行并且是最后一行
                    CGFloat lineWidth = CTLineGetTypographicBounds(line, &_fistLineAscent, &_lastLineDescent, NULL);
                    maxLineWidth = MAX(lineWidth, maxLineWidth);
                }
                else if (i == 0) { //第一行
                    CGFloat lineWidth = CTLineGetTypographicBounds(line, &_fistLineAscent, NULL, NULL);
                    maxLineWidth = MAX(lineWidth, maxLineWidth);
                }
                else if (i == maxLines-1 || startIndex+count >= stringLength) { //最后一行
                    CGFloat lineWidth = CTLineGetTypographicBounds(line, NULL, &_lastLineDescent, NULL);
                    maxLineWidth = MAX(lineWidth, maxLineWidth);
                }
                else{
                    CGFloat lineWidth = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
                    maxLineWidth = MAX(lineWidth, maxLineWidth);
                }
                
                CFArrayAppendValue(_lines, line);
                CFRelease(line);
                
                


                startIndex+=count;
                
            }
            else{
                break;
            }
        }
        
        
        if (i > 0){
            if (maxLineWidth+1 < maxWidth) {
                maxLineWidth+=1;
            }
            _cacheContentSize.width = guceil(maxLineWidth);
            
            
            CGFloat lineHeight = _fontLineHeight;
            
            // 自定义行高计算
            if (_lineHeight > __FLT_EPSILON__) {
                // 当自定义行高fistLineAscent大于自定计算的值时，使用自定义值
                CGFloat userFirstLineAscent = (_lineHeight - _fontLineHeight)/2 + _ascent;
                if (userFirstLineAscent > _fistLineAscent) {
                    _fistLineAscent = userFirstLineAscent;
                }
                // 当自定义行高lastLineDescent大于自定计算的值时，使用自定义值
                CGFloat userLastLineDescent = (_lineHeight - _fontLineHeight)/2 + _descent;
                if (userLastLineDescent > _lastLineDescent) {
                    _lastLineDescent = userLastLineDescent;
                }
                lineHeight = _lineHeight;
            }
            _cacheContentSize.height = guceil((i-1)*(lineHeight+_lineSpace)+_fistLineAscent+_lastLineDescent);
        }
        else{
            _cacheContentSize = CGSizeZero;
        }
    }
    
    _needUpdateLines = NO;
}

- (void)updateLinesIfNeed{
    if (_needUpdateLines) {
        [self buildLines];
    }
}

- (CGRect)attachmentRectAtIndex:(NSInteger)index size:(CGSize)size{
    [self updateLinesIfNeed];
    
    CGFloat offsetY = _fistLineAscent;
    CGFloat lineHeight = _fontLineHeight;
    if (_lineHeight > __FLT_EPSILON__) {
        lineHeight = _lineHeight;
    }

    CFIndex lineCount = CFArrayGetCount(_lines);
    
    for (int i = 0; i < lineCount; i++) {
        CTLineRef line = CFArrayGetValueAtIndex(_lines, i);
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        for (int r = 0; r < CFArrayGetCount(runs); r++) {
            CTRunRef run = CFArrayGetValueAtIndex(runs, r);
            CFRange range = CTRunGetStringRange(run);
            if (range.location <= index && range.location+range.length > index) {
                if (_truncated && r == CFArrayGetCount(runs)-1 && i == (int)lineCount-1) {
                    return CGRectZero;
                }
                CGFloat lineAcent = 0;
                CGFloat lineWidth = CTLineGetTypographicBounds(line, &lineAcent, NULL, NULL);

                CGPoint pos = CGPointZero;
                CTRunGetPositions(run, CFRangeMake(0, 1), &pos);
                CGFloat offsetX = pos.x;
                offsetY -= pos.y;
                if (_textAlignment == NSTextAlignmentCenter){
                    offsetX+=(size.width-lineWidth)/2;
                }
                
                CGFloat ascent, descent, leading;
                CGFloat width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, &leading);
                CGRect bounds = CGRectMake(offsetX, offsetY-ascent, width, ascent+descent);
                return bounds;
            }
        }
        offsetY+=(lineHeight+_lineSpace);
    }
    return CGRectZero;
}

- (void)setLineSpace:(CGFloat)lineSpace {
    if (_lineSpace != lineSpace) {
        _lineSpace = lineSpace;
        _needUpdateLines = YES;
    }
}

- (void)setLineHeight:(CGFloat)lineHeight {
    if (_lineHeight != lineHeight) {
        _lineHeight = lineHeight;
        _needUpdateLines = YES;
    }
}


- (NSUInteger)displayedNumberOfLines{
    [self updateLinesIfNeed];
    return (NSUInteger)CFArrayGetCount(_lines);
}


- (CGSize)contentSize{
    [self updateLinesIfNeed];
    return _cacheContentSize;
}

- (void)drawTextInRect:(CGRect)rect{
    [self updateLinesIfNeed];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CFIndex count = CFArrayGetCount(_lines);
    
    CGFloat lineHeight = _fontLineHeight;
    if (_lineHeight > __FLT_EPSILON__) {
        lineHeight = _lineHeight;
    }

    
    //绘制背景
    if (_highlightedTextRange.length > 0 && _highlightedBackgroundColor != nil) {
        CGFloat offsetY = (_fistLineAscent-_ascent);
        for (int i = 0; i < count; i++) {
            CTLineRef line = CFArrayGetValueAtIndex(_lines, i);
            CFRange lineRange = CTLineGetStringRange(line);
            
            NSRange insetRange;
            insetRange.location = MAX(lineRange.location, _highlightedTextRange.location);
            insetRange.length = MIN(lineRange.location+lineRange.length, _highlightedTextRange.location+_highlightedTextRange.length)-insetRange.location;
            
            if (insetRange.length > 0) {
                CGFloat offsetX1 = CTLineGetOffsetForStringIndex(line, insetRange.location, NULL);
                CGFloat offsetX2 = 0;
                if (insetRange.location+insetRange.length < lineRange.location+lineRange.length) {
                    offsetX2 = CTLineGetOffsetForStringIndex(line, insetRange.location+insetRange.length, NULL);
                }
                else{
                    offsetX2 = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
                }
                [_highlightedBackgroundColor setFill];
                [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(offsetX1, offsetY, offsetX2-offsetX1, _ascent+_descent) cornerRadius:2] fill];
            }
            
            offsetY+=(lineHeight+_lineSpace);
        }
    }

    //绘制文字
    CGPoint point = rect.origin;
    if (count) {
        point.y += _fistLineAscent;
        CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1, -1));
        for (int i = 0; i < count; i++) {
            CTLineRef line = CFArrayGetValueAtIndex(_lines, i);
            if (_textAlignment == NSTextAlignmentLeft) {
                CGContextSetTextPosition(context, point.x, point.y+(lineHeight+_lineSpace)*i);
            }
            else if (_textAlignment == NSTextAlignmentCenter){
                CGFloat lineWidth = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
                CGContextSetTextPosition(context, point.x+(rect.size.width-lineWidth)/2, point.y+(lineHeight+_lineSpace)*i);
            }
            else if (_textAlignment == NSTextAlignmentRight){
                CGFloat lineWidth = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
                CGContextSetTextPosition(context, point.x+(rect.size.width-lineWidth), point.y+(lineHeight+_lineSpace)*i);
            }
            CTLineDraw(line, context);
        }
    }
    
    CGContextRestoreGState(context);
}

- (NSUInteger)characterIndexAtPoint:(CGPoint)point size:(CGSize)size {
    [self updateLinesIfNeed];
    
    CGFloat lineHeight = _fontLineHeight;
    if (_lineHeight > __FLT_EPSILON__) {
        lineHeight = _lineHeight;
    }

    point.y-=(_fistLineAscent-_ascent);
    
    CGFloat fontHeight = _ascent+_descent;
    NSInteger lineIndex = point.y/(lineHeight+_lineSpace);
    CFIndex count = CFArrayGetCount(_lines);
    CGFloat offsetY = fmod(point.y, lineHeight);
    if (offsetY < fontHeight && lineIndex >= 0 && lineIndex < count) {
        CTLineRef line = CFArrayGetValueAtIndex(_lines, lineIndex);
        CGFloat lineWidth = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
        if (_textAlignment == NSTextAlignmentCenter){
            point.x -= (size.width-lineWidth)/2;
        }
        else if (_textAlignment == NSTextAlignmentRight){
            point.x -= (size.width-lineWidth);
        }
        NSUInteger index = CTLineGetStringIndexForPosition(line, CGPointMake(point.x, offsetY));
        if ((point.x < CTLineGetOffsetForStringIndex(line, index, NULL)) && (index>0))
        {
            --index;
        }
        return index;
    }
    return NSNotFound;
}



- (void)dealloc
{
    CFRelease(_lines);
    if (_typesetter) CFRelease(_typesetter);
}

- (void)drawTextAttachmentInRect:(CGRect)rect usingBlock:(void (^)(NSUInteger index, NSTextAttachment *attachment, CGRect frame, NSDictionary *attributes))block {
    [_textAttachmentIndexs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        CGRect frame = [self attachmentRectAtIndex:idx size:rect.size];
        if (!CGRectIsNull(frame)) {
            NSDictionary *attributes = [_attributedString attributesAtIndex:idx effectiveRange:NULL];
            NSTextAttachment *attachment = attributes[@"NSAttachment"];
            if (block != nil) {
                block(idx, attachment, frame, attributes);
            }
        }
    }];
}


@end
