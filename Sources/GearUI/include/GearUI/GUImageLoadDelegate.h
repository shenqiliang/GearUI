//
//  GUImageLoadDelegate.h
//  TBText
//
//  Created by 谌启亮 on 15/9/2.
//  Copyright (c) 2015年 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^GUImageLoadCompletedBlock)(NSError *error, UIImage *image, BOOL useNetwork);

@protocol GUImageLoadOperation <NSObject>

- (void)cancel;

@end


@protocol GUImageLoadDelegate <NSObject>

@required
/**
 载入网络图片代理，返回一个可取消对象，用来取消此url图片的下载操作。

 @param url 图片url
 @param completedBlock 图片载入完成时，回调图片或者错误对象
 @return 取消操作对象，必须实现cancel方法，用来取消此url的下载。
 */
- (id<GUImageLoadOperation>)loadImageFromURL:(NSURL *)url completed:(GUImageLoadCompletedBlock)completedBlock;

@optional
// image name加载图片
- (UIImage *)imageNamed:(NSString *)imageNamed;

@end
