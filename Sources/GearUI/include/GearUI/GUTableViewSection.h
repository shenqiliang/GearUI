//
//  GUTableViewSection.h
//  GearUI
//
//  Created by 谌启亮 on 09/03/2018.
//  Copyright © 2018 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GUNodeViewProtocol.h"

/// TableView Section对象
@interface GUTableViewSection : NSObject <GUNodeProtocol>

/// Section Header View的nodeId
@property (nonatomic, strong) NSString *headerViewNodeId;

/// Section Footer View的nodeId
@property (nonatomic, strong) NSString *footerViewNodeId;

/// 是否隐藏这个Section
@property (nonatomic) BOOL disableLayout;

@end
