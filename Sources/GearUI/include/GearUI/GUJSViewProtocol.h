//
//  GUJSViewProtocol.h
//  GearUI
//
//  Created by 谌启亮 on 03/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "GUJSObjectProtocol.h"

@protocol GUNodeViewProtocol;

@protocol GUJSViewProtocol <GUJSObjectProtocol, JSExport>

- (UIView<GUNodeViewProtocol> *)viewWithNodeId:(NSString *)nodeId NS_SWIFT_NAME(view(nodeId:));
- (void)setKeyPathAttributes:(NSDictionary<NSString *, id> *)keyPathAttributes;
- (void)setAttribute:(id)attribute forKeyPath:(NSString *)keyPath;

@end
