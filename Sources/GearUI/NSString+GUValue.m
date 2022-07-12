//
//  NSString+GUValue.m
//  GearUI
//
//  Created by 谌启亮 on 16/4/16.
//  Copyright © 2016年 谌启亮. All rights reserved.
//

#import "NSString+GUValue.h"
#import "GUConfigure.h"
#import "GULog.h"

@implementation NSString (GUValue)

- (UIColor *)gu_UIColorValue
{
    int r = 0, g = 0, b = 0, a = 0xFF;
    if ([self hasPrefix:@"#"]) {
        if(sscanf([self UTF8String], "#%02x%02x%02x %d%%", &r, &g, &b, &a)==4){
            return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a/100.0];
        }
        else if(sscanf([self UTF8String], "#%02x%02x%02x%02x", &r, &g, &b, &a)>=3){
            return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a/255.0];
        }
        else{
            return [UIColor blackColor];
        }
    }
    else{
        NSString *selName = [NSString stringWithFormat:@"%@Color", self];
        SEL sel = NSSelectorFromString(selName);
        if ([(id)[UIColor class] respondsToSelector:sel]) {
            return [UIColor performSelector:sel];
        }
        else{
            return nil;
        }
    }
}

- (UIFont *)gu_UIFontValue
{
    static NSDictionary *fontWeightDescMap = nil;
    if (fontWeightDescMap == nil) {
        fontWeightDescMap = @{
            @"thin": @(UIFontWeightThin),
            @"w100": @(UIFontWeightThin),
            
            @"ultralight": @(UIFontWeightUltraLight),
            @"w200": @(UIFontWeightUltraLight),
            

            @"light": @(UIFontWeightLight),
            @"w300": @(UIFontWeightLight),
            
            @"w400": @(UIFontWeightRegular),
            
            @"medium": @(UIFontWeightMedium),
            @"w500": @(UIFontWeightMedium),

            @"semibold": @(UIFontWeightSemibold),
            @"w600": @(UIFontWeightSemibold),

            @"bold": @(UIFontWeightBold),
            @"w700": @(UIFontWeightBold),
            
            @"heavy": @(UIFontWeightHeavy),
            @"w800": @(UIFontWeightHeavy),

            @"black": @(UIFontWeightBlack),
            @"w900": @(UIFontWeightBlack),

        };
    }
    
    NSArray *components = [self componentsSeparatedByString:@";"];
    if ([components count] == 1) {
        return [UIFont systemFontOfSize:[components[0] floatValue]];
    }
    else if ([components count] == 2) {
        NSNumber *fontWeight = fontWeightDescMap[[components[0] lowercaseString]];
        if (fontWeight != nil) {
            return [UIFont systemFontOfSize:[components[1] floatValue] weight:[fontWeight floatValue]];
        }
        else {
            UIFont *font = [UIFont fontWithName:components[0] size:[components[1] floatValue]];
            if (font == nil) {
                GUFail(@"font name %@ no supported", components[0]);
            }
            return font;
        }
    }
    return nil;
}

- (UIImage *)gu_UIImageValue
{
    NSArray *components = [self componentsSeparatedByString:@";"];
    UIImage *image = nil;
    if ([components count] >= 1) {
        if ([[GUConfigure sharedInstance].imageLoadDelegate respondsToSelector:@selector(imageNamed:)]) {
            image = [[GUConfigure sharedInstance].imageLoadDelegate imageNamed:components[0]];
        }
        if (image == nil && ![self hasPrefix:@"#"]) {
            image = [UIImage imageNamed:components[0]];
        }
        if (image == nil) {
            UIColor *color = [components[0] gu_UIColorValue];
            if (color) {
                UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, [UIScreen mainScreen].scale);
                [color setFill];
                UIRectFill(CGRectMake(0, 0, 1, 1));
                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
            else {
                NSScanner *scanner = [NSScanner scannerWithString:[components[0] stringByReplacingOccurrencesOfString:@" " withString:@""]];
                NSString *shapeName = nil;
                NSString *paramsString = nil;
                if([scanner scanUpToString:@"(" intoString:&shapeName] && [scanner scanString:@"(" intoString:nil]
                   && [scanner scanUpToString:@")" intoString:&paramsString] && [scanner scanString:@")" intoString:nil]) {
                    NSScanner *scanner = [NSScanner scannerWithString:paramsString];
                    CGFloat radius = 0;
                    CGFloat width = 0;
                    UIColor *fillColor = nil;
                    UIColor *strokeColor = nil;
                    NSArray<NSValue *> *points = nil;
                    NSString *paramName = nil;
                    UIBezierPath *path = nil;
                    while ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@":"] intoString:&paramName] && [scanner scanString:@":" intoString:NULL]) {
                        NSString *paramValue = nil;
                        paramName = [paramName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        if ([scanner scanString:@"[" intoString:nil]) {
                            [scanner scanUpToString:@"]" intoString:&paramValue];
                            [scanner scanString:@"]," intoString:NULL];
                        }
                        else {
                            [scanner scanUpToString:@"," intoString:&paramValue];
                            [scanner scanString:@"," intoString:NULL];
                        }
                        if([paramName isEqualToString:@"radius"] || [paramName isEqualToString:@"corner"]  || [paramName isEqualToString:@"cornerRadius"]) {
                            radius = [paramValue doubleValue];
                        }
                        else if ([paramName isEqualToString:@"fillColor"] || [paramName isEqualToString:@"fill"] || [paramName isEqualToString:@"color"]) {
                            fillColor = [paramValue gu_UIColorValue];
                        }
                        else if ([paramName isEqualToString:@"stroke"] || [paramName isEqualToString:@"strokeColor"]) {
                            strokeColor = [paramValue gu_UIColorValue];
                        }
                        else if ([paramName isEqualToString:@"width"] || [paramName isEqualToString:@"lineWidth"]) {
                            width = [paramValue floatValue];
                        }
                        else if ([paramName isEqualToString:@"points"]) {
                            NSMutableArray<NSValue *> *array = [NSMutableArray array];
                            for (NSString *pointString in [paramValue componentsSeparatedByString:@"},"]) {
                                [array addObject:[NSValue valueWithCGPoint:CGPointFromString([pointString stringByAppendingString:@"}"])]];
                            }
                            points = [array copy];
                        }
                        
                    }
                    BOOL stretch = NO;
                    if ([shapeName isEqualToString:@"circle"]) {
                        path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, radius*2, radius*2)];
                    }
                    if ([shapeName isEqualToString:@"round"] || [shapeName isEqualToString:@"roundRect"]) {
                        path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, radius*2, radius*2) cornerRadius:radius];
                        stretch = YES;
                    }
                    else if ([shapeName isEqualToString:@"triangle"]) {
                        if ([points count] == 3) {
                            path = [UIBezierPath bezierPath];
                            [path moveToPoint:[points[0] CGPointValue]];
                            [path addLineToPoint:[points[1] CGPointValue]];
                            [path addLineToPoint:[points[2] CGPointValue]];
                            [path closePath];
                        }
                    }
                    if (width > 0) {
                        path.lineWidth = width;
                        [path applyTransform:CGAffineTransformMakeTranslation(width/2, width/2)];
                    }
                    CGSize imageSize = path.bounds.size;
                    imageSize.width+=width;
                    imageSize.height+=width;
                    UIGraphicsBeginImageContextWithOptions(imageSize, NO, [UIScreen mainScreen].scale);
                    if (fillColor != nil) {
                        [fillColor setFill];
                        [path fill];
                    }
                    if (strokeColor != nil) {
                        [strokeColor setStroke];
                        [path stroke];
                    }
                    image = UIGraphicsGetImageFromCurrentImageContext();
                    if (stretch) {
                        image = [image stretchableImageWithLeftCapWidth:image.size.width/2 topCapHeight:image.size.height/2];
                    }
                    UIGraphicsEndImageContext();
                }
            }
        }
    }
        
        
    if ([components count] >= 2) {
        CGPoint cap = CGPointFromString(components[1]);
        if (cap.x > __FLT_EPSILON__ || cap.y > __FLT_EPSILON__) {
            image = [image stretchableImageWithLeftCapWidth:cap.x topCapHeight:cap.y];
        }
    }
    return image;
}


@end
