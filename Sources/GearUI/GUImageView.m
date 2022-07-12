//
//  GUImageView.m
//  GearUI
//
//  Created by 谌启亮 on 03/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUImageView.h"
#import "GUImageLoadDelegate.h"
#import "GUConfigure.h"
#import "NSString+GUValue.h"
#import "GUAsyncImageLoader.h"
#import "GUDefines.h"

@interface GUImageView ()


@end

@implementation GUImageView
{
    CALayer *_highlightCover;
    GUAsyncImageLoader *_imageLoader;
}

FORWARD_PROPERTY(placeholderImage, setPlaceholderImage:, placeholderImage, UIImage*, _imageLoader)
FORWARD_PROPERTY(useFadeTransition, setUseFadeTransition:, useFadeTransition, BOOL, _imageLoader)
FORWARD_PROPERTY(content, setContent:, content, NSString*, _imageLoader)


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        _imageLoader = [[GUAsyncImageLoader alloc] initWithTarget:self setter:@selector(_setImage:) imageView:self];
    }
    return self;
}

- (void)_setImage:(UIImage *)image {
    [super setImage:image];
}

- (void)setImage:(UIImage *)image {
    [super setImage:image];
    [_imageLoader invalidate];
}

- (BOOL)updateAttributeValue:(NSString *)value forName:(NSString *)name {
    if ([name isEqualToString:@"image"] && [value isKindOfClass:[NSString class]]) {
        self.content = value;
        return YES;
    }
    return NO;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)updateChildren:(NSArray *)children {
    NSString *text = [(GUNode *)children.firstObject text];
    if (text.length > 0) {
        self.content = [(GUNode *)children.firstObject text];
    }
}

- (void)setAnimationDuration:(NSTimeInterval)animationDuration {
    [super setAnimationDuration:animationDuration];
    if ([self.image.images count] > 1 && animationDuration > __FLT_EPSILON__) {
        self.image = [UIImage animatedImageWithImages:self.image.images duration:animationDuration];
    }
}

- (void)cancelImageRequest {
    [_imageLoader cancelImageRequest];
}


- (void)setHighlightedCoverColor:(UIColor *)highlightedCoverColor {
    if (_highlightedCoverColor != highlightedCoverColor) {
        _highlightedCoverColor = highlightedCoverColor;
        if (_highlightCover == nil) {
            _highlightCover = [CALayer layer];
            _highlightCover.frame = self.bounds;
        }
        _highlightCover.backgroundColor = _highlightedCoverColor.CGColor;
    }
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    if (!hidden) {
        if ([self.image.images count] && !self.isAnimating) {
            UIImage *image = self.image;
            self.image = nil;
            self.image = image;
        }
        [self startAnimating];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _highlightCover.frame = self.bounds;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted) {
        [self.layer addSublayer:_highlightCover];
    }
    else {
        [_highlightCover removeFromSuperlayer];
    }
}

@end
