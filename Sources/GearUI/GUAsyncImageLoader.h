//
//  GUAsyncImageLoader.h
//  GearUI
//
//  Created by 谌启亮 on 2021/12/20.
//

#import <Foundation/Foundation.h>
#import "GUConfigure.h"


@interface GUAsyncImageLoader : NSObject

- (instancetype)initWithTarget:(id)target setter:(SEL)setter imageView:(UIImageView *)imageView;
- (instancetype)initWithUpdateImageHandler:(void(^)(UIImage *))updateImageHandler imageView:(UIImageView *)imageView;

@property (nonatomic, strong) NSString *content;

@property(nonatomic, strong) id<GUImageLoadOperation> downloadOperation;

@property (nonatomic, strong) UIImage *placeholderImage;

@property (nonatomic) BOOL useFadeTransition;

- (void)invalidate;

- (void)cancelImageRequest;

@end

