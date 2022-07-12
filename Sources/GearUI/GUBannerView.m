//
//  GUBannerView.m
//  GearUI
//
//  Created by 谌启亮 on 13/09/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUBannerView.h"
#import "GUImageView.h"
#import "GULayoutView.h"
#import "GUPageControl.h"

@interface GUBannerView () <UIScrollViewDelegate>

@property (nonatomic, strong) NSTimer *timer;

@end


@implementation GUBannerView
{
    UIScrollView *_scrollView;
    NSMutableDictionary *_loadedContentsViews;
}

- (void)dealloc
{
    [self invalidateTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _loadedContentsViews = [NSMutableDictionary dictionary];
        
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.delegate = self;
        _scrollView.pagingEnabled = YES;
        [self addSubview:_scrollView];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (GUPageControl *)supportedPageControl {
    GULayoutView *layoutView = (GULayoutView *)self.superview;
    if ([layoutView isKindOfClass:[GULayoutView class]]) {
        GUPageControl *pageControl = (GUPageControl *)[layoutView viewWithNodeId:self.pageControlId];
        if ([pageControl isKindOfClass:[GUPageControl class]]) {
            return pageControl;
        }
    }
    return nil;
}

- (void)layoutSubviews {
    _scrollView.frame = self.bounds;
    _scrollView.contentSize = CGSizeMake(_imagePaths.count*self.bounds.size.width*3, self.bounds.size.height);
    _scrollView.contentOffset = CGPointMake(_imagePaths.count*self.bounds.size.width, 0);
    [self loadVisiableItems];
}


- (void)didUpdateAttributes {
    [self supportedPageControl].numberOfPages = _imagePaths.count;
    [self supportedPageControl].currentPage = _currentPage;
    [[self supportedPageControl] addTarget:self action:@selector(gu_pageControlChanged:) forControlEvents:UIControlEventValueChanged];
    _scrollView.contentOffset = CGPointMake(_imagePaths.count*self.bounds.size.width, 0);
}

- (void)gu_pageControlChanged:(GUPageControl *)control {
    [self setCurrentPage:control.currentPage animated:YES];
}

- (void)setImagePaths:(NSArray<NSString *> *)imagePaths {
    if ([imagePaths isKindOfClass:[NSString class]]) {
        imagePaths = [(NSString *)imagePaths componentsSeparatedByString:@";"];
    }
    if (![_imagePaths isEqualToArray:imagePaths]) {
        [_loadedContentsViews enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
        [_loadedContentsViews removeAllObjects];
        _imagePaths = imagePaths;
        _scrollView.contentSize = CGSizeMake(_imagePaths.count*self.bounds.size.width*3, self.bounds.size.height);
        _scrollView.contentOffset = CGPointMake(_imagePaths.count*self.bounds.size.width, 0);
        [self supportedPageControl].numberOfPages = _imagePaths.count;
        [self supportedPageControl].currentPage = _currentPage;
        [self loadVisiableItems];
        
    }
    _scrollView.scrollEnabled = [_imagePaths count] > 1;
}

- (void)adjustContentOffsetAfterAnimation {
    CGFloat totalWidth = _imagePaths.count*_scrollView.bounds.size.width;
    if (_scrollView.contentOffset.x < totalWidth || _scrollView.contentOffset.x > totalWidth*2) {
        _scrollView.contentOffset = CGPointMake(fmod(_scrollView.contentOffset.x, totalWidth*2)+totalWidth, 0);
    }
}

- (void)loadVisiableItems {
    if (_imagePaths.count == 0) {
        return;
    }
    if (_scrollView.bounds.size.width <= __FLT_EPSILON__ || _scrollView.bounds.size.height <= __FLT_EPSILON__) {
        return;
    }
    CGFloat totalWidth = _imagePaths.count*_scrollView.bounds.size.width;
    CGFloat offsetX = _scrollView.contentOffset.x;
    NSInteger page = (offsetX - totalWidth + _scrollView.bounds.size.width/2)/_scrollView.bounds.size.width;
    for (NSInteger p = page-1; p <= page+1; p++) {
        CGRect frame = CGRectMake(totalWidth+p*_scrollView.bounds.size.width, 0, _scrollView.bounds.size.width, _scrollView.bounds.size.height);
        GUImageView *loadedView = _loadedContentsViews[@(p)];
        if (loadedView == nil) {
            loadedView = [self dequeueContentView];
            loadedView.content = _imagePaths[(p+_imagePaths.count)%_imagePaths.count];
            loadedView.frame = frame;
            [_scrollView addSubview:loadedView];
            _loadedContentsViews[@(p)] = loadedView;
        }
        else {
            loadedView.frame = frame;
        }
    }
}

- (GUImageView *)dequeueContentView {
    __block id foundKey = nil;
    CGRect checkRect = CGRectMake(_scrollView.contentOffset.x-_scrollView.bounds.size.width/2, 0, _scrollView.bounds.size.width*2, _scrollView.bounds.size.height);
    [_loadedContentsViews enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, GUImageView * _Nonnull obj, BOOL * _Nonnull stop) {
        if (!CGRectIntersectsRect(checkRect, obj.frame)) {
            foundKey = key;
            *stop = YES;
        }
    }];
    GUImageView *imageView = nil;
    if (foundKey) {
        imageView = _loadedContentsViews[foundKey];
        [imageView removeFromSuperview];
        [_loadedContentsViews removeObjectForKey:foundKey];
    }
    if (imageView == nil) {
        imageView = [GUImageView new];
    }
    return imageView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self adjustContentOffsetAfterAnimation];
    [self loadVisiableItems];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (_imagePaths.count == 0) {
        return;
    }
    [self updateValueWithOffsetX:(*targetContentOffset).x];
}

- (void)updateValueWithOffsetX:(CGFloat)offsetX {
    NSInteger page = offsetX/_scrollView.bounds.size.width;
    page = page%_imagePaths.count;
    if (page != _currentPage) {
        _currentPage = page;
        [self supportedPageControl].currentPage = _currentPage;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)setCurrentPage:(NSInteger)currentPage {
    [self setCurrentPage:currentPage animated:NO];
}

- (void)setCurrentPage:(NSInteger)currentPage animated:(BOOL)animated {
    if (_currentPage != currentPage) {
        _currentPage = currentPage;
        CGFloat targetX = _scrollView.bounds.size.width * _currentPage;
        CGFloat currentX = _scrollView.contentOffset.x;
        CGFloat contentWidth = [_imagePaths count] * _scrollView.bounds.size.width;
        if (ABS(targetX - currentX) < ABS(targetX + contentWidth - currentX) && ABS(targetX - currentX) < ABS(targetX + 2 * contentWidth - currentX)) {
            [_scrollView setContentOffset:CGPointMake(targetX, 0) animated:animated];
        }
        else if (ABS(targetX + contentWidth - currentX) < ABS(targetX - currentX) && ABS(targetX + contentWidth - currentX) < ABS(targetX + 2 * contentWidth - currentX)) {
            [_scrollView setContentOffset:CGPointMake(targetX + contentWidth, 0) animated:animated];
        }
        else {
            [_scrollView setContentOffset:CGPointMake(targetX + 2 * contentWidth, 0) animated:animated];
        }
    }
}

- (void)setAutoScroll:(BOOL)autoScroll {
    _autoScroll = autoScroll;
    [self try2StartAutoScroll];
}

- (void)try2StartAutoScroll
{
    [self invalidateTimer];
    
    if (self.autoScroll) {
        if (self.scrollTimeInterval <= 0) {
            self.scrollTimeInterval = 5;
        }
        self.timer = [NSTimer scheduledTimerWithTimeInterval:self.scrollTimeInterval target:self selector:@selector(auto2Next:) userInfo:nil repeats:YES];
    }
}

- (void)invalidateTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)auto2Next:(NSTimer *)timer
{
    if (_imagePaths.count == 0 || _imagePaths.count == 1) {
        return;
    }
    if (_scrollView.tracking || _scrollView.decelerating) {
        return;
    }
    
    CGFloat scrollViewWidth = _scrollView.bounds.size.width;
    CGPoint offset = CGPointMake(_scrollView.contentOffset.x + scrollViewWidth, 0);
    if (scrollViewWidth > 0) {
        NSInteger count = offset.x / scrollViewWidth;
        if (offset.x - count * scrollViewWidth > 1) {
            offset.x = (count + 1) * scrollViewWidth;
        }
    }
    [self updateValueWithOffsetX:offset.x];
    [_scrollView setContentOffset:offset animated:YES];
}

#pragma mark - notification
- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self invalidateTimer];
}

- (void)applicationWillEnterForeground:(NSNotification *)notificaiton
{
    [self try2StartAutoScroll];
}

- (void)didMoveToWindow {
    if (self.window == nil) {
        [self invalidateTimer];
    }
    else {
        [self try2StartAutoScroll];
    }
}

@end

