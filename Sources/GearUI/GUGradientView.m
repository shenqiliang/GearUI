//
//  GUGradientView.m
//  GearUI
//
//  Created by 谌启亮 on 04/07/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUGradientView.h"
#import "NSString+GUValue.h"

@implementation GUGradientView
@dynamic layer;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.startPoint = CGPointMake(0.5, 0);
        self.layer.endPoint = CGPointMake(0.5, 1);
        self.layer.locations = @[@0, @1];
        self.layer.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor blackColor].CGColor];
    }
    return self;
}

+ (Class)layerClass{
    return [CAGradientLayer class];
}

- (void)setColors:(NSArray *)colors {
    if ([colors isKindOfClass:[NSString class]]) {
        [self updateCombinedAttributes:@{@"colors":colors}];
    }
}

- (void)setLocations:(NSArray<NSNumber *> *)locations {
    if ([locations isKindOfClass:[NSString class]]) {
        [self updateCombinedAttributes:@{@"locations":locations}];
    }
}

- (void)setStartPoint:(CGPoint)startPoint {
    self.layer.startPoint = startPoint;
}

- (void)setEndPoint:(CGPoint)endPoint {
    self.layer.endPoint = endPoint;
}

- (NSDictionary *)updateCombinedAttributes:(NSDictionary *)attributes{
    NSMutableDictionary *allAttr = [attributes mutableCopy];
    if (allAttr[@"startPoint"]) {
        self.layer.startPoint = CGPointFromString(allAttr[@"startPoint"]);
    }
    if (allAttr[@"endPoint"]) {
        self.layer.endPoint = CGPointFromString(allAttr[@"endPoint"]);
    }
    if (allAttr[@"colors"]) {
        NSString *colors = allAttr[@"colors"];
        NSMutableArray *array = [NSMutableArray array];
        for (NSString *colorString in [colors componentsSeparatedByString:@","]) {
            UIColor *color = [[colorString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] gu_UIColorValue];
            if (color == nil) {
                color = [UIColor clearColor];
            }
            [array addObject:(id)color.CGColor];
        }
        self.layer.colors = [array copy];
    }
    if (allAttr[@"locations"]) {
        NSString *locations = allAttr[@"locations"];
        NSMutableArray *array = [NSMutableArray array];
        for (NSString *location in [locations componentsSeparatedByString:@","]) {
            [array addObject:@([location floatValue])];
        }
        self.layer.locations = [array copy];
    }
    [allAttr removeObjectForKey:@"startPoint"];
    [allAttr removeObjectForKey:@"endPoint"];
    [allAttr removeObjectForKey:@"colors"];
    [allAttr removeObjectForKey:@"locations"];
    return [allAttr copy];
}



@end
