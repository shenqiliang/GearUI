//
//  GUCollectionView.m
//  GearUI
//
//  Created by 谌启亮 on 05/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUCollectionView.h"
#import "GUCollectionViewCell.h"
#import "GUDefines.h"

@interface GUCollectionViewLayout : UICollectionViewFlowLayout
@property (nonatomic) BOOL alignLeft;
@end

@implementation GUCollectionViewLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    
    NSArray *attributesForElementsInRect = [super layoutAttributesForElementsInRect:rect];
    if (_alignLeft) {
        NSMutableArray *newAttributesForElementsInRect = [[NSMutableArray alloc] initWithCapacity:attributesForElementsInRect.count];
        
        CGFloat leftMargin = self.sectionInset.left; //initalized to silence compiler, and actaully safer, but not planning to use.
        
        //this loop assumes attributes are in IndexPath order
        for (UICollectionViewLayoutAttributes *attributes in attributesForElementsInRect) {
            if (attributes.frame.origin.x == self.sectionInset.left) {
                leftMargin = self.sectionInset.left; //will add outside loop
            } else {
                CGRect newLeftAlignedFrame = attributes.frame;
                newLeftAlignedFrame.origin.x = leftMargin;
                attributes.frame = newLeftAlignedFrame;
            }
            
            leftMargin += attributes.frame.size.width + self.minimumInteritemSpacing;
            [newAttributesForElementsInRect addObject:attributes];
        }
        
        return newAttributesForElementsInRect;
    }
    else {
        return attributesForElementsInRect;
    }

}
@end


@interface GUCollectionView () <UICollectionViewDelegate, UICollectionViewDataSource>


@end

@implementation GUCollectionView
{
    GUCollectionViewLayout *_flowLayout;
    NSArray *_staticCellNodes;
    CGRect _lastLayoutRect;
}

FORWARD_PROPERTY(estimatedItemSize, setEstimatedItemSize:, estimatedItemSize, CGSize, _flowLayout)

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    if (layout == nil) {
        _flowLayout = [GUCollectionViewLayout new];
        _flowLayout.estimatedItemSize = CGSizeMake(155, 155);
    }
    self = [super initWithFrame:frame collectionViewLayout:_flowLayout];
    if (self) {
        super.dataSource = self;
        super.delegate = self;
        
        if (@available(iOS 11, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return self;
}

- (void)setAlignLeft:(BOOL)alignLeft {
    _alignLeft = alignLeft;
    _flowLayout.alignLeft = alignLeft;
}

- (NSArray<GUNode *> *)updateSubnodes:(NSArray<GUNode *> *)subnodes {
    NSMutableArray *array = [NSMutableArray array];
    for (GUNode *cellNode in subnodes) {
        if ([cellNode isKindOfClass:[GUNode class]]) {
            [self registerClass:[cellNode objectClass] forCellWithReuseIdentifier:cellNode.nodeId];
            [array addObject:cellNode];
        }
    }
    _staticCellNodes = [array copy];
    return [NSArray array];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_staticCellNodes count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GUNode *node = _staticCellNodes[indexPath.row];
    GUCollectionViewCell *cell = [self dequeueReusableCellWithReuseIdentifier:node.nodeId forIndexPath:indexPath];
    if (cell.nodeId == nil) {
        [node updateObject:cell];
    }
    return cell;
}


- (void)setScrollDirection:(NSString *)scrollDirection {
    if (_scrollDirection != scrollDirection) {
        _scrollDirection = scrollDirection;
        if ([scrollDirection isEqualToString:@"h"] || [scrollDirection isEqualToString:@"horizontal"] || [scrollDirection isEqualToString:@"left-right"]) {
            _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        }
        else {
            _flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        }
        [_flowLayout invalidateLayout];
    }
}

- (GUCollectionViewCell *)dequeueCellWithNodeId:(NSString *)nodeId forIndexPath:(NSIndexPath *)indexPath {
    GUCollectionViewCell *cell = [self dequeueReusableCellWithReuseIdentifier:nodeId forIndexPath:indexPath];
    if ([cell.nodeId length] == 0) {
        for (GUNode *node in _staticCellNodes) {
            if ([node.nodeId isEqualToString:nodeId]) {
                [node updateObject:cell];
                break;
            }
        }
    }
    return cell;
}

- (void)setMinimumLineSpacing:(CGFloat)minimumLineSpacing {
    _flowLayout.minimumLineSpacing = minimumLineSpacing;
}

- (void)setMinimumInteritemSpacing:(CGFloat)minimumInteritemSpacing {
    _flowLayout.minimumInteritemSpacing = minimumInteritemSpacing;
}

- (CGFloat)minimumInteritemSpacing {
    return _flowLayout.minimumInteritemSpacing;
}

- (CGFloat)minimumLineSpacing {
    return _flowLayout.minimumLineSpacing;
}

- (void)layoutSubviews {
    if (!CGRectEqualToRect(self.frame, _lastLayoutRect)) {
        [self.collectionViewLayout invalidateLayout];
        _lastLayoutRect = self.frame;
    }
    if ([self.layoutSubViewDelegate respondsToSelector:@selector(collectionViewWillLayoutSubviews:)]) {
        [self.layoutSubViewDelegate collectionViewWillLayoutSubviews:self];
    }
    [super layoutSubviews];
}

@end
