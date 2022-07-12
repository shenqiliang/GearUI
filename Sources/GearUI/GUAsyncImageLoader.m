//
//  GUAsyncImageLoader.m
//  GearUI
//
//  Created by 谌启亮 on 2021/12/20.
//

#import "GUAsyncImageLoader.h"
#import "NSString+GUValue.h"

@interface GUAsyncImageLoader()

@property(nonatomic, weak) id target;
@property(nonatomic, weak) UIImageView *imageView;
@property(nonatomic) BOOL finishedLoad;

@property(nonatomic, copy) void(^updateImageHandler)(UIImage *);

@end

@implementation GUAsyncImageLoader
{
    SEL _setter;
}

- (instancetype)initWithTarget:(id)target setter:(SEL)setter imageView:(UIImageView *)imageView
{
    self = [super init];
    if (self) {
        _target = target;
        _setter = setter;
        _imageView = imageView;
    }
    return self;
}

- (instancetype)initWithUpdateImageHandler:(void(^)(UIImage *))updateImageHandler imageView:(UIImageView *)imageView
{
    self = [super init];
    if (self) {
        _updateImageHandler = updateImageHandler;
        _imageView = imageView;
    }
    return self;
}

- (void)setImage:(UIImage *)image {
    if (_target != nil && _setter != nil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_target performSelector:_setter withObject:image];
#pragma clang diagnostic pop
    }
    else if (_updateImageHandler != nil) {
        _updateImageHandler(image);
    }
    if ([image.images count] > 1) {
        [_imageView startAnimating];
    }
}

- (void)invalidate {
    _content = nil;
    [self _cancelImageRequest];
}

- (void)cancelImageRequest {
    [self _cancelImageRequest];
}

- (void)_cancelImageRequest {
    [self.downloadOperation cancel];
    self.downloadOperation = nil;
}

- (void)setContent:(NSString *)content {
    if ([_content isEqualToString:content]) {
        if (_finishedLoad) {
            return;
        }
        else if (self.downloadOperation != nil) {
            return;
        }
    }
    _content = content;
    [self _cancelImageRequest];
    if ([content length] == 0) {
        self.image = self.placeholderImage;
        _finishedLoad = YES;
        return;
    }
    if ([content hasPrefix:@"http"]) {
        self.image = self.placeholderImage;
        __weak GUAsyncImageLoader *weakSelf = self;
        NSURL *imageURL = [NSURL URLWithString:content];
        if (imageURL == nil) {
            imageURL = [NSURL URLWithString:[content stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        }
        self.finishedLoad = NO;
        self.downloadOperation = [[GUConfigure sharedInstance].imageLoadDelegate loadImageFromURL:imageURL completed:^(NSError *error, UIImage *image, BOOL useNetwork) {
            GUAsyncImageLoader *strongSelf = weakSelf;
            if (strongSelf == nil || content != strongSelf.content) {
                return;
            }
            if (image) {
                UIImageView *imageView = strongSelf.imageView;
                NSTimeInterval animationDuration = imageView.animationDuration;
                if (animationDuration > __FLT_EPSILON__ && [image.images count] > 0) {
                    image = [UIImage animatedImageWithImages:image.images duration:animationDuration];
                }
                if (strongSelf.useFadeTransition && imageView != nil && useNetwork) {
                    [UIView transitionWithView:imageView
                            duration:0.3
                            options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                        strongSelf.image = image;
                    } completion:nil];
                } else {
                    strongSelf.image = image;
                }
            }
            strongSelf.downloadOperation = nil;
            strongSelf.finishedLoad = YES;
        }];
    }
    else if ([content hasPrefix:@"/"]) {
        self.image = [UIImage imageWithContentsOfFile:content];
        self.finishedLoad = YES;
    }
    else {
        if ([content rangeOfString:@"%"].location != NSNotFound) {
            NSMutableArray *images = [NSMutableArray array];
            NSString *imageName = [NSString stringWithFormat:content, 0];
            if ([imageName rangeOfString:@"%"].location == NSNotFound) {
                UIImage *image = [imageName gu_UIImageValue];
                if (image) {
                    [images addObject:image];
                }
                for (int i = 1; i < 200; i++) {
                    NSString *imageName = [NSString stringWithFormat:content, i];
                    UIImage *image = [imageName gu_UIImageValue];
                    if (image) {
                        [images addObject:image];
                    }
                    else {
                        break;
                    }
                }
            }
            
            self.image = [UIImage animatedImageWithImages:images duration:self.imageView.animationDuration];
        }
        else {
            self.image = [content gu_UIImageValue] ?: _placeholderImage;
        }
        self.finishedLoad = YES;
    }
}

- (void)dealloc {
    [_downloadOperation cancel];
}

@end
