//
//  TKRecordManager.m
//  TKAudio
//
//  Created by hanxiuhui on 2019/8/3.
//  Copyright © 2019 TK. All rights reserved.
//

#import "TKRecordManager.h"
#import "VoiceConverter.h"
#import "NSFileManager+BDAdd.h"

@import AVFoundation;
@import AudioToolbox;

@interface TKRecordManager ()
@property (strong, nonatomic) AVAudioRecorder *recorder;
/// 检测音量计时器
@property (nonatomic, strong) NSTimer *detectVolumeTimer;
/// wav绝对路径
@property (nonatomic, copy) NSString *wavPath;
/// amr绝对路径
@property (nonatomic, copy) NSString *amrPath;
@end

@implementation TKRecordManager
- (void)dealloc {
    NSLog(@"%@ > 销毁..", NSStringFromClass(self.class));
}

- (void)addDetectVolumeTimer {
    if (self.detectVolumeTimer) {
        [self.detectVolumeTimer invalidate];
        self.detectVolumeTimer = nil;
    }
    self.detectVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(detectVolumeTimerAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.detectVolumeTimer forMode:NSRunLoopCommonModes];
}

// 实时检测音量
- (void)detectVolumeTimerAction {
    [self.recorder updateMeters];
    float peakPower = [self.recorder averagePowerForChannel: 0];
    double peakPowerForChannel = pow(10, (0.05 * peakPower));
    if (self.delegate && [self.delegate respondsToSelector:@selector(realTimeUpdateVolume:)]) {
        [self.delegate realTimeUpdateVolume:peakPowerForChannel];
    }
}

#pragma mark - Public Methods

- (void)startRecorder {
    // 删除amr、wav文件
    [[self class] remove_Amr_Wav_Record];
    
    // 初始化录音
    self.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:self.wavPath]
                                                settings:[self settings]
                                                   error:nil];
    // 开启音量检测
    self.recorder.meteringEnabled = YES;
    
    // 准备录音
    if ([self.recorder prepareToRecord]){
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        // 开始录音
        if ([self.recorder record]){
            NSLog(@"开始录音");
            [self addDetectVolumeTimer];
        }
    }
}

- (void)stopRecorder {
    double cTime = self.recorder.currentTime;
    [self.recorder stop];
    [self resetAudioSessionCategoryPlayback];
    
    if (cTime >= 1) {
        [self convertWavToAmr];
    } else {
        // wav转amr失败
        NSLog(@"wav转amr失败");
        [self.recorder deleteRecording];
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(convertFaild)]) {
            [self.delegate convertFaild];
        }
    }
    
    self.recorder = nil;
    
    [self.detectVolumeTimer invalidate];
    self.detectVolumeTimer = nil;
}

- (void)cancelRecorder {
    [self.recorder stop];
    [self.recorder deleteRecording];
    [self resetAudioSessionCategoryPlayback];
    
    [self.detectVolumeTimer invalidate];
    self.detectVolumeTimer = nil;
}

// 恢复设置回放标志，否则会导致其它播放声音也会变小
- (void)resetAudioSessionCategoryPlayback {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

// wav转为amr格式
- (void)convertWavToAmr {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int result = [VoiceConverter convertWavToAmr:self.wavPath amrSavePath:self.amrPath];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (@(result).boolValue) {
                // wav转amr成功
                NSLog(@"wav转amr成功");
                NSData *amrData = [NSData dataWithContentsOfFile:self.amrPath];
                if (self.delegate &&
                    [self.delegate respondsToSelector:@selector(convertSuccessAmrData:amrPath:)]) {
                    [self.delegate convertSuccessAmrData:amrData amrPath:self.amrPath];
                }
                
                // 删除wav文件
                [self.recorder deleteRecording];
            }
        });
    });
}

// 获取录音设置
- (NSDictionary *)settings {
    NSMutableDictionary *settingDict = [NSMutableDictionary dictionary];
    // 录音格式，录制 wav样式，无压缩
    [settingDict setObject:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    // 采样率
    [settingDict setObject:[NSNumber numberWithFloat:8000.f] forKey:AVSampleRateKey];
    // 采样位数 默认 16
    [settingDict setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    // 通道的数目
    [settingDict setObject:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    // 音频编码质量
    [settingDict setObject:[NSNumber numberWithInt:AVAudioQualityMedium] forKey:AVEncoderAudioQualityKey];
    
    return [settingDict copy];
}

#pragma mark - Private Methods

// 生成文件路径
+ (NSString *)getPathByFileName:(NSString *)fileName ofType:(NSString *)type {
    NSString *directory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *filePath = [directory stringByAppendingPathComponent:fileName];
    NSString *itemPath = [[filePath stringByAppendingPathExtension:type] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return itemPath;
}

+ (NSString *)getWavAbsolutePath {
    return [[self class] getPathByFileName:recordFileName ofType:@"wav"];
}

+ (NSString *)getAmrAbsolutePath {
    return [[self class] getPathByFileName:recordFileName ofType:@"amr"];
}

+ (void)remove_Amr_Wav_Record {
    [[NSFileManager defaultManager] removeItemAtAbsolutePath:[[self class] getAmrAbsolutePath]];
    [[NSFileManager defaultManager] removeItemAtAbsolutePath:[[self class] getWavAbsolutePath]];
}

#pragma mark - getter

- (NSString *)wavPath {
    if (!_wavPath) {
        _wavPath = [[self class] getWavAbsolutePath];
    }
    return _wavPath;
}

- (NSString *)amrPath {
    if (!_amrPath) {
        _amrPath = [[self class] getAmrAbsolutePath];
    }
    return _amrPath;
}
@end
