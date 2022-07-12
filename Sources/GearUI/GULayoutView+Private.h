//
//  GULayoutView+Private.h
//  GearUI
//
//  Created by 谌启亮 on 03/04/2018.
//  Copyright © 2018 谌启亮. All rights reserved.
//
#import <GearUI/GearUI.h>

@interface GULayoutView ()

//私有方法，禁止外部执行js
- (BOOL)__runJavaScript:(NSString *)js;
- (BOOL)__runJavaScript:(NSString *)js withSourceURL:(NSURL *)url;

- (void)showDebugErrorMessage:(NSString *)message;

@end
