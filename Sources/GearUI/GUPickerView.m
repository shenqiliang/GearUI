//
//  GUPickerView.m
//  GearUI
//
//  Created by 谌启亮 on 09/03/2018.
//  Copyright © 2018 谌启亮. All rights reserved.
//

#import "GUPickerView.h"
#import "GUNode.h"

@interface GUPickerView() <UIPickerViewDelegate, UIPickerViewDataSource>

@end

@implementation GUPickerView {
    NSArray<GUNode *> *_subnodes;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
    }
    return self;
}

- (NSArray<GUNode *> *)updateSubnodes:(NSArray<GUNode *> *)subnodes {
    _subnodes = subnodes;
    return [NSArray new];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return [_subnodes count];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [_subnodes[component].subNodes count];
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    UIColor *textColor = _textColor;
    if (textColor == nil) {
        textColor = [UIColor blackColor];
    }
    NSString *title = _subnodes[component].subNodes[row].text;
    NSAttributedString *attString =
    [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:textColor}];
    
    return attString;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return _rowHeight > __FLT_EPSILON__ ? _rowHeight : 30;
}

- (void)layoutSubviews {
    [super layoutSubviews];
//    for (UIView *view in self.subviews) {
//        view.hidden = view.bounds.size.height < 1;
//    }
}

- (NSString *)selectedValueInComponent:(NSInteger)component {
    return _subnodes[component].subNodes[[self selectedRowInComponent:component]].text;
}

- (void)selectValue:(NSString *)value inComponent:(NSInteger)component animated:(BOOL)animated {
    GUNode *curNode = _subnodes[component];
    NSInteger row = 0;
    for (NSInteger i = 0; i < curNode.subNodes.count; i++) {
        if ([curNode.subNodes[i].text isEqualToString:value]) {
            row = i;
            break;
        }
    }
    [self selectRow:row inComponent:component animated:animated];
}

@end
