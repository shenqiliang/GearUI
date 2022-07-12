//
//  UIView+GULayout.h
//  GearUI
//
//  Created by 谌启亮 on 29/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GULayoutConstraint;

OBJC_EXTERN GULayoutConstraint *GULayoutConstraintsBestMatch(NSArray *constraints, NSUInteger *index);

NSLayoutAttribute NSLayoutAttributeFromString(NSString *attributeName);
NSString *NSStringFromLayoutAttribute(NSLayoutAttribute attribute);

@interface GULayoutPlaceHolder : NSProxy

+ (instancetype)placeHolderWithNodeId:(NSString *)nodeId;

@property (nonatomic, strong) NSString *nodeId;

- (void)updateTargetWithIdMap:(NSDictionary *)map;

@end

@interface UIView (GULayout)
@property (nonatomic, strong, readonly) NSMutableDictionary *gu_layoutFailInfo;
@property (nonatomic, strong, readonly) NSMutableDictionary *gu_layoutInfo;
- (void)gu_updateLayoutWithAttribute:(NSLayoutAttribute)layoutAttribute value:(NSString *)value;

@end
