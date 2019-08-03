//
//  TKRecordManager.h
//  TKAudio
//
//  Created by hanxiuhui on 2019/8/3.
//  Copyright © 2019 TK. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *recordFileName = @"tank_audio";

@protocol TKRecordDelegate <NSObject>
@optional
- (void)realTimeUpdateVolume:(CGFloat)volume;
- (void)convertSuccessAmrData:(NSData *)amrData amrPath:(NSString *)amrPath;
- (void)convertFaild;
@end

@interface TKRecordManager : NSObject

@property (nonatomic, weak) id<TKRecordDelegate> delegate;

/// 开始录音
- (void)startRecorder;
/// 结束录音
- (void)stopRecorder;
/// 取消录音
- (void)cancelRecorder;

/// 获取wav录制文件绝对路径
+ (NSString *)getWavAbsolutePath;
/// 获取amr录制文件绝对路径
+ (NSString *)getAmrAbsolutePath;
/// 删除amr、wav文件
+ (void)remove_Amr_Wav_Record;
@end

NS_ASSUME_NONNULL_END
