//
//  GUSlideBar.m
//  GearUI
//
//  Created by harmanhuang on 2017/10/23.
//  Copyright © 2017年 谌启亮. All rights reserved.
//

#import "GUSlideBar.h"
#import "GUSlideBarItem.h"
#import "UIView+Additions.h"

#define DEVICE_WIDTH CGRectGetWidth([UIScreen mainScreen].bounds)
#define DEFAULT_SLIDER_COLOR [UIColor orangeColor]
#define SLIDER_VIEW_HEIGHT 1.5
#define DEFAULT_ITEM_SPACE 38.0f
#define FDSlideBarMaxWidth DEVICE_WIDTH

@interface GUSlideBar () <GUSlideBarItemDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) NSMutableArray *items;
@property (strong, nonatomic) UIView *sliderView;
@property (strong, nonatomic) UIView *bottomLineView;

@property (strong, nonatomic) GUSlideBarItem *selectedItem;
@property (strong, nonatomic) GUSlideBarItemSelectedCallback callback;

@end

@implementation GUSlideBar

- (instancetype)init {
    CGRect frame = CGRectMake(0, 0, FDSlideBarMaxWidth, 40);
    return [self initWithFrame:frame];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self= [super initWithFrame:frame]) {
        _items = [NSMutableArray array];
        [self initScrollView];
        [self initSliderView];
    }
    return self;
}

#pragma - mark Custom Accessors

- (void)setItemsTitle:(NSArray *)itemsTitle {
    _itemsTitle = itemsTitle;
    [self setupItems];
}

- (void)setItemColor:(UIColor *)itemColor {
    for (GUSlideBarItem *item in _items) {
        [item setItemTitleColor:itemColor];
    }
}

- (void)setItemSelectedColor:(UIColor *)itemSelectedColor {
    for (GUSlideBarItem *item in _items) {
        [item setItemSelectedTitleColor:itemSelectedColor];
    }
}

- (void)setSliderColor:(UIColor *)sliderColor {
    _sliderColor = sliderColor;
    self.sliderView.backgroundColor = _sliderColor;
}

- (void)setSelectedItem:(GUSlideBarItem *)selectedItem {
    if (_selectedItem == selectedItem) {
        return;
    }
    _selectedItem.selected = NO;
    _selectedItem = selectedItem;
}

- (void)setTitleFontSize:(CGFloat)titleFontSize {
    for (GUSlideBarItem *item in _items) {
        [item setItemTitleFont:titleFontSize];
    }
}

- (void)setShowBottomLine:(BOOL)showBottomLine
{
    _showBottomLine = showBottomLine;
    self.bottomLineView.hidden = !_showBottomLine;
}

- (UIView *)bottomLineView
{
    if (!_bottomLineView) {
        _bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, 0.5f)];
        [self addSubview:_bottomLineView];
        _bottomLineView.bottom = self.height;
    }
    return _bottomLineView;
}

- (void)setBottomLineColor:(UIColor *)bottomLineColor
{
    _bottomLineColor = bottomLineColor;
    self.bottomLineView.backgroundColor = bottomLineColor;
}

- (CGFloat)itemSpace
{
    if (_itemSpace < 0) {
        _itemSpace = DEFAULT_ITEM_SPACE;
    }
    return _itemSpace;
}


#pragma - mark Private

- (void)initScrollView {
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.alwaysBounceHorizontal = YES;
    [self addSubview:self.scrollView];
}

- (void)initSliderView {
    self.sliderView = [[UIView alloc] init];
    self.sliderColor = DEFAULT_SLIDER_COLOR;
    self.sliderView.backgroundColor = self.sliderColor;
    [self.scrollView addSubview:self.sliderView];
}

- (void)setupItems {
    CGFloat itemX = self.leftRightSpace;
    for (NSInteger index = 0; index < self.itemsTitle.count; index++) {
        NSString *title = self.itemsTitle[index];
        GUSlideBarItem *item = [[GUSlideBarItem alloc] init];
        item.delegate = self;
        
        // Init the current item's frame
        CGFloat itemW = [item widthForTitle:title];
        // this app custom:first item before has no item space
        item.frame = CGRectMake(itemX, 0, itemW, CGRectGetHeight(_scrollView.frame));
        itemX += itemW;
        if (index < self.itemsTitle.count - 1) {
            itemX += self.itemSpace; // size.width = ceil(size.width) + 10; in baritem
        }
        [item setItemTitle:title];
        [_items addObject:item];
        
        [_scrollView addSubview:item];
    }
    itemX += self.leftRightSpace;
    
    // Cculate the scrollView 's contentSize by all the items
    _scrollView.contentSize = CGSizeMake(itemX, CGRectGetHeight(_scrollView.frame));
    
    // Set the default selected item, the first item
    GUSlideBarItem *firstItem = [self.items firstObject];
    firstItem.selected = YES;
    self.selectedItem = firstItem;
    
    // Set the frame of sliderView by the selected item
    if (!self.fixSliderViewWidth) {
        self.sliderViewWidth = firstItem.width;
    }
    self.sliderView.frame = CGRectMake(0, self.height - SLIDER_VIEW_HEIGHT, self.sliderViewWidth, SLIDER_VIEW_HEIGHT);
    self.sliderView.center = CGPointMake(firstItem.center.x, self.sliderView.center.y);
}

/** 选中的item居中 */
- (void)scrollToVisibleItem:(GUSlideBarItem *)item {
    NSInteger selectedItemIndex = [self.items indexOfObject:self.selectedItem];
    NSInteger visibleItemIndex = [self.items indexOfObject:item];
    
    // If the selected item is same to the item to be visible, nothing to do
    if (selectedItemIndex == visibleItemIndex) {
        return;
    }
    
    CGPoint offset = CGPointZero;
    CGFloat itemCenterX = CGRectGetMidX(item.frame);
    if (itemCenterX < self.width / 2.0f) {
        offset.x = 0;
    } else if (itemCenterX > self.scrollView.contentSize.width - self.width / 2.0f)  {
        offset.x = self.scrollView.contentSize.width - self.width;
    } else {
        offset.x = itemCenterX - self.width / 2.0f;
    }
    [self.scrollView setContentOffset:offset animated:YES];
}

- (void)addAnimationWithSelectedItem:(GUSlideBarItem *)item {
    
    // Caculate the distance of translation
    CGFloat dx = CGRectGetMidX(item.frame) - CGRectGetMidX(self.selectedItem.frame);
    
    // Add the animation about translation
    CABasicAnimation *positionAnimation = [CABasicAnimation animation];
    positionAnimation.keyPath = @"position.x";
    positionAnimation.fromValue = @(self.sliderView.layer.position.x);
    positionAnimation.toValue = @(self.sliderView.layer.position.x + dx);
    
    // Combine all the animations to a group
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.animations = @[positionAnimation/*, boundsAnimation*/];
    animationGroup.duration = 0.2;
    [self.sliderView.layer addAnimation:animationGroup forKey:@"basic"];
    
    if (!self.fixSliderViewWidth) {
        self.sliderViewWidth = item.width;
        self.sliderView.frame = CGRectMake(0, self.height - SLIDER_VIEW_HEIGHT, self.sliderViewWidth, SLIDER_VIEW_HEIGHT);
        self.sliderView.center = CGPointMake(self.selectedItem.center.x, self.sliderView.center.y);
    }
    self.sliderView.layer.position = CGPointMake(self.sliderView.layer.position.x + dx, self.sliderView.layer.position.y);
}

#pragma mark - Public
- (void)slideBarItemSelectedCallback:(GUSlideBarItemSelectedCallback)callback {
    _callback = callback;
}

- (void)changeSliderViewWhenScrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat contentOffsetX = scrollView.contentOffset.x;
    if (contentOffsetX < 0 || contentOffsetX > (scrollView.contentSize.width - scrollView.frame.size.width)) {
        return;
    }
    if (scrollView.frame.size.width <= 0) {
        return;
    }
    
    NSInteger viewIndex = contentOffsetX / scrollView.width;
    CGFloat offsetWidth = contentOffsetX - viewIndex * scrollView.width;
    NSInteger viewIndexOffset = contentOffsetX / scrollView.width + 0.5f;
    NSInteger curIndex = [self.items indexOfObject:self.selectedItem];
    BOOL shouldScroll = labs(curIndex - viewIndexOffset) > 1;
    if (fabs(offsetWidth) < 10e-6 || shouldScroll) {
        if (viewIndex <= self.items.count - 1) {
            GUSlideBarItem *barItem = self.items[viewIndex];
            if (!self.fixSliderViewWidth) {
                self.sliderViewWidth = barItem.width;
            }
            self.sliderView.width = self.sliderViewWidth;
            self.sliderView.center = CGPointMake(barItem.center.x, self.sliderView.center.y);
            barItem.selected = YES;
            [self scrollToVisibleItem:barItem];
            self.selectedItem = barItem;
        }
        return;
    }
    
    
    if (viewIndex + 1 > self.items.count - 1) {
        return;
    }
    
    GUSlideBarItem *curItem = self.items[viewIndex];
    GUSlideBarItem *nextItem = self.items[viewIndex + 1];
    
    // change sliderView width
    CGFloat distanceBetweenItems = nextItem.center.x - curItem.center.x;
    if (distanceBetweenItems <= 0) {
        return;
    }
    CGFloat curWidthTargetOffset = viewIndex * scrollView.width + scrollView.width * (1.0f / 2);    // 当前滑动时sliderView长度最大的位置
    CGFloat widthOffsetPercent = (scrollView.width * (1.0f / 2) - fabs(curWidthTargetOffset - contentOffsetX)) / (scrollView.width * (1.0f / 2));
    if (self.fixSliderViewWidth) {
        CGFloat movedWidth = (distanceBetweenItems - self.sliderViewWidth) * widthOffsetPercent;
        self.sliderView.width = self.sliderViewWidth + movedWidth;
    } else {
        CGFloat nextOffsetPercent = offsetWidth / scrollView.width;
        CGFloat curSliderViewWidth = (1 - nextOffsetPercent) * curItem.width + nextOffsetPercent * nextItem.width;
        CGFloat movedWidth = (distanceBetweenItems - curSliderViewWidth) * widthOffsetPercent;
        self.sliderView.width = curSliderViewWidth + movedWidth;
    }
    
    // change sliderView center
    CGFloat centerOffsetPercent = (contentOffsetX - viewIndex * scrollView.width) / (scrollView.width * 1.0f);
    CGPoint curCenter = CGPointMake(curItem.center.x + distanceBetweenItems * centerOffsetPercent, self.sliderView.center.y);
    self.sliderView.center = curCenter;
}

#pragma mark - FDSlideBarItemDelegate
- (void)slideBarItemSelected:(GUSlideBarItem *)item {
    if (item == self.selectedItem) {
        return;
    }
    
    [self scrollToVisibleItem:item];
    [self addAnimationWithSelectedItem:item];
    self.selectedItem = item;
    if (self.callback) {
        self.callback([self.items indexOfObject:item]);
    }
}

@end

