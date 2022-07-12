//
//  GULayoutConstraint.h
//  GearUI
//
//  Created by 谌启亮 on 29/06/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GULayoutPlaceHolder;

@interface GULayoutConstraint : NSLayoutConstraint

@property (nonatomic, strong) NSString *firstNodeId;
@property (nonatomic, strong) NSString *secondNodeId;

@property (nonatomic, strong) NSString *attributeString;

@end
