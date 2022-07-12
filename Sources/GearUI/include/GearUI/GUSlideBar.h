//
//  GUSlideBar.h
//  GearUI
//
//  Created by harmanhuang on 2017/10/23.
//  Copyright © 2017年 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^GUSlideBarItemSelectedCallback)(NSUInteger idx);

/** 改自第三方库FDSlideBar */
@interface GUSlideBar : UIView

// All the titles of FDSilderBar
@property (copy, nonatomic) NSArray *itemsTitle;

// All the item's text color of the normal state
@property (strong, nonatomic) UIColor *itemColor;

// The selected item's text color
@property (strong, nonatomic) UIColor *itemSelectedColor;

@property (assign, nonatomic) CGFloat titleFontSize;

// The slider color
@property (strong, nonatomic) UIColor *sliderColor;

// space between button
@property (assign, nonatomic) CGFloat itemSpace;

// first item to left or last item to right space
@property (assign, nonatomic) CGFloat leftRightSpace;

// if NO, then ingore sliderViewWidth, and user item width
@property (assign, nonatomic) BOOL fixSliderViewWidth;
@property (assign, nonatomic) CGFloat sliderViewWidth;

@property (strong, nonatomic) UIColor *bottomLineColor;
@property (assign, nonatomic) BOOL showBottomLine;

// Add the callback deal when a slide bar item be selected
- (void)slideBarItemSelectedCallback:(GUSlideBarItemSelectedCallback)callback;

//// Set the slide bar item at index to be selected
//- (void)selectSlideBarItemAtIndex:(NSUInteger)index;

// change slider view width when scroll view did scroll
- (void)changeSliderViewWhenScrollViewDidScroll:(UIScrollView *)scrollView;

@end

