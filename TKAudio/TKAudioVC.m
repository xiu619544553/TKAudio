//
//  AudioVC.m
//  TKAudio
//
//  Created by hanxiuhui on 2019/8/3.
//  Copyright © 2019 TK. All rights reserved.
//

#import "TKAudioVC.h"

#import "TKMacro.h"
#import <Masonry.h>
#import "UIView+TKAdd.h"

#import "TKRecordItem.h"
#import "TKRecordManager.h"

// 录制最大时长、精确度
static CGFloat maxRecordTime = 90.f;
static CGFloat recordAccuracy = 0.01f;

/// 录制过程中，手指触摸点的区域状态
typedef NS_ENUM(NSInteger, TKRecordingTouchStatus) {
    /// 位置
    TKRecordingUnknow,
    /// 手指在录制区域内
    TKRecording_TouchInRecordingArea,
    /// 手指超出有效区域，但是仍在录音
    TKRecording_TouchOutRecordingArea
};

@interface TKAudioVC () <TKRecordDelegate> {
    BOOL              _isRecord; // 是否在录音
    CGFloat           _recordTime;
    TKRecordingTouchStatus _style;
}

@property (nonatomic, strong) NSData *amrData;
@property (nonatomic, strong) TKRecordManager *record;
/// 记录录制时间计时器
@property (nonatomic, strong) NSTimer *recordTimer;

@property (nonatomic, strong) TKRecordItem *recordItem;
@property (nonatomic, strong) UIView *recordContainerView;
@property (nonatomic, strong) UIView *recordContainerViewTopGrayView;
@property (nonatomic, strong) UILabel *recordTitleLabel;
@property (nonatomic, strong) UIView *titleBottomLine;
@property (nonatomic, strong) UILabel *recordLabel;
@property (nonatomic, strong) UIButton *recordImgBtn;
@property (nonatomic, strong) UIView *recordProgressLine;
@property (nonatomic, strong) UIButton *reRecordingBtn;
@end

@implementation TKAudioVC

#pragma mark - LifeCycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"录制语音";
    self.view.backgroundColor = UIColor.whiteColor;
    [self setupUI];
}

#pragma mark - Touch Methods

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self.view];
    if (!CGRectContainsPoint(self.recordContainerView.frame, point)) {
        return;
    }
    
    if (self.recordImgBtn.isHidden) { return; }
    
    if (!_isRecord) {
        CGFloat touchIncrement = 20.f;
        CGRect recordFrame = CGRectMake(self.recordImgBtn.x - touchIncrement, self.recordContainerView.y + self.recordTitleLabel.height - touchIncrement, self.recordImgBtn.width + touchIncrement * 2, self.recordImgBtn.height + touchIncrement * 2);
        
        if (CGRectContainsPoint(recordFrame, point)) {
            
            // 重置录制数据
            _recordTime = 0.f;
            _isRecord = YES;
            _style = TKRecording_TouchInRecordingArea;
            
            self.recordItem.hidden = NO;
            
            [self updateLabelTitle];
            [self addRecordTimer];
            
            // 开始录制音频
            self.record = [[TKRecordManager alloc] init];
            self.record.delegate = self;
            [self.record startRecorder];
            
            self.view.userInteractionEnabled = NO;
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!_isRecord) { return; }
    
    CGPoint point = [[touches anyObject] locationInView:self.view];
    CGFloat invalidMinY = CGRectGetMinY(self.recordContainerView.frame) + self.recordTitleLabel.height;
    if (point.y < invalidMinY) {
        _style = TKRecording_TouchOutRecordingArea;
    } else {
        _style = TKRecording_TouchInRecordingArea;
    }
    [self updateLabelTitle];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    if (!_isRecord) { return; }
    
    self.view.userInteractionEnabled = YES;
    
    if (_style == TKRecording_TouchInRecordingArea) {
        // 至少录制1s，才算是录制有效
        if (_recordTime >= 1.f) { // 结束录制
            [self.record stopRecorder];
        } else { // 取消录制
            [self.record cancelRecorder];
            [self.recordItem removeFromSuperview];
            self.recordItem = nil;
        }
    } else if (_style == TKRecording_TouchOutRecordingArea) {
        // 取消录制
        [self.record cancelRecorder];
        
        [self.recordItem removeFromSuperview];
        self.recordItem = nil;
        
        _amrData = nil;
    }
    
    [self resetAudioView];
    [self updateLabelTitle];
}

// 记录录音时长 0.01
- (void)recordTimerAction {
    if (!_isRecord) {
        [self resetAudioView];
    }
    
    _recordTime += recordAccuracy;
    [self updateLabelTitle];
    self.recordProgressLine.width = _recordTime/maxRecordTime * self.view.width;
    
    if (maxRecordTime - _recordTime <= recordAccuracy) {
        // 最多录制90s，结束录制
        [self resetAudioView];
        // 结束录制
        [self.record stopRecorder];
    }
}

// 重置视图状态
- (void)resetAudioView {
    _isRecord = NO;
    _style = TKRecordingUnknow;
    self.recordProgressLine.width = 0.f;
    [self updateLabelTitle];
    [self.recordTimer invalidate];
    self.recordTimer = nil;
    self.view.userInteractionEnabled = YES;
}

// 添加录制时长计时器
- (void)addRecordTimer {
    if (self.recordTimer) {
        [self.recordTimer invalidate];
        self.recordTimer = nil;
    }
    self.recordTimer = [NSTimer scheduledTimerWithTimeInterval:recordAccuracy target:self selector:@selector(recordTimerAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.recordTimer forMode:NSRunLoopCommonModes];
}

// 更新标签状态
- (void)updateLabelTitle {
    CGFloat remainingTime = maxRecordTime - _recordTime;
    if (_style == TKRecording_TouchInRecordingArea) {
        
        NSMutableAttributedString *titleLabelAttStr = nil;
        if (remainingTime <= 10.f) {// 10s倒计时
            titleLabelAttStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.f", remainingTime] attributes:@{NSForegroundColorAttributeName : TKThemeColor, NSFontAttributeName : [UIFont systemFontOfSize:15.f]}];
        } else {
            NSString *baseStr = @"上滑取消";
            NSString *secStr = [NSString stringWithFormat:@"（%.f''）", floor(_recordTime)];
            NSString *titleStr = [NSString stringWithFormat:@"%@%@", baseStr, secStr];
            titleLabelAttStr = [[NSMutableAttributedString alloc] initWithString:titleStr];
            [titleLabelAttStr addAttributes:@{NSForegroundColorAttributeName : TKWordColor, NSFontAttributeName : [UIFont systemFontOfSize:13.f]}
                                      range:[baseStr rangeOfString:baseStr]];
            [titleLabelAttStr addAttributes:@{NSForegroundColorAttributeName : TKThemeColor, NSFontAttributeName : [UIFont systemFontOfSize:13.f]}
                                      range:[titleStr rangeOfString:secStr]];
        }
        [self.recordTitleLabel setAttributedText:titleLabelAttStr];
        
        self.recordLabel.hidden = NO;
        self.recordLabel.text = @"松开按钮完成录制";
        
        self.recordImgBtn.layer.borderWidth = 0.f;
        [self.recordImgBtn setImage:nil forState:UIControlStateNormal];
        self.recordImgBtn.backgroundColor = UIColorFromRGB(242,242,242);
        
    } else if (_style == TKRecording_TouchOutRecordingArea) {
        
        NSMutableAttributedString *titleLabelAttStr = nil;
        if (remainingTime <= 10.f) {// 10s倒计时
            titleLabelAttStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.f", remainingTime] attributes:@{NSForegroundColorAttributeName : TKThemeColor, NSFontAttributeName : [UIFont systemFontOfSize:15.f]}];
        } else {
            NSString *baseStr = @"松开取消";
            NSString *secStr = [NSString stringWithFormat:@"（%.f''）", floor(_recordTime)];
            NSString *titleStr = [NSString stringWithFormat:@"%@%@", baseStr, secStr];
            titleLabelAttStr = [[NSMutableAttributedString alloc] initWithString:titleStr];
            [titleLabelAttStr addAttributes:@{NSForegroundColorAttributeName : TKThemeColor,
                                              NSFontAttributeName : [UIFont systemFontOfSize:13.f]}
                                      range:[baseStr rangeOfString:baseStr]];
            [titleLabelAttStr addAttributes:@{NSForegroundColorAttributeName : TKThemeColor,
                                              NSFontAttributeName : [UIFont systemFontOfSize:13.f]}
                                      range:[titleStr rangeOfString:secStr]];
        }
        [self.recordTitleLabel setAttributedText:titleLabelAttStr];
        
        self.recordLabel.hidden = YES;
        
        [self recoverRecordImgBtnFrame];
        self.recordImgBtn.backgroundColor = TKThemeColor;
        [self.recordImgBtn setImage:[UIImage imageNamed:@"icon_move_delete"] forState:UIControlStateNormal];
    } else {
        NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:@"录制语音观点" attributes:@{NSForegroundColorAttributeName : TKWordColor, NSFontAttributeName : [UIFont systemFontOfSize:13.f]}];
        [self.recordTitleLabel setAttributedText:attr];
        
        self.recordLabel.hidden = NO;
        self.recordLabel.text = @"按住开始录音";
        
        [self recoverRecordImgBtnFrame];
        self.recordImgBtn.backgroundColor = [UIColor clearColor];
        [self.recordImgBtn setImage:[UIImage imageNamed:@"icon_record_audio"] forState:UIControlStateNormal];
    }
}

- (void)recoverRecordImgBtnFrame {
    self.recordImgBtn.layer.borderWidth = 1.f;
    CGFloat recordBtnW = 90.f;
    self.recordImgBtn.frame = (CGRect){{(self.view.width - recordBtnW)/2.f, CGRectGetMaxY(self.titleBottomLine.frame) + 37.f}, {recordBtnW, recordBtnW}};
    self.recordImgBtn.layer.cornerRadius = CGRectGetWidth(self.recordImgBtn.bounds)/2.f;
}

#pragma mark - TKRecordingerDelegate Methods

- (void)convertSuccessAmrData:(NSData *)amrData amrPath:(NSString *)amrPath {
    _amrData = amrData;
    
    // 录制结束
    self.reRecordingBtn.hidden = NO;
    self.recordImgBtn.hidden = YES;
    self.recordTitleLabel.hidden = YES;
    self.titleBottomLine.hidden = YES;
    self.recordLabel.text = @"重新录制";
    self.recordLabel.textColor = TKThemeColor;
    
    // 展示说股内容
    self.recordItem.amrPath = amrPath;
    [self.recordItem setRecordTime:[NSString stringWithFormat:@"%.f″", _recordTime]];
}

- (void)convertFaild {}

- (void)realTimeUpdateVolume:(CGFloat)volume {
    [self drawCircleWithVolume:volume];
}

- (void)drawCircleWithVolume:(CGFloat)volume {
    if (_style == TKRecording_TouchInRecordingArea) {
        
        CGPoint center = self.recordImgBtn.center;
        CGFloat recordImgBtnW = 90.f;
        
        CGFloat changeW = recordImgBtnW + volume * 666.f;
        CGSize size = CGSizeMake(changeW, changeW);
        CGRect rect = (CGRect){{center.x - size.width/2.f, center.y - size.width/2.f}, size};
        self.recordImgBtn.frame = rect;
        
        self.recordImgBtn.size = size;
        self.recordImgBtn.layer.cornerRadius = CGRectGetWidth(self.recordImgBtn.bounds)/2.f;
    }
}

#pragma mark - Event Methods

- (void)reRecordingBtnClick:(UIButton *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"是否重新录制？" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *knowAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *configAction = [UIAlertAction actionWithTitle:@"重新录制" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        // 删除amr、wav文件
        [TKRecordManager remove_Amr_Wav_Record];
        
        // 视图
        self.reRecordingBtn.hidden = YES;
        self.recordImgBtn.hidden = NO;
        self.recordTitleLabel.hidden = NO;
        self.titleBottomLine.hidden = NO;
        self.recordLabel.text = @"按钮开始录音";
        self.recordLabel.textColor = TKWordColor;
        
        [self.recordItem removeFromSuperview];
        self.recordItem = nil;
        
        self.amrData = nil;
    }];
    [alertController addAction:knowAction];
    [alertController addAction:configAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - getter

- (UIView *)recordContainerView {
    if (!_recordContainerView) {
        _recordContainerView = [UIView new];
        _recordContainerView.backgroundColor = [UIColor whiteColor];
    }
    return _recordContainerView;
}

- (UIView *)recordContainerViewTopGrayView {
    if (!_recordContainerViewTopGrayView) {
        _recordContainerViewTopGrayView = [UIView new];
        _recordContainerViewTopGrayView.backgroundColor = UIColor.groupTableViewBackgroundColor;
    }
    return _recordContainerViewTopGrayView;
}

- (UILabel *)recordTitleLabel {
    if (!_recordTitleLabel) {
        _recordTitleLabel = [[UILabel alloc] init];
        _recordTitleLabel.backgroundColor = [UIColor whiteColor];
        NSDictionary *att = @{NSForegroundColorAttributeName : TKWordColor,
                              NSFontAttributeName : [UIFont systemFontOfSize:13.f]};
        NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:@"长按录制语音" attributes:att];
        [_recordTitleLabel setAttributedText:attr];
        _recordTitleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _recordTitleLabel;
}

- (UIView *)titleBottomLine {
    if (!_titleBottomLine) {
        _titleBottomLine = [self private_createLine];
    }
    return _titleBottomLine;
}

- (UILabel *)recordLabel {
    if (!_recordLabel) {
        _recordLabel = [[UILabel alloc] init];
        _recordLabel.text = @"按住开始录音";
        _recordLabel.backgroundColor = [UIColor clearColor];
        _recordLabel.textColor = TKWordColor;
        _recordLabel.textAlignment = NSTextAlignmentCenter;
        _recordLabel.font = [UIFont systemFontOfSize:13.f];
    }
    return _recordLabel;
}

- (UIButton *)recordImgBtn {
    if (!_recordImgBtn) {
        _recordImgBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _recordImgBtn.bounds = (CGRect){{0.f, 0.f}, {90.f, 90.f}};
        _recordImgBtn.userInteractionEnabled = NO;
        [_recordImgBtn setImage:[UIImage imageNamed:@"icon_record_audio"]
                       forState:UIControlStateNormal];
        _recordImgBtn.contentMode = UIViewContentModeScaleAspectFit;
        _recordImgBtn.layer.cornerRadius = CGRectGetWidth(_recordImgBtn.bounds)/2.f;
        _recordImgBtn.layer.masksToBounds = YES;
        _recordImgBtn.layer.borderColor = TKSeparatorColor.CGColor;
        _recordImgBtn.layer.borderWidth = 1.f;
    }
    return _recordImgBtn;
}

- (UIButton *)reRecordingBtn {
    if (!_reRecordingBtn) {
        _reRecordingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _reRecordingBtn.hidden = YES;
        _reRecordingBtn.adjustsImageWhenHighlighted = NO;
        _reRecordingBtn.bounds = (CGRect){{0.f, 0.f}, {90.f, 90.f}};
        [_reRecordingBtn setImage:[UIImage imageNamed:@"icon_delete_audio"]
                          forState:UIControlStateNormal];
        _reRecordingBtn.contentMode = UIViewContentModeScaleAspectFit;
        _reRecordingBtn.layer.cornerRadius = CGRectGetWidth(_reRecordingBtn.bounds)/2.f;
        _reRecordingBtn.layer.masksToBounds = YES;
        _reRecordingBtn.layer.borderColor = TKSeparatorColor.CGColor;
        _reRecordingBtn.layer.borderWidth = 1.f;
        [_reRecordingBtn addTarget:self
                             action:@selector(reRecordingBtnClick:)
                   forControlEvents:UIControlEventTouchUpInside];
    }
    return _reRecordingBtn;
}

- (UIView *)recordProgressLine {
    if (!_recordProgressLine) {
        _recordProgressLine = [[UIView alloc] init];
        _recordProgressLine.backgroundColor = TKThemeColor;
    }
    return _recordProgressLine;
}

- (TKRecordItem *)recordItem {
    if (!_recordItem) {
        _recordItem = [[TKRecordItem alloc] initWithFrame:CGRectMake(0.f, 200, self.view.frame.size.width, 40.f)];
        _recordItem.hidden = YES;
        [self.view addSubview:_recordItem];
    }
    return _recordItem;
}

#pragma mark - Private Methods

- (UIView *)private_createLine {
    UIView *lineView = [[UIView alloc] init];
    lineView.backgroundColor = TKSeparatorColor;
    return lineView;
}

- (void)setupUI {
    [self.view addSubview:self.recordContainerViewTopGrayView];
    [self.view addSubview:self.recordContainerView];
    
    [self.recordContainerView addSubview:self.recordImgBtn];
    [self.recordContainerView addSubview:self.recordTitleLabel];
    [self.recordContainerView addSubview:self.titleBottomLine];
    [self.recordContainerView addSubview:self.recordLabel];
    [self.recordContainerView addSubview:self.recordProgressLine];
    [self.recordContainerView addSubview:self.reRecordingBtn];
    
    
    [self.recordContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(240);
    }];
    [self.recordContainerViewTopGrayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(10.f);
        make.bottom.equalTo(self.recordContainerView.mas_top);
    }];
    [self.recordTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.recordContainerView);
        make.height.mas_equalTo(44.f);
    }];
    [self.titleBottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.recordTitleLabel.mas_bottom);
        make.left.right.equalTo(self.recordContainerView);
        make.height.mas_equalTo(kSINGLE_LINE);
    }];
    [self.recordProgressLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleBottomLine.mas_bottom);
        make.left.equalTo(self.recordContainerView);
        make.size.mas_equalTo(CGSizeMake(0.f, 2.f));
    }];
    [self.recordImgBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.recordContainerView.mas_centerX);
        make.top.equalTo(self.titleBottomLine.mas_bottom).offset(37.f);
        make.size.mas_equalTo(self.recordImgBtn.frame.size);
    }];
    [self.recordLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.recordContainerView);
        make.bottom.equalTo(self.recordContainerView).offset(-37.f);
    }];
    
    // 重新录制
    [self.reRecordingBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.recordContainerView.mas_centerX);
        make.top.equalTo(self.titleBottomLine.mas_bottom).offset(37.f);
        make.size.mas_equalTo(self.recordImgBtn.frame.size);
    }];
}
@end
