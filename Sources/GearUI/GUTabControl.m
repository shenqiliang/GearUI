//
//  GUTabControl.m
//  GearUI
//
//  Created by sidetang on 2017/10/1.
//  Copyright © 2017年 谌启亮. All rights reserved.
//

#import "GUTabControl.h"
#import "UIView+GUPrivate.h"

@interface GUTabControl()

@property (nonatomic,strong) UIImageView *indicatorView;
@property (nonatomic) CGPoint originCenter;

@end

@implementation GUTabControl {
    NSMutableArray *_buttons;
    CFTimeInterval _animationStartTime;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _titleColor = [UIColor whiteColor];
        _selectedTitleColor = [UIColor whiteColor];
        _indicatorColor = [UIColor whiteColor];
        _buttons = [NSMutableArray array];
        _titleFont = [UIFont boldSystemFontOfSize:17];
        _indicatorSize = CGSizeMake(33, 2);
        [self addTarget:self action:@selector(gu_valueChanged) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void)gu_valueChanged {
    if ([_action isKindOfClass:[NSString class]] && [_action length]) {
        [self gu_runAction:_action];
    }
}


- (void)setSelectedIndex:(NSInteger)selectedIndex {
    [self setSelectedIndex:selectedIndex animated:NO];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated
{
    if (selectedIndex < _items.count && selectedIndex >= 0) {
        _selectedIndex = selectedIndex;
    }
    [self setNeedsLayout];
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self layoutIfNeeded];
        }];
    }
}

- (void)setSelectedTitleColor:(UIColor *)color{
    _selectedTitleColor = color;
    [self setNeedsLayout];
}

- (void)setTitleColor:(UIColor *)color {
    _titleColor = color;
    [self setNeedsLayout];
}

- (void)setItems:(NSArray<NSString *> *)titles {
    
    if ([titles isKindOfClass:[NSString class]]) {
        titles = [(NSString *)titles componentsSeparatedByString:@";"];
    }
    
    NSArray<NSString *> *array = [titles copy];
    _items = array;
    
    if (_selectedIndex >= _items.count) {
        _selectedIndex = 0;
    }
    
    [_buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_buttons removeAllObjects];
    
    for (int i = 0; i < _items.count; i++) {
        UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:[_items objectAtIndex:i] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        [_buttons addObject:button];
    }
    
    [self setNeedsLayout];
}

- (void)buttonTapped:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        NSUInteger index = [_buttons indexOfObject:button];
        if (index != NSNotFound) {
            [self setSelectedIndex:index animated:_enableAnimation];
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }
}

- (void)setIndicatorImage:(UIImage *)indicatorImage {
    _indicatorImage = indicatorImage;
    [self _updateIndicatorContent];
}

- (void)setIndicatorColor:(UIColor *)indicatorColor {
    _indicatorColor = indicatorColor;
    [self _updateIndicatorContent];
}

- (void)setIndicatorSize:(CGSize)indicatorSize {
    _indicatorSize = indicatorSize;
    CGRect indicatorFrame = _indicatorView.frame;
    indicatorFrame.size = indicatorSize;
    _indicatorView.frame = indicatorFrame;
    [self setNeedsLayout];
}


- (void)_updateIndicatorContent {
    if (_indicatorImage == nil) {
        _indicatorView.image = nil;
        _indicatorView.backgroundColor = _indicatorColor;
    }
    else {
        _indicatorView.image = _indicatorImage;
        _indicatorView.backgroundColor = [UIColor clearColor];
    }
}

- (UIImageView *)indicatorView {
    if (_indicatorView == nil) {
        _indicatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _indicatorSize.width, _indicatorSize.height)];
        [self _updateIndicatorContent];
        [self addSubview:_indicatorView];
    }
    return _indicatorView;
}

- (void)layoutSubviews {
    CGFloat buttonWidth = _itemWidth;
    if (buttonWidth <= __FLT_EPSILON__ && _items.count > 0) {
        buttonWidth = (self.bounds.size.width - (_items.count-1) * _itemSpace) / (CGFloat)_items.count;
    }
    CGFloat offsetX = (self.bounds.size.width - (_items.count-1) * _itemSpace - buttonWidth * _items.count)/2;
    for (int i = 0; i < _buttons.count; i++) {
        UIButton* button = _buttons[i];
        if (i == _selectedIndex) {
            [button setTitleColor:_selectedTitleColor forState:UIControlStateNormal];
            button.titleLabel.font = _selectedTitleFont ?: _titleFont;
        }
        else {
            [button setTitleColor:_titleColor forState:UIControlStateNormal];
            button.titleLabel.font = _titleFont;
        }
        button.frame = CGRectMake(offsetX + (buttonWidth+_itemSpace)*i, 0, buttonWidth, self.bounds.size.height);
    }

    if (_selectedIndex >= 0 && _selectedIndex < _buttons.count) {
        self.indicatorView.hidden = NO;
        self.indicatorView.center = CGPointMake(offsetX + (buttonWidth+_itemSpace)*_selectedIndex + (buttonWidth / 2.0), self.bounds.size.height - _indicatorSize.height/2);
    }
    else {
        self.indicatorView.hidden = YES;
    }
}

- (CGSize)intrinsicContentSize {
    if (_itemWidth > 0) {
        return CGSizeMake(_itemWidth*_items.count+_itemSpace*(_items.count-1), UIViewNoIntrinsicMetric);
    }
    else {
        return [super intrinsicContentSize];
    }
}

@end
