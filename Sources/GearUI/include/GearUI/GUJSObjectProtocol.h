//
//  GUJSObjectProtocol.h
//  GearUI
//
//  Created by 谌启亮 on 03/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol GUJSObjectProtocol <NSObject, JSExport>

//可选属性
@property (nonatomic, strong) NSString *nodeId;

JSExportAs(update,
- (void)setKeyPathAttributes:(NSDictionary<NSString *, id> *)keyPathAttributes
);
JSExportAs(set,
- (void)setAttribute:(id)attribute forKeyPath:(NSString *)keyPath
);

@end
