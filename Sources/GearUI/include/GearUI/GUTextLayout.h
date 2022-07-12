//
//  GUTextLayout.h
//  TBText
//
//  Created by 谌启亮 on 15/9/17.
//  Copyright (c) 2015年 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>

/// 文本布局对象，用于GULabel的自定义高速布局引擎
@interface GUTextLayout : NSObject

//设置attributestring
@property (nonatomic, copy) NSAttributedString *attributedString;

//设置适合显示的最大宽度
@property (nonatomic) CGFloat preferredMaxWidth;

//设置高亮背景的文字范围
@property (nonatomic) NSRange highlightedTextRange;

//高亮文字背景颜色
@property (nonatomic) UIColor *highlightedBackgroundColor;

//返回布局的大小
- (CGSize)contentSize;

//显示行数, 根据preferredMaxWidth计算。
@property (nonatomic, readonly) NSUInteger displayedNumberOfLines;

//是否截断, 根据preferredMaxWidth计算。
@property (nonatomic, getter=isTruncated, readonly) BOOL truncated;

//设置最大行数
@property (nonatomic) NSUInteger numberOflines;

//绘制文本
- (void)drawTextInRect:(CGRect)rect;
- (void)drawTextAttachmentInRect:(CGRect)rect usingBlock:(void (^)(NSUInteger index, NSTextAttachment *attachment, CGRect frame, NSDictionary *attributes))block;

//换行模式
@property (nonatomic) NSLineBreakMode lineBreakMode;

//行间距
@property (nonatomic) CGFloat lineSpace;

//行高
@property (nonatomic) CGFloat lineHeight;


//计算字符大小
- (CGRect)attachmentRectAtIndex:(NSInteger)index size:(CGSize)size;

//更据位置返回该位置字符索引
- (NSUInteger)characterIndexAtPoint:(CGPoint)point size:(CGSize)size;

// 截断显示的字符，默认“”
@property(nonatomic, strong) NSAttributedString *truncationString;

@property(nonatomic) NSTextAlignment textAlignment;

@property(nonatomic) BOOL adjustsFontSizeToFitWidth;


@end
