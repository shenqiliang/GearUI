//
//  GUDataBindingObserver.h
//  GearUI
//
//  Created by 谌启亮 on 2022/4/1.
//

#import <Foundation/Foundation.h>
#import <GearUI/GULayoutView.h>

NS_ASSUME_NONNULL_BEGIN

//FOUNDATION_EXTERN NSString *GUDataBindingObserverMutiple

@interface GUDataBindingObserver : NSObject

@property(nonatomic, strong) NSString *keyPath;
@property(nonatomic, strong) NSString *objectKeyPath;

- (instancetype)initWithLayoutView:(GULayoutView *)layoutView keyPath:(NSString *)keyPath object:(NSObject *)obj objectKeyPath:(NSString *)objectKeyPath map:(id (^ __nullable)(__nullable id value))map;
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
