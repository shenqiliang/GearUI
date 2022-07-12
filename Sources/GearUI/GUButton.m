//
//  GUButton.m
//  GearUI
//
//  Created by 谌启亮 on 03/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUButton.h"
#import "GUNodeProtocol.h"
#import "NSString+GUValue.h"
#import "UIView+GUPrivate.h"
#import "GUImageLoadDelegate.h"
#import "GUConfigure.h"
#import "GULabel.h"
#import "GUAsyncImageLoader.h"
#import "GUDefines.h"

UIControlState GU_NSStringToUIControlState(NSString *name) {
    NSScanner *scanner = [NSScanner scannerWithString:name];
    UIControlState controlState = UIControlStateNormal;
    while (![scanner isAtEnd]) {
        NSString *upperString = nil;
        BOOL hasUpperString = [scanner scanCharactersFromSet:[NSCharacterSet uppercaseLetterCharacterSet] intoString:&upperString];
        NSString *lowerString = nil;
        BOOL hasLowerString = [scanner scanCharactersFromSet:[NSCharacterSet lowercaseLetterCharacterSet] intoString:&lowerString];
        if (!hasLowerString && !hasUpperString) {
            break;
        }
        NSString *firstPart = [upperString lowercaseString] ?: @"";
        NSString *seconedPart = lowerString ?: @"";
        NSString *stateName = [firstPart stringByAppendingString:seconedPart];
        if ([stateName isEqualToString:@"highlighted"]) {
            controlState = controlState | UIControlStateHighlighted;
        }
        else if ([stateName isEqualToString:@"disabled"]) {
            controlState = controlState | UIControlStateDisabled;
        }
        else if ([stateName isEqualToString:@"selected"]) {
            controlState = controlState | UIControlStateSelected;
        }
        else {
            return UIControlStateReserved;
        }
    }
    return controlState;
}



@interface GULabel()
- (NSDictionary *)gu_textAttributes;
- (NSMutableAttributedString *)generateAttributeTextForGUTextSubNodes:(NSArray *)subNodes inheritAttributes:(NSDictionary *)inheritAttributes;
@end

@interface GUButton ()

@property(nonatomic, strong) id<GUImageLoadOperation> downloadOperation;
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, GUAsyncImageLoader *> *imageLoaders;
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, GUAsyncImageLoader *> *backgroundImageLoaders;

@end

@implementation GUButton {
    UIFont *_titleFont;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageLoaders = [NSMutableDictionary dictionary];
        _backgroundImageLoaders = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (void)initialize {
    [[GUConfigure sharedInstance] setEnumeRepresentation:@{
                                                           @"titleLeft" : @(GUButtonLayoutTypeTitleLeft),
                                                           @"titleRight" : @(GUButtonLayoutTypeTitleRight),
                                                           @"titleTop" : @(GUButtonLayoutTypeTitleTop),
                                                           @"titleBottom" : @(GUButtonLayoutTypeTitleBottom)
                                                           } forPropertyName:@"layoutType" ofClass:self];
    
}

- (NSArray<GUNode *> *)updateSubnodes:(NSArray<GUNode *> *)subnodes {
    if (subnodes.count == 1) {
        [self setTitle:[subnodes.firstObject content] forState:UIControlStateNormal];
    }
    else if ([subnodes count] > 0) {
        GULabel *temp = [GULabel new];
        temp.font = _titleFont;
        temp.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        NSAttributedString *content = [temp generateAttributeTextForGUTextSubNodes:subnodes inheritAttributes:[temp gu_textAttributes]];
        [self setAttributedTitle:content forState:UIControlStateNormal];
        UIColor *selectedTitleColor = [self titleColorForState:UIControlStateSelected];
        if (selectedTitleColor != nil) {
            NSMutableAttributedString *selectedContent = [content mutableCopy];
            [selectedContent addAttribute:NSForegroundColorAttributeName value:selectedTitleColor range:NSMakeRange(0, [content length])];
            [self setAttributedTitle:selectedContent forState:UIControlStateSelected];
        }
    }
    return nil;
}


- (void)updateChildren:(NSArray *)children {
    if (children.count == 1 && [children.firstObject isKindOfClass:[GUNode class]]) {
        [self setTitle:[(GUNode *)children.firstObject content] forState:UIControlStateNormal];
    }
}


- (void)endTrackingWithTouch:(nullable UITouch *)touch withEvent:(nullable UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
    
    if ([self pointInside:[touch locationInView:self] withEvent:event]) {
        void(^bolck)(void)  = ^{
            [self gu_handleViewTap];
        };
        if (_delaysHighlighting) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), bolck);
        }
        else {
            bolck();
        }
    }
}


- (BOOL)updateAttributeValue:(NSString *)value forName:(NSString *)name{
    if ([name isEqualToString:@"titleColor"]) {
        [self setTitleColor:[value gu_UIColorValue] forState:UIControlStateNormal];
        return YES;
    }
    if ([name isEqualToString:@"font"]) {
        _titleFont = [value gu_UIFontValue];
        self.titleLabel.font = _titleFont;
        return YES;
    }
    if ([name isEqual:@"title"] || [name hasSuffix:@"Title"]) {
        NSString *stateString = [name substringToIndex:[name length] - [@"title" length]];
        UIControlState controlState = GU_NSStringToUIControlState(stateString);
        if (controlState != UIControlStateReserved) {
            [self setTitle:value forState:controlState];
            return YES;
        }
    }
    else if ([name isEqual:@"titleColor"] || [name hasSuffix:@"TitleColor"]) {
        NSString *stateString = [name substringToIndex:[name length] - [@"titleColor" length]];
        UIControlState controlState = GU_NSStringToUIControlState(stateString);
        if (controlState != UIControlStateReserved) {
            [self setTitleColor:[value gu_UIColorValue] forState:controlState];
            return YES;
        }
    }
    else if ([name isEqual:@"titleShadowColor"] || [name hasSuffix:@"TitleShadowColor"]) {
        NSString *stateString = [name substringToIndex:[name length] - [@"titleColor" length]];
        UIControlState controlState = GU_NSStringToUIControlState(stateString);
        if (controlState != UIControlStateReserved) {
            [self setTitleShadowColor:[value gu_UIColorValue] forState:controlState];
            return YES;
        }
    }
    else if ([name isEqual:@"backgroundImage"] || [name hasSuffix:@"BackgroundImage"]) {
        NSString *stateString = [name substringToIndex:[name length] - [@"backgroundImage" length]];
        UIControlState controlState = GU_NSStringToUIControlState(stateString);
        if (controlState != UIControlStateReserved) {
            GUAsyncImageLoader *imageLoader = [self.backgroundImageLoaders objectForKey:@(controlState)];
            if (imageLoader == nil) {
                __weak GUButton *weakSelf = self;
                imageLoader = [[GUAsyncImageLoader alloc] initWithUpdateImageHandler:^(UIImage *image) {
                    [weakSelf _setBackgroundImage:[value gu_UIImageValue] forState:controlState];
                } imageView:self.imageView];
                self.backgroundImageLoaders[@(controlState)] = imageLoader;
            }
            imageLoader.content = value;
            return YES;
        }
    }
    else if ([name isEqual:@"image"] || [name hasSuffix:@"Image"]) {
        NSString *stateString = [name substringToIndex:[name length] - [@"image" length]];
        UIControlState controlState = GU_NSStringToUIControlState(stateString);
        if (controlState != UIControlStateReserved) {
            GUAsyncImageLoader *imageLoader = [self.imageLoaders objectForKey:@(controlState)];
            if (imageLoader == nil) {
                __weak GUButton *weakSelf = self;
                imageLoader = [[GUAsyncImageLoader alloc] initWithUpdateImageHandler:^(UIImage *image) {
                    [weakSelf _setImage:image forState:controlState];
                } imageView:self.imageView];
                self.imageLoaders[@(controlState)] = imageLoader;
            }
            imageLoader.content = value;
            return YES;
        }
    }

    return NO;
}

- (void)_setImage:(UIImage *)image forState:(UIControlState)state {
    [super setImage:image forState:state];
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state {
    [super setImage:image forState:state];
    [self.imageLoaders[@(state)] invalidate];
}

- (void)_setBackgroundImage:(UIImage *)image forState:(UIControlState)state {
    [super setBackgroundImage:image forState:state];
}

- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state {
    [super setBackgroundImage:image forState:state];
    [self.backgroundImageLoaders[@(state)] invalidate];
}

- (void)setHighlighted:(BOOL)highlighted {
    if (highlighted || !_delaysHighlighting) {
        [super setHighlighted:highlighted];
    }
    else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [super setHighlighted:highlighted];

        });
    }
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    if (_layoutType == GUButtonLayoutTypeTitleBottom) {
        CGSize titleSize = [self.currentTitle sizeWithAttributes:@{NSFontAttributeName: _titleFont ?: [UIFont systemFontOfSize:15]}];
        CGSize imageSize = self.currentImage.size;
        CGRect rect = CGRectMake((contentRect.size.width-titleSize.width)/2+contentRect.origin.x, (contentRect.size.height-titleSize.height-imageSize.height)/2+contentRect.origin.y+imageSize.height, titleSize.width, titleSize.height);
        return UIEdgeInsetsInsetRect(rect, self.titleEdgeInsets);
    }
    else if (_layoutType == GUButtonLayoutTypeTitleLeft) {
        CGSize titleSize = [self.currentTitle sizeWithAttributes:@{NSFontAttributeName: _titleFont ?: [UIFont systemFontOfSize:15]}];
        CGRect rect = CGRectMake(0+contentRect.origin.x, (contentRect.size.height-titleSize.height)/2+contentRect.origin.y, titleSize.width, titleSize.height);
        return UIEdgeInsetsInsetRect(rect, self.titleEdgeInsets);
    }
    else if (_layoutType == GUButtonLayoutTypeTitleTop) {
        CGSize titleSize = [self.currentTitle sizeWithAttributes:@{NSFontAttributeName: _titleFont ?: [UIFont systemFontOfSize:15]}];
        CGSize imageSize = self.currentImage.size;
        CGRect rect = CGRectMake((contentRect.size.width-titleSize.width)/2+contentRect.origin.x, (contentRect.size.height-titleSize.height-imageSize.height)/2+contentRect.origin.y, titleSize.width, titleSize.height);
        return UIEdgeInsetsInsetRect(rect, self.titleEdgeInsets);
    }
    else {
        return [super titleRectForContentRect:contentRect];
    }
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    if (_layoutType == GUButtonLayoutTypeTitleBottom) {
        CGSize titleSize = [self.currentTitle sizeWithAttributes:@{NSFontAttributeName: _titleFont ?: [UIFont systemFontOfSize:15]}];
        CGSize imageSize = self.currentImage.size;
        CGRect rect = CGRectMake((contentRect.size.width-imageSize.width)/2+contentRect.origin.x, (contentRect.size.height-titleSize.height-imageSize.height)/2+contentRect.origin.y, imageSize.width, imageSize.height);
        return UIEdgeInsetsInsetRect(rect, self.imageEdgeInsets);
    }
    else if (_layoutType == GUButtonLayoutTypeTitleLeft) {
        CGSize imageSize = self.currentImage.size;
        CGRect rect = CGRectMake(contentRect.size.width-imageSize.width+contentRect.origin.x, (contentRect.size.height - imageSize.height)/2+contentRect.origin.y, imageSize.width, imageSize.height);
        return UIEdgeInsetsInsetRect(rect, self.imageEdgeInsets);
    }
    else if (_layoutType == GUButtonLayoutTypeTitleTop) {
        CGSize titleSize = [self.currentTitle sizeWithAttributes:@{NSFontAttributeName: _titleFont ?: [UIFont systemFontOfSize:15]}];
        CGSize imageSize = self.currentImage.size;
        CGRect rect = CGRectMake((contentRect.size.width-imageSize.width)/2+contentRect.origin.x, (contentRect.size.height-titleSize.height-imageSize.height)/2+titleSize.height+contentRect.origin.y, imageSize.width, imageSize.height);
        return UIEdgeInsetsInsetRect(rect, self.imageEdgeInsets);
    }
    else {
        return [super imageRectForContentRect:contentRect];
    }
}

- (CGSize)intrinsicContentSize {
    if (_layoutType == GUButtonLayoutTypeTitleBottom || _layoutType == GUButtonLayoutTypeTitleTop) {
        CGSize titleSize = [self.currentTitle sizeWithAttributes:@{NSFontAttributeName: _titleFont ?: [UIFont systemFontOfSize:15]}];
        CGSize imageSize = self.currentImage.size;
        CGFloat maxWidth = MAX(titleSize.width, imageSize.width);
        CGFloat height = titleSize.height + imageSize.height;
        UIEdgeInsets contentEdgeInsets = self.contentEdgeInsets;
        return CGSizeMake(maxWidth + contentEdgeInsets.left + contentEdgeInsets.right, height + contentEdgeInsets.top + contentEdgeInsets.bottom);
    }
    return [super intrinsicContentSize];
}

@end
