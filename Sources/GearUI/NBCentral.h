//
//  NBCentral.h
//  NSCentralApp
//
//  Created by 谌启亮 on 2017/7/15.
//  Copyright © 2017年 谌启亮. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NBCentral;

@protocol NBCentralDelegate <NSObject>

- (void)central:(NBCentral *)central didReceiveData:(NSData *)data;

@end

@interface NBCentral : NSObject

- (instancetype)initWithUUID:(NSString *)uuid;

- (void)writeData:(NSData *)data;

@property (nonatomic, weak) id<NBCentralDelegate> delegate;

@end
