//
//  GUVideoView.m
//  GearUI
//
//  Created by 谌启亮 on 11/08/2017.
//  Copyright © 2017 谌启亮. All rights reserved.
//

#import "GUVideoView.h"
#import <AVFoundation/AVFoundation.h>

@implementation GUVideoView {
    AVPlayerItem *_playerItem;
    __weak AVPlayerLayer *_playerLayer;
    AVPlayer *_player;
    BOOL _isPlaying;
    CADisplayLink *_updateDisplayLink;
    BOOL _isSeeking;
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _playerLayer = (id)self.layer;
        _player = [AVPlayer playerWithPlayerItem:nil];
        _playerLayer.player = _player;
        [_player addObserver:self forKeyPath:@"timeControlStatus" options:0 context:nil];
        [_player addObserver:self forKeyPath:@"status" options:0 context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishPlay:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        _updateDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
        if (@available(iOS 10.0, *)) {
            _updateDisplayLink.preferredFramesPerSecond = 30;
        } else {
            // Fallback on earlier versions
        }
        [_updateDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [_updateDisplayLink setPaused:YES];
    }
    return self;
}

- (void)finishPlay:(NSNotification *)notification {
    if (notification.object == _playerItem) {
        if (_repeat) {
            [_player seekToTime:kCMTimeZero];
            [self play];
        }
        else {
            if ([_delegate respondsToSelector:@selector(videoViewDidFinishPlay:)]) {
                [_delegate videoViewDidFinishPlay:self];
            }
        }
    }
}

- (void)setSyncedSlider:(UISlider *)syncedSlider {
    if (_syncedSlider != syncedSlider) {
        [_syncedSlider removeTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
        _syncedSlider = syncedSlider;
        [_syncedSlider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self refreshUI];
    }
}

- (void)setSyncedPlayButton:(UIButton *)syncedPlayButton {
    if (_syncedPlayButton != syncedPlayButton) {
        [_syncedPlayButton removeTarget:self action:@selector(togglePlay:) forControlEvents:UIControlEventTouchUpInside];
        _syncedPlayButton = syncedPlayButton;
        [_syncedPlayButton addTarget:self action:@selector(togglePlay:) forControlEvents:UIControlEventTouchUpInside];
        [self refreshUI];
    }
}

- (void)sliderChanged:(UISlider *)slider {
    [self seekToTime:slider.value];
}

- (void)togglePlay:(UIButton *)playButton {
    playButton.selected = !playButton.selected;
    if (playButton.selected) {
        [self play];
    }
    else {
        [self pause];
    }
}

- (void)mute {
    _player.volume = 0;
}

- (void)refreshUI {
    if (@available(iOS 10.0, *)) {
        switch (_player.timeControlStatus) {
            case AVPlayerTimeControlStatusPlaying:
                _syncedPlayButton.enabled = YES;
                _syncedPlayButton.selected = YES;
                [_updateDisplayLink setPaused:NO];
                break;
            case AVPlayerTimeControlStatusPaused:
                _syncedPlayButton.enabled = YES;
                _syncedPlayButton.selected = NO;
                [_updateDisplayLink setPaused:YES];
                break;
            case AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate:
                _syncedPlayButton.enabled = NO;
                _syncedPlayButton.selected = NO;
                [_updateDisplayLink setPaused:YES];
                break;
            default:
                break;
        }
    } else {
        // Fallback on earlier versions
    }
    switch (_player.status) {
        case AVPlayerStatusReadyToPlay:
            _syncedSlider.enabled = YES;
            CMTime duration = _player.currentItem.duration;
            if (duration.timescale > 0) {
                _syncedSlider.maximumValue = duration.value/(CGFloat)duration.timescale;
            }
            break;
        default:
            _syncedSlider.enabled = NO;
            break;
    }
}

- (void)update {
    CMTime current = _player.currentItem.currentTime;
    if (!_syncedSlider.isTracking && !_isSeeking) {
        _syncedSlider.value = current.value/(CGFloat)current.timescale;
    }
    if ([_delegate respondsToSelector:@selector(videoViewProgressDidChanged:)]) {
        [_delegate videoViewProgressDidChanged:self];
    }
}

- (NSTimeInterval)duration {
    CMTime duration = _player.currentItem.duration;
    if (duration.timescale == 0) {
        return 0;
    }
    return duration.value / (NSTimeInterval)duration.timescale;
}

- (NSTimeInterval)currentTime {
    CMTime currentTime = _player.currentItem.currentTime;
    if (currentTime.timescale == 0) {
        return 0;
    }
    return currentTime.value / (NSTimeInterval)currentTime.timescale;
}

- (void)setFileName:(NSString *)fileName {
    [self setContent:fileName];
}

- (void)setContent:(NSString *)content{
    if ([_content isEqualToString:content]) {
        return;
    }
    if ([content hasPrefix:@"http"]) {
        _playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:content]];
    }
    else {
        _playerItem = [AVPlayerItem playerItemWithURL:[[NSBundle mainBundle] URLForResource:content withExtension:nil]];
    }
    [_player replaceCurrentItemWithPlayerItem:_playerItem];
    _playerLayer.player = _player;
    [self play];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    if (newWindow == nil) {
        [self pause];
    }
    else {
        if (_isPlaying) {
            [self play];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"timeControlStatus"]) {
        [self refreshUI];
        if (@available(iOS 10.0, *)) {
            switch (_player.timeControlStatus) {
                case AVPlayerTimeControlStatusPlaying:
                    if ([_delegate respondsToSelector:@selector(videoViewDidPlay:)]) {
                        [_delegate videoViewDidPlay:self];
                    }
                    break;
                case AVPlayerTimeControlStatusPaused:
                case AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate:
                    if ([_delegate respondsToSelector:@selector(videoViewDidPause:)]) {
                        [_delegate videoViewDidPause:self];
                    }
                    break;
                default:
                    break;
            }
        } else {
            // Fallback on earlier versions
        }
    }
    else if ([keyPath isEqualToString:@"status"]) {
        [self refreshUI];
    }
}

- (void)setContentMode:(UIViewContentMode)contentMode {
    [super setContentMode:contentMode];
    if (contentMode == UIViewContentModeScaleAspectFill) {
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    else if (contentMode == UIViewContentModeScaleToFill) {
        _playerLayer.videoGravity = AVLayerVideoGravityResize;
    }
    else {
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    }
}

- (void)play
{
    [_player play];
    _isPlaying = YES;
}

-(void)pause
{
    [_player pause];
    _isPlaying = NO;
}

- (void)stop {
    [_player pause];
    _isPlaying = NO;
    [_player replaceCurrentItemWithPlayerItem:nil];
    _playerLayer.player = nil;
}

- (BOOL)isPlaying {
    return _isPlaying;
}

- (void)setRepeat:(BOOL)repeat {
    _repeat = repeat;
}

- (void)seekToTime:(NSTimeInterval)time {
    _isSeeking = YES;
    [_updateDisplayLink setPaused:YES];
    __weak id weakSelf = self;
    [_player seekToTime:CMTimeMake(time*1000, 1000) completionHandler:^(BOOL finished) {
        GUVideoView *strongSelf = weakSelf;
        strongSelf->_isSeeking = NO;
        [strongSelf->_updateDisplayLink setPaused:NO];
    }];
}

- (void)dealloc {
    [_player removeObserver:self forKeyPath:@"timeControlStatus"];
}


@end
