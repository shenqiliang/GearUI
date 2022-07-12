//
//  GUTableViewSection.m
//  GearUI
//
//  Created by 谌启亮 on 09/03/2018.
//  Copyright © 2018 谌启亮. All rights reserved.
//

#import "GUTableViewSection.h"
#import "GUNode.h"
#import "GUTableViewCell.h"
#import "GUTableView.h"
#import "GUViewController.h"

@interface UIView (ParentGUViewController)
- (GUViewController *)guViewController;
@end

@implementation UIView (ParentGUViewController)
- (GUViewController *)guViewController {
    UIResponder *responder = self;
    while (responder != nil && ![responder isKindOfClass:[GUViewController class]])
        responder = [responder nextResponder];
    return (GUViewController *)responder;
}
@end

@interface GUViewController()
- (void)showDebugErrorMessage:(NSString *)message;
@end


@interface GUTableViewSection ()

@property (nonatomic, strong) NSArray<GUNode *> *cellNodes;
@property (nonatomic, strong) NSArray<GUNode *> *viewNodes;
@property (nonatomic, strong) NSMutableArray<GUTableViewCell *> *staticCells;
@property (nonatomic, strong) UIView<GUNodeViewProtocol> *staticHeaderView;
@property (nonatomic, strong) UIView<GUNodeViewProtocol> *staticFooterView;
@property (nonatomic, weak) GUTableView *tableView;

- (UIView<GUNodeViewProtocol> *)viewWithNodeId:(NSString *)nodeId;
- (void)gu_genStaticCellsIfNeeds;
- (UIView<GUNodeViewProtocol> *)generateViewWithNodeId:(NSString *)nodeId;

@end


@implementation GUTableViewSection

- (NSArray<GUNode *> *)updateSubnodes:(NSArray<GUNode *> *)subnodes {
    _cellNodes = [subnodes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", @"TableViewCell"]];
    _viewNodes = [subnodes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name != %@", @"TableViewCell"]];
    [_staticCells removeAllObjects];
    return [NSArray array];
}

- (void)setDisableLayout:(BOOL)disableLayout{
    if (_disableLayout != disableLayout) {
        _disableLayout = disableLayout;
        [self.tableView reloadData];
    }
}

- (void)updateChildren:(NSArray *)children {
    NSMutableArray *array = [NSMutableArray array];
    for (GUTableViewCell *cell in children) {
        if ([cell isKindOfClass:[GUTableViewCell class]]) {
            [array addObject:cell];
        }
    }
    _staticCells = [array mutableCopy];
}

- (void)gu_genStaticCellsIfNeeds {
    if ([_staticCells count] != [_cellNodes count]) {
        NSMutableArray *array = [NSMutableArray array];
        for (GUNode *subNode in _cellNodes) {
            @try {
                id<GUNodeProtocol> childNode = [subNode generateObject];
                if (childNode != nil) {
                    [array addObject:childNode];
                }
            } @catch (NSException *exception) {
                [[self.tableView guViewController] showDebugErrorMessage:exception.reason];
            } @finally {
                
            }
        }
        [self updateChildren:array];
    }
    if (self.staticHeaderView == nil || ![self.staticHeaderView.nodeId isEqualToString:self.headerViewNodeId]) {
        self.staticHeaderView = [self generateViewWithNodeId:self.headerViewNodeId];
    }
    if (self.staticFooterView == nil || ![self.staticFooterView.nodeId isEqualToString:self.footerViewNodeId]) {
        self.staticFooterView = [self generateViewWithNodeId:self.footerViewNodeId];
    }
}

- (UIView<GUNodeViewProtocol> *)viewWithNodeId:(NSString *)nodeId {
    if ([nodeId length] == 0) {
        return nil;
    }
    UIView<GUNodeViewProtocol> *v = [self.staticHeaderView viewWithNodeId:nodeId];
    if (v != nil) {
        return v;
    }
    v = [self.staticFooterView viewWithNodeId:nodeId];
    if (v != nil) {
        return v;
    }
    for (GUTableViewCell *cell in _staticCells) {
        if ([cell.nodeId isEqualToString:nodeId]) {
            return cell;
        }
    }
    for (GUTableViewCell *cell in _staticCells) {
        UIView<GUNodeViewProtocol> *view = [cell viewWithNodeId:nodeId];
        if (view != nil) {
            return view;
        }
    }
    return nil;
}

- (UIView<GUNodeViewProtocol> *)generateViewWithNodeId:(NSString *)nodeId {
    if ([nodeId length] == 0) {
        return nil;
    }
    for (GUNode *node in _viewNodes) {
        if ([node.nodeId isEqualToString:nodeId]) {
            UIView<GUNodeViewProtocol> *view = [node generateObject];
            if ([view isKindOfClass:[UIView class]]) {
                return view;
            }
        }
    }
    return nil;
}


@end
