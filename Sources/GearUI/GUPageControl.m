//
//  GUPageControl.m
//  GearUI
//
//  Created by 谌启亮 on 13/09/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUPageControl.h"

@implementation GUPageControl

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _currentDotColor = [UIColor whiteColor];
        _dotColor = [UIColor colorWithWhite:1 alpha:0.2];
        _dotSpacing = 12;
        _dotSize = 4;
    }
    return self;
}

- (void)setCurrentPage:(NSInteger)currentPage {
    _currentPage = currentPage;
    [self setNeedsDisplay];
}

- (void)setNumberOfPages:(NSUInteger)numberOfPages {
    _numberOfPages = numberOfPages;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (_numberOfPages > 1) {
        CGFloat offsetXBegin = (self.bounds.size.width-(_numberOfPages-1)*_dotSpacing - _dotSize*_numberOfPages)/2;
        for (int i = 0; i < _numberOfPages; i++) {
            UIBezierPath *dot = [UIBezierPath bezierPathWithArcCenter:CGPointMake(offsetXBegin+i*(_dotSpacing+_dotSize), self.bounds.size.height/2) radius:_dotSize/2 startAngle:-M_PI endAngle:M_PI clockwise:YES];
            if (i == _currentPage) {
                [_currentDotColor set];
            }
            else {
                [_dotColor set];
            }
            [dot fill];
        }
    }
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (_numberOfPages > 1) {
        CGPoint location = [touch locationInView:self];
        CGFloat offsetXBegin = (self.bounds.size.width-(_numberOfPages-1)*(_dotSpacing+_dotSize))/2;
        CGFloat currentOffset = offsetXBegin + _currentPage * (_dotSpacing+_dotSize);
        if (location.x < currentOffset - (_dotSpacing+_dotSize)/2 && _currentPage > 0) {
            [self setCurrentPage:_currentPage - 1];
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
        else if (location.x > currentOffset + (_dotSpacing+_dotSize)/2 && _currentPage < _numberOfPages - 1) {
            [self setCurrentPage:_currentPage + 1];
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }
    
}


@end
