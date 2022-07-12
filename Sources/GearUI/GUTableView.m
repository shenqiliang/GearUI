//
//  GUTableView.m
//  GearUI
//
//  Created by 谌启亮 on 30/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUTableView.h"
#import "GUTableViewCell.h"
#import "GULayoutView.h"
#import "GUTableViewSection.h"
#import "UIView+GUPrivate.h"
#import <objc/runtime.h>
#import "GUWeakProxy.h"
#import "GULog.h"

@interface GUTableViewDelegateProxy : NSProxy

- (instancetype)initWithTableView:(GUTableView *)tableView;

@property (nonatomic, weak) id<UITableViewDelegate> delegate;

@end

@implementation GUTableViewDelegateProxy {
    __weak GUTableView *_tableView;
}

- (instancetype)initWithTableView:(GUTableView *)tableView {
    _tableView = tableView;
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([_tableView respondsToSelector:aSelector]){
        return YES;
    }
    return [(id)_delegate respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature* signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        signature = [(id)_delegate methodSignatureForSelector:aSelector];
    }
    return signature;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([_tableView respondsToSelector:aSelector]){
        return _tableView;
    }
    if ([_delegate respondsToSelector:aSelector]){
        return _delegate;
    }
    return nil;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([_tableView respondsToSelector:[anInvocation selector]]){
        [anInvocation invokeWithTarget:(id)_tableView];
    }
    else if ([_delegate respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:(id)_delegate];
    }
    else {
        [super forwardInvocation:anInvocation];
    }
}

- (BOOL)isProxy {
    return YES;
}


@end

@interface GUPhysicAnimator : NSObject {
    CADisplayLink *_displayLink;
    CFTimeInterval _startTime;
    CGFloat _acc;
}

- (instancetype)initWithStartValue:(CGFloat)startValue endValue:(CGFloat)endValue velocity:(CGFloat)velocity;
- (void)start;
- (void)stop;

@property (nonatomic) void(^updator)(CGFloat);

@property (nonatomic) CGFloat startValue;
@property (nonatomic) CGFloat endValue;
@property (nonatomic) CGFloat velocity;

@end

@implementation GUPhysicAnimator

- (instancetype)initWithStartValue:(CGFloat)startValue endValue:(CGFloat)endValue velocity:(CGFloat)velocity
{
    self = [super init];
    if (self) {
        if ((endValue-startValue)*velocity < 0) {
            GUError(@"can not reach endValue with the velocity %f, try %f", velocity, -velocity);
        }
        _startValue = startValue;
        _endValue = endValue;
        _velocity = velocity;
        _acc = - (_velocity * _velocity) / (2 * (_endValue - _startValue));
    }
    return self;
}

- (void)start {
    _startTime = CACurrentMediaTime();
    _displayLink = [CADisplayLink displayLinkWithTarget:[GUWeakProxy proxyWithObject:self] selector:@selector(update)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stop {
    [_displayLink invalidate];
    _displayLink = nil;
}

- (void)update {
    CFTimeInterval deltTime = 0;
    if (@available(iOS 10.0, *)) {
        deltTime = _displayLink.targetTimestamp - _startTime;
    } else {
        deltTime = CACurrentMediaTime() - _startTime;
    }
    CGFloat vt = _velocity + deltTime * _acc;
    if (_velocity * vt >= 0) {
        CGFloat deltDis = (vt + _velocity) / 2 * deltTime;
        if (_updator != nil) {
            _updator(_startValue + deltDis);
        }
    }
    else {
        if (_updator != nil) {
            _updator(_endValue);
        }
        [self stop];
    }
}

@end

@interface GUTableViewCell()
@property (nonatomic, strong) NSString *action;
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


@interface GUTableView() <UITableViewDataSource, UITableViewDelegate>
{
    NSArray<GUTableViewSection *> *_sections;
    NSCache *_estimatedRowHeightCache;
    NSCache *_estimatedSectionHeaderHeightCache;
    NSCache *_estimatedSectionFooterHeightCache;
    GUTableViewDelegateProxy *_delegateProxy;
    BOOL _respondDidScroll;
    BOOL _deallocing;
    GUPhysicAnimator *_physicAnimator;
}

@end

@implementation GUTableView

+ (NSArray *)initializedAttributeKeys {
    return @[@"style"];
}

+ (id)newObjectWithAttributes:(NSDictionary *)initializedAttributes {
    if ([initializedAttributes[@"style"] isEqualToString:@"grouped"]) {
        return [[self alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    }
    else {
        return [[self alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    }
}


- (NSArray *)delayedUpdateAttributeNames {
    return @[@"headerViewNodeId", @"footerViewNodeId"];
}

+ (NSString *)reuseIdentifierWithCellNodeID:(NSString *)cellNodeId configure:(NSDictionary *)configure{
    NSString *reuseIdentifier = cellNodeId;
    if ([configure count] > 0) {
        NSMutableString *temp = [NSMutableString stringWithCapacity:100];
        for (NSString *key in [[configure allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
            NSString *value = configure[key];
            [temp appendFormat:@",%@:%@", key, value];
        }
        reuseIdentifier = [reuseIdentifier stringByAppendingString:temp];
    }
    return reuseIdentifier;
}

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (self) {
        super.dataSource = self;
        _delegateProxy = [[GUTableViewDelegateProxy alloc] initWithTableView:self];
        super.delegate = (id<UITableViewDelegate>)_delegateProxy;
        #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
        if (@available(iOS 15.0, *)) {
            self.sectionHeaderTopPadding = 0;
        }
        #endif
        self.estimatedRowHeight = 80;
        self.rowHeight = UITableViewAutomaticDimension;
        if (style == UITableViewStyleGrouped) {
            self.estimatedSectionHeaderHeight = 20;
            self.estimatedSectionFooterHeight = 20;
        }
        _estimatedRowHeightCache = [[NSCache alloc] init];
        _estimatedSectionHeaderHeightCache = [[NSCache alloc] init];
        _estimatedSectionFooterHeightCache = [[NSCache alloc] init];
    }
    return self;
}

- (void)phyicalAnimatedScrollToContentOffset:(CGPoint)contentOffset velocity:(CGFloat)velocity {
    _physicAnimator = [[GUPhysicAnimator alloc] initWithStartValue:self.contentOffset.y endValue:contentOffset.y velocity:velocity];
    __weak id weakSelf = self;
    _physicAnimator.updator = ^(CGFloat offset) {
        [weakSelf setContentOffset:CGPointMake(0, offset)];
    };
    [_physicAnimator start];
}

- (NSArray<GUNode *> *)updateSubnodes:(NSArray<GUNode *> *)subnodes {
    
    NSMutableArray<GUNode *> *subSectionNodes = [NSMutableArray array];
    
    NSMutableArray<GUNode *> *sectionChildNodes = nil;

    for (GUNode *node in subnodes) {
        if ([node.name isEqualToString:@"TableViewSection"]) {
            if ([sectionChildNodes count] > 0) {
                GUNode *sectionNode = [GUNode new];
                sectionNode.name = @"TableViewSection";
                sectionNode.subNodes = [sectionChildNodes copy];
                [subSectionNodes addObject:sectionNode];
            }
            [subSectionNodes addObject:node];
            sectionChildNodes = nil;
        }
        else {
            if (sectionChildNodes == nil) {
                sectionChildNodes = [NSMutableArray array];
            }
            [sectionChildNodes addObject:node];
        }
    }
    
    if ([sectionChildNodes count] > 0) {
        GUNode *sectionNode = [GUNode new];
        sectionNode.name = @"TableViewSection";
        sectionNode.subNodes = [sectionChildNodes copy];
        [subSectionNodes addObject:sectionNode];
    }

    return [subSectionNodes copy];
}

- (void)updateChildren:(NSArray *)children {
    NSMutableArray *array = [NSMutableArray array];
    for (GUTableViewSection *cell in children) {
        if ([cell isKindOfClass:[GUTableViewSection class]]) {
            cell.tableView = self;
            [array addObject:cell];
        }
    }
    _sections = [array copy];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [_physicAnimator stop];
    [super touchesBegan:touches withEvent:event];
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    return YES;
}

- (void)setRemoveRedundantSeparator:(BOOL)removeRedundantSeparator {
    if (_removeRedundantSeparator != removeRedundantSeparator) {
        _removeRedundantSeparator = removeRedundantSeparator;
        if (_removeRedundantSeparator) {
            if (self.tableHeaderView == nil) {
                self.tableHeaderView = [UIView new];
            }
            if (self.tableFooterView == nil) {
                self.tableFooterView = [UIView new];
            }
        }
    }
}

- (id<GUNodeProtocol>)subnodeWithId:(NSString *)nodeId {
    if ([nodeId length] == 0) {
        return nil;
    }
    for (GUTableViewSection *section in _sections) {
        if ([section.nodeId isEqualToString:nodeId]) {
            return section;
        }
    }
    if ([self.nodeId isEqualToString:nodeId]) {
        return (UIView<GUNodeViewProtocol> *)self;
    }
    if ([self.tableHeaderView.nodeId isEqualToString:nodeId]) {
        return (UIView<GUNodeViewProtocol> *)self.tableHeaderView;
    }
    if ([self.tableFooterView.nodeId isEqualToString:nodeId]) {
        return (UIView<GUNodeViewProtocol> *)self.tableFooterView;
    }
    if ([self.tableHeaderView isKindOfClass:[GULayoutView class]]) {
        UIView<GUNodeViewProtocol> *view = [(GULayoutView *)self.tableHeaderView viewWithNodeId:nodeId];
        if (view != nil) {
            return view;
        }
    }
    if ([self.tableFooterView isKindOfClass:[GULayoutView class]]) {
        UIView<GUNodeViewProtocol> *view = [(GULayoutView *)self.tableFooterView viewWithNodeId:nodeId];
        if (view != nil) {
            return view;
        }
    }
    if (self.dataSource == self) {
        [self gu_genStaticCellsIfNeeds];
    }
    for (GUTableViewSection *section in _sections) {
        UIView<GUNodeViewProtocol> *view = [section viewWithNodeId:nodeId];
        if (view) {
            return view;
        }
    }
    return [super subnodeWithId:nodeId];
}

- (void)gu_genStaticCellsIfNeeds {
    for (GUTableViewSection *section in _sections) {
        [section gu_genStaticCellsIfNeeds];
    }
}

- (NSArray<GUTableViewSection *> *)displayedSections {
    return [_sections filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"disableLayout != YES"]];
}

- (NSArray<GUTableViewCell *> *)displayedCellInSection:(NSInteger)section {
    NSArray<GUTableViewCell *> *cells = [self displayedSections][section].staticCells;
    return [cells filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"disableLayout != YES"]];
}

- (UIView<GUNodeViewProtocol> *)generateViewWithNodeId:(NSString *)nodeId {
    for (GUTableViewSection *section in _sections) {
        UIView<GUNodeViewProtocol> *view = [section generateViewWithNodeId:nodeId];
        if (view) {
            return view;
        }
    }
    return nil;
}

- (void)setDelegate:(id<UITableViewDelegate>)delegate {
    if (!_deallocing) {
        _delegateProxy = [[GUTableViewDelegateProxy alloc] initWithTableView:self];
        _delegateProxy.delegate = delegate;
        _respondDidScroll = [delegate respondsToSelector:@selector(scrollViewDidScroll:)];
        [super setDelegate:(id<UITableViewDelegate>)_delegateProxy];
    }
    else {
        [super setDelegate:delegate];
    }
}

- (void)setHeaderViewNodeId:(NSString *)headerViewNodeId {
    if (![_headerViewNodeId isEqualToString:headerViewNodeId]) {
        _headerViewNodeId = headerViewNodeId;
        UIView *tableHeaderView = [self generateViewWithNodeId:headerViewNodeId];
        self.tableHeaderView = tableHeaderView;
        [tableHeaderView setNeedsLayout];
        [tableHeaderView layoutIfNeeded];
        CGRect frame = tableHeaderView.frame;
        frame.size = [tableHeaderView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        tableHeaderView.frame = frame;
        self.tableHeaderView = tableHeaderView;
    }
}

- (void)layoutSubviews {
    UIView *tableHeaderView = [self tableHeaderView];
    if (tableHeaderView != nil) {
        CGRect frame = tableHeaderView.frame;
        frame.size = [tableHeaderView systemLayoutSizeFittingSize:self.bounds.size withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
        tableHeaderView.frame = frame;
    }
    UIView *tableFooterView = [self tableFooterView];
    if (tableFooterView != nil) {
        CGRect frame = tableFooterView.frame;
        frame.size = [tableFooterView systemLayoutSizeFittingSize:self.bounds.size withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
        tableFooterView.frame = frame;
    }
    [super layoutSubviews];
}

- (void)setFooterViewNodeId:(NSString *)footerViewNodeId {
    if (![_footerViewNodeId isEqualToString:footerViewNodeId]) {
        _footerViewNodeId = footerViewNodeId;
        UIView *tableFooterView = [self generateViewWithNodeId:footerViewNodeId];
        self.tableFooterView = tableFooterView;
        [tableFooterView setNeedsLayout];
        [tableFooterView layoutIfNeeded];
        CGRect frame = tableFooterView.frame;
        frame.size = [tableFooterView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        tableFooterView.frame = frame;
        self.tableFooterView = tableFooterView;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    if (_delegateProxy.delegate == nil && tableView.dataSource == self) {
        GUTableViewSection *tableSection = [self displayedSections][section];
        if (tableView.dataSource == self && tableSection.headerViewNodeId) {
            return 20;
        }
        else {
            return self.estimatedSectionHeaderHeight;
        }
    }
    if ([_delegateProxy.delegate respondsToSelector:@selector(tableView:estimatedHeightForHeaderInSection:)]) {
        return [_delegateProxy.delegate tableView:tableView estimatedHeightForHeaderInSection:section];
    }
    CGFloat estimatedHeight = [[_estimatedSectionHeaderHeightCache objectForKey:@(section)] floatValue];
    if (estimatedHeight >= 1) {
        return estimatedHeight;
    }
    else {
        if ([_delegateProxy.delegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
            return 20;
        }
        else {
            return self.estimatedSectionHeaderHeight;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([_delegateProxy.delegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
        return [_delegateProxy.delegate tableView:tableView heightForHeaderInSection:section];
    }
    if (tableView.dataSource == self) {
        GUTableViewSection *tableSection = [self displayedSections][section];
        if ([tableSection.headerViewNodeId length] == 0 && self.style == UITableViewStylePlain) {
            return 0;
        }
        else {
            return UITableViewAutomaticDimension;
        }
    }
    else {
        return UITableViewAutomaticDimension;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section {
    if (_delegateProxy.delegate == nil && tableView.dataSource == self) {
        GUTableViewSection *tableSection = [self displayedSections][section];
        if (tableView.dataSource == self && tableSection.footerViewNodeId) {
            return 20;
        }
        else {
            return self.estimatedSectionHeaderHeight;
        }
    }
    if ([_delegateProxy.delegate respondsToSelector:@selector(tableView:estimatedHeightForFooterInSection:)]) {
        return [_delegateProxy.delegate tableView:tableView estimatedHeightForFooterInSection:section];
    }
    CGFloat estimatedHeight = [[_estimatedSectionFooterHeightCache objectForKey:@(section)] floatValue];
    if (estimatedHeight >= 1) {
        return estimatedHeight;
    }
    else {
        if ([_delegateProxy.delegate respondsToSelector:@selector(tableView:heightForFooterInSection:)]) {
            return 20;
        }
        else {
            return self.estimatedSectionFooterHeight;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([_delegateProxy.delegate respondsToSelector:@selector(tableView:heightForFooterInSection:)]) {
        return [_delegateProxy.delegate tableView:tableView heightForFooterInSection:section];
    }
    if (tableView.dataSource == self) {
        GUTableViewSection *tableSection = [self displayedSections][section];
        if ([tableSection.footerViewNodeId length] == 0 && self.style == UITableViewStylePlain) {
            return 0;
        }
        else {
            return UITableViewAutomaticDimension;
        }
    }
    else {
        return UITableViewAutomaticDimension;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegateProxy.delegate respondsToSelector:@selector(tableView:estimatedHeightForRowAtIndexPath:)]) {
        return [_delegateProxy.delegate tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
    }
    NSNumber *rowHeightNumber = [_estimatedRowHeightCache objectForKey:indexPath];
    if (rowHeightNumber) {
        return [rowHeightNumber floatValue];
    }
    else {
        return self.estimatedRowHeight;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([_delegateProxy.delegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)]) {
        return [_delegateProxy.delegate tableView:tableView viewForHeaderInSection:section];
    }
    if (tableView.dataSource == self) {
        GUTableViewSection *tableSection = [self displayedSections][section];
        return tableSection.staticHeaderView;
    }
    else {
        return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if ([_delegateProxy.delegate respondsToSelector:@selector(tableView:viewForFooterInSection:)]) {
        return [_delegateProxy.delegate tableView:tableView viewForFooterInSection:section];
    }
    if (tableView.dataSource == self) {
        GUTableViewSection *tableSection = [self displayedSections][section];
        return tableSection.staticFooterView;
    }
    else {
        return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self displayedSections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    [self gu_genStaticCellsIfNeeds];
    return [[self displayedCellInSection:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self gu_genStaticCellsIfNeeds];
    UITableViewCell *cell = [self displayedCellInSection:indexPath.section][indexPath.row];
    return cell;
}

- (GUTableViewCell *)dequeueCellWithNodeId:(NSString *)nodeId{
    return [self dequeueCellWithNodeId:nodeId defaultAttributes:nil];
}

- (GUTableViewCell *)dequeueCellWithNodeId:(NSString *)nodeId defaultAttributes:(NSDictionary *)attributes {
    NSString *reuseCellId = [GUTableView reuseIdentifierWithCellNodeID:nodeId configure:attributes];
    GUTableViewCell *cell = [super dequeueReusableCellWithIdentifier:reuseCellId];
    if ([cell isKindOfClass:[GUTableViewCell class]]) {
        return cell;
    }
    for (GUTableViewSection *section in _sections) {
        for (GUNode *node in section.cellNodes) {
            if ([node.nodeId isEqualToString:nodeId]) {
                Class cellClass = [node objectClass];
                if (cellClass) {
                    GUTableViewCell *cell = [(GUTableViewCell *)[cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseCellId];
                    [node updateObject:cell];
                    return cell;
                }
            }
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegateProxy.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        [_delegateProxy.delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
        return;
    }
    GUTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.action) {
        [self gu_runAction:cell.action];
    }
    if (self.autoDeselectCell) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [_estimatedRowHeightCache setObject:@(cell.bounds.size.height) forKey:indexPath];
    if ([_delegateProxy.delegate respondsToSelector:@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:)]) {
        [_delegateProxy.delegate tableView:tableView didEndDisplayingCell:cell forRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingHeaderView:(UIView *)view forSection:(NSInteger)section {
    [_estimatedSectionHeaderHeightCache setObject:@(view.bounds.size.height) forKey:@(section)];
    if ([_delegateProxy.delegate respondsToSelector:@selector(tableView:didEndDisplayingHeaderView:forSection:)]) {
        [_delegateProxy.delegate tableView:tableView didEndDisplayingHeaderView:view forSection:section];
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingFooterView:(UIView *)view forSection:(NSInteger)section {
    [_estimatedSectionFooterHeightCache setObject:@(view.bounds.size.height) forKey:@(section)];
    if ([_delegateProxy.delegate respondsToSelector:@selector(tableView:didEndDisplayingFooterView:forSection:)]) {
        [_delegateProxy.delegate tableView:tableView didEndDisplayingFooterView:view forSection:section];
    }
}

- (nullable __kindof UITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier {
    @throw [NSException exceptionWithName:NSGenericException reason:@"dequeueReusableCellWithIdentifier: is not supported by GUTableView, use dequeueCellWithNodeId: instead." userInfo:nil];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_physicAnimator stop];
    if ([_delegateProxy.delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        [_delegateProxy.delegate scrollViewWillBeginDragging:scrollView];
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_respondDidScroll) {
        [_delegateProxy.delegate scrollViewDidScroll:scrollView];
        return;
    }
}

- (void)setFitContent:(BOOL)fitContent {
    if (_fitContent != fitContent) {
        _fitContent = fitContent;
        [self invalidateIntrinsicContentSize];
    }
}

- (void)setContentSize:(CGSize)contentSize {
    [super setContentSize:contentSize];
    if (_fitContent) {
        [self invalidateIntrinsicContentSize];
    }
}

- (CGSize)intrinsicContentSize {
    if (_fitContent) {
        return self.contentSize;
    }
    else {
        return [super intrinsicContentSize];
    }
}

- (void)dealloc {
    _deallocing = YES;
}



@end
