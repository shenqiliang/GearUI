//
//  GUVideoView.h
//  GearUI
//
//  Created by 谌启亮 on 11/08/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GUVideoView;

/// 视频播放代理
@protocol GUVideoViewDelegate<NSObject>
@optional

/// 完成播放回调
- (void)videoViewDidFinishPlay:(GUVideoView *)videoView;

/// 暂停播放回调
- (void)videoViewDidPause:(GUVideoView *)videoView;

/// 开始播放回调
- (void)videoViewDidPlay:(GUVideoView *)videoView;

/// 视频进度改变回调
- (void)videoViewProgressDidChanged:(GUVideoView *)videoView;

@end

/// 视频播放视图
@interface GUVideoView : UIView

/// 视频内容，可以为url或视频文件名
@property (nonatomic, strong) NSString *content;

/// 是否循环播放
@property (nonatomic) BOOL repeat;

/// 是否正在播放
@property (nonatomic, readonly) BOOL isPlaying;

/// 播放行为回调代理
@property (nonatomic, weak) id<GUVideoViewDelegate> delegate;

/// 同步进度条
@property (nonatomic, weak) UISlider *syncedSlider;

/// 同步播放按钮。播放时按钮进入选中（selected）状态。
@property (nonatomic, weak) UIButton *syncedPlayButton;

/// 视频时长
@property (nonatomic, readonly) NSTimeInterval duration;

/// 视频当前进度
@property (nonatomic, readonly) NSTimeInterval currentTime;

/// 播放
- (void)play;

/// 静音
- (void)mute;

/// 暂停
- (void)pause;

/// 停止
- (void)stop;

/// 进度拖放
/// @param time 进度时间点
- (void)seekToTime:(NSTimeInterval)time;

@end
