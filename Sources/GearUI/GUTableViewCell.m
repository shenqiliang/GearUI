//
//  GUTableViewCell.m
//  GearUI
//
//  Created by 谌启亮 on 30/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUTableViewCell.h"
#import "GULayoutView.h"
#import "GUNode.h"
#import "NSObject+GUPrivate.h"
#import "GULog.h"

@interface GUTableViewCell()
{
    GUNode *_cellNode;
    NSLayoutConstraint *_heightConstraint;
}

@property (nonatomic, strong) GULayoutView *layoutView;
@property (nonatomic, strong) NSString *action;

@end

@implementation GUTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
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
    }
    return self;
}

- (void)didLoadFromNode:(GUNode *)node{
    _cellNode = node;
}

- (void)updateChildren:(NSArray *)children {
    [_layoutView updateChildren:children];
    [self gu_bindPropertyForSubClassOf:[GUTableViewCell class]];
}

- (GUTableViewCell *)reuseCellWithIdentifier:(NSString *)reuseIdentifier {
    GUTableViewCell *cell = [[self.class alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    [[_cellNode copy] updateObject:cell];
    return cell;
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
    else{
        GUWarn(@"TableViewCell only support height layout attribute. others will be ignored.");
    }
}

- (UIView<GUNodeViewProtocol> *)viewWithNodeId:(NSString *)nodeId {
    return [_layoutView viewWithNodeId:nodeId];
}

- (void)setSelectedBackgroundColor:(UIColor *)selectedBackgroundColor {
    if (_selectedBackgroundColor != selectedBackgroundColor) {
        _selectedBackgroundColor = selectedBackgroundColor;
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        self.selectedBackgroundView.backgroundColor = _selectedBackgroundColor;
    }
}

@end
