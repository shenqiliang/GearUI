//
//  GUCollectionViewCell.m
//  GearUI
//
//  Created by 谌启亮 on 05/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUCollectionViewCell.h"
#import "GULayoutView.h"
#import "GULog.h"


@implementation GUCollectionViewCell
{
    GULayoutView *_layoutView;
    GUNode *_cellNode;
    NSLayoutConstraint *_heightConstraint;
    NSLayoutConstraint *_widthConstraint;
    BOOL _isHeightCalculated;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _layoutView = [[GULayoutView alloc] initWithFrame:self.contentView.bounds];
        _layoutView.backgroundColor = [UIColor clearColor];
        _layoutView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_layoutView];
        [_layoutView setAttribute:@"0" forKeyPath:@"top"];
        [_layoutView setAttribute:@"0" forKeyPath:@"left"];
        [_layoutView setAttribute:@"0" forKeyPath:@"right"];
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:_layoutView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        bottomConstraint.priority = UILayoutPriorityDefaultLow;
        [self.contentView addConstraint:bottomConstraint];
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

- (GULayoutView *)layoutView {
    return _layoutView;
}

- (void)updateChildren:(NSArray *)children {
    [_layoutView updateChildren:children];
}

- (void)gu_updateLayoutWithAttribute:(NSLayoutAttribute)layoutAttribute value:(NSString *)value{
    if (layoutAttribute == NSLayoutAttributeHeight) {
        if (_heightConstraint == nil) {
            _heightConstraint = [NSLayoutConstraint constraintWithItem:_layoutView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:[value floatValue]];
            [_layoutView addConstraint:_heightConstraint];
        }
        else {
            _heightConstraint.constant = [value floatValue];
        }
    }
    else if (layoutAttribute == NSLayoutAttributeWidth) {
        if (_widthConstraint == nil) {
            _widthConstraint = [NSLayoutConstraint constraintWithItem:_layoutView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:[value floatValue]];
            [_layoutView addConstraint:_widthConstraint];
        }
        else {
            _widthConstraint.constant = [value floatValue];
        }
    }
    else{
        GUWarn(@"CollectionViewCell only support height & width layout attribute. others will be ignored.");
    }
}

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    if ([[UIDevice currentDevice].systemVersion floatValue] <= 9.2) {
        if (!_isHeightCalculated) {
            [self setNeedsLayout];
            [self layoutIfNeeded];
            CGSize size = [_layoutView systemLayoutSizeFittingSize:layoutAttributes.size];
            CGRect frame = layoutAttributes.frame;
            frame.size = size;
            layoutAttributes.frame = frame;
            _isHeightCalculated = true;
        }
        return layoutAttributes;
    }
    else {
        return [super preferredLayoutAttributesFittingAttributes:layoutAttributes];
    }
}

- (NSString *)reuseIdentifier{
    return self.nodeId;
}

- (UIView<GUNodeViewProtocol> *)viewWithNodeId:(NSString *)nodeId {
    return [_layoutView viewWithNodeId:nodeId];
}

@end
