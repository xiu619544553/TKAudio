//
//  TKRecordItem.m
//  TKAudio
//
//  Created by hanxiuhui on 2019/8/3.
//  Copyright © 2019 TK. All rights reserved.
//

#import "TKRecordItem.h"
#import <Masonry.h>
#import "TKRecordManager.h"
#import "TKMacro.h"

@import AVFoundation;
@import AudioToolbox;

@interface TKRecordItem () <AVAudioPlayerDelegate>

@property (nonatomic, copy) NSString *wavPath;
@property (nonatomic, strong) AVAudioPlayer *player;

@property (nonatomic, strong) NSMutableArray<UIImage *> *animatedImages;

@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UIButton *playVoiceButton;
@property (nonatomic, strong) UIImageView *voiceAnimatedImageView;

@end

@implementation TKRecordItem

#pragma mark - Init Methods

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.whiteColor;
        
        [self addSubview:self.durationLabel];
        [self addSubview:self.playVoiceButton];
        [self.playVoiceButton addSubview:self.voiceAnimatedImageView];
        
        [self.playVoiceButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(10.f);
            make.top.bottom.equalTo(self);
            make.width.mas_equalTo(self.playVoiceButton.currentImage.size.width);
        }];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"StockRecordItem_被销毁");
}

- (void)updateUI {
    [self.voiceAnimatedImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.playVoiceButton.mas_left).offset(50.f/2.f);
        make.centerY.mas_equalTo(self.playVoiceButton.mas_centerY);
    }];
    
    [self.durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.playVoiceButton.mas_right).offset(15);
        make.centerY.mas_equalTo(self.playVoiceButton.mas_centerY);
    }];
}

#pragma mark - Event Methods

- (void)playVoiceButtonClick:(UIButton *)sender
{
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
    sender.selected = !sender.isSelected;
    if (sender.isSelected) {
        // 播放音频
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:[TKRecordManager getWavAbsolutePath]] error:&error];
        _player.delegate = self;
        [_player play];
        if (error) {
            NSLog(@"播放音频 error_%@", error);
        } else {
            [_voiceAnimatedImageView startAnimating];
        }
    } else {
        // 暂停音频
        [_player stop];
        [_voiceAnimatedImageView stopAnimating];
        _voiceAnimatedImageView.image = [UIImage imageNamed:@"voice_animation_3"];
    }
}

- (void)stopPlay
{
    [_player stop];
    [_voiceAnimatedImageView stopAnimating];
    _voiceAnimatedImageView.image = [UIImage imageNamed:@"voice_animation_3"];
}

#pragma mark - AVAudioPlayerDelegate Methods

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"播放完毕");
    _playVoiceButton.selected = NO;
    [_voiceAnimatedImageView stopAnimating];
    _voiceAnimatedImageView.image = [UIImage imageNamed:@"voice_animation_3"];
}

#pragma mark - setter

- (void)setAmrPath:(NSString *)amrPath {
    _amrPath = amrPath;
    
    self.durationLabel.hidden = NO;
    self.voiceAnimatedImageView.hidden = NO;
    
    [self updateUI];
}

- (void)setRecordTime:(NSString *)recordTime {
    _recordTime = recordTime;
    self.durationLabel.text = recordTime;
}


#pragma mark - getter

- (UIButton *)playVoiceButton {
    if (!_playVoiceButton) {
        _playVoiceButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playVoiceButton.adjustsImageWhenHighlighted = NO;
        _playVoiceButton.contentMode = UIViewContentModeScaleAspectFit;
        [_playVoiceButton setImage:[UIImage imageNamed:@"audio_part_item"] forState:UIControlStateNormal];
        [_playVoiceButton addTarget:self
                               action:@selector(playVoiceButtonClick:)
                     forControlEvents:UIControlEventTouchUpInside];
    }
    return _playVoiceButton;
}

- (UIImageView *)voiceAnimatedImageView {
    if (!_voiceAnimatedImageView) {
        _voiceAnimatedImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"voice_animation_3"]];
        _voiceAnimatedImageView.hidden = YES;
        _voiceAnimatedImageView.animationImages = self.animatedImages;
        _voiceAnimatedImageView.animationDuration = 1.0f;
    }
    return _voiceAnimatedImageView;
}

- (UILabel *)durationLabel {
    if (!_durationLabel) {
        _durationLabel = [UILabel new];
        _durationLabel.font = [UIFont systemFontOfSize:14.f];
        _durationLabel.hidden = YES;
        _durationLabel.textColor = TKWordColor;
    }
    return _durationLabel;
}

- (NSMutableArray<UIImage *> *)animatedImages {
    if (!_animatedImages) {
        _animatedImages = @[].mutableCopy;
        
        for (int i = 1; i < 4; i++) {
            UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"voice_animation_%@", @(i)]];
            [_animatedImages addObject:image];
        }
    }
    return _animatedImages;
}
@end
