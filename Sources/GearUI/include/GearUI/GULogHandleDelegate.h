//
//  GULogHandlerDelegate.h
//  Pods
//
//  Created by 谌启亮 on 2021/12/24.
//

/// 日志回调代理
@protocol GULogHandleDelegate <NSObject>

/// 调试信息打印回调
/// @param message 日志信息
- (void)debug:(NSString *)message;

/// 警告信息打印回调
/// @param message 日志信息
- (void)warning:(NSString *)message;

/// 错误信息打印回调
/// @param message 日志信息
- (void)error:(NSString *)message;

/// 崩溃信息打印回调
/// @param message 日志信息
- (void)fail:(NSString *)message;


@end
