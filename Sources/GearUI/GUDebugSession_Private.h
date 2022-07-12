//
//  GUDebugSession_Private.h
//  GearUI
//
//  Created by 谌启亮 on 11/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUDebugSession.h"

@interface GUDebugSession ()

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableArray *relatedFileNames;

- (void)updateWithString:(NSString *)string;
- (void)updateForReletedFileNames;

@end
