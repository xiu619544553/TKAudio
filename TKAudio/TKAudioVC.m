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

typedef NS_ENUM(NSInteger, StockRecordStatus) {
    StockRecordUnknow,        // 未知
    StockRecord_Touched,      // 在有效区域
    StockRecord_TouchedBeyond // 手指已超出有效区域，但是仍在录音
};

@interface TKAudioVC () <TKRecordDelegate> {
    BOOL              _isRecord; // 是否在录音
    CGFloat           _recordTime;
    StockRecordStatus _style;
}
@property (nonatomic, strong) NSData *amrData;///< arm二进制
@property (nonatomic, strong) TKRecordManager *record;
@property (nonatomic, strong) NSTimer *recordTimer;///< 记录录制时间计时器

@property (nonatomic, strong) TKRecordItem *recordItem;

@property (nonatomic, strong) UIView *bottomViewTopGrayViewTopLine;
@property (nonatomic, strong) UIView *bottomViewTopGrayView;
@property (nonatomic, strong) UIView *bottomViewTopLine;
@property (nonatomic, strong) UIView *bottomView;

// 录制语音状态显示的视图
@property (nonatomic, strong) UILabel *recordTitleLabel;///< 录制语音观点
@property (nonatomic, strong) UIView *titleBottomLine;
@property (nonatomic, strong) UILabel *recordLabel;///< 按住开始录音标签
@property (nonatomic, strong) UIButton *recordImgBtn;
@property (nonatomic, strong) UIView *recordProgressLine;

// 语音录制完成显示的视图
@property (nonatomic, strong) UIButton *re_recordingBtn;///< 重新录制按钮
@end

@implementation TKAudioVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"录制语音";
    self.view.backgroundColor = UIColor.whiteColor;
    
    [self setupUI];
}

#pragma mark - Touch Methods

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event
{    
    CGPoint point = [[touches anyObject] locationInView:self.view];
    if (!CGRectContainsPoint(self.bottomView.frame, point)) {
        return;
    }
    
    if (self.recordImgBtn.isHidden) { return; }
    
    if (!_isRecord) {
        CGFloat touchIncrement = 20.f;
        CGRect recordFrame = CGRectMake(self.recordImgBtn.x - touchIncrement, self.bottomView.y + self.recordTitleLabel.height - touchIncrement, self.recordImgBtn.width + touchIncrement * 2, self.recordImgBtn.height + touchIncrement * 2);
        
        if (CGRectContainsPoint(recordFrame, point)) {
            
            _recordTime = 0.f;
            _isRecord = YES;
            self.recordItem.hidden = NO;
            
            _style = StockRecord_Touched;
            [self updateLabelTitle];
            
            [self addRecordTimer];
            self.recordLabel.text = @"松开按钮完成录制";
            
            // 开始录制音频
            self.record = [[TKRecordManager alloc] init];
            self.record.delegate = self;
            [self.record startRecorder];
            
            self.view.userInteractionEnabled = NO;
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!_isRecord) { return; }
    
    CGPoint point = [[touches anyObject] locationInView:self.view];
    CGFloat invalidMinY = CGRectGetMinY(self.bottomView.frame) + self.recordTitleLabel.height;
    if (point.y < invalidMinY) {
        _style = StockRecord_TouchedBeyond;
    } else {
        _style = StockRecord_Touched;
    }
    [self updateLabelTitle];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event
{
    if (!_isRecord) { return; }
    
    self.view.userInteractionEnabled = YES;
    
    if (_style == StockRecord_Touched) {
        // 至少录制1s，才算是录制有效
        if (_recordTime >= 1.f) {
            // 结束录制
            [self.record stopRecorder];
        } else {
            // 取消录制
            [self.record cancelRecorder];
            [self.recordItem removeFromSuperview];
            self.recordItem = nil;
        }
    } else if (_style == StockRecord_TouchedBeyond) {
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
- (void)recordTimerAction
{
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

- (void)resetAudioView
{
    _isRecord = NO;
    _style = StockRecordUnknow;
    self.recordProgressLine.width = 0.f;
    [self updateLabelTitle];
    [self.recordTimer invalidate];
    self.recordTimer = nil;
    self.view.userInteractionEnabled = YES;
}

- (void)addRecordTimer
{
    if (self.recordTimer) {
        [self.recordTimer invalidate];
        self.recordTimer = nil;
    }
    self.recordTimer = [NSTimer scheduledTimerWithTimeInterval:recordAccuracy target:self selector:@selector(recordTimerAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.recordTimer forMode:NSRunLoopCommonModes];
}

- (void)updateLabelTitle
{
    CGFloat remainingTime = maxRecordTime - _recordTime;
    if (_style == StockRecord_Touched) {
        
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
        
    } else if (_style == StockRecord_TouchedBeyond) {
        
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

- (void)recoverRecordImgBtnFrame
{
    self.recordImgBtn.layer.borderWidth = 1.f;
    CGFloat recordBtnW = 90.f;
    self.recordImgBtn.frame = (CGRect){{(self.view.width - recordBtnW)/2.f, CGRectGetMaxY(self.titleBottomLine.frame) + 37.f}, {recordBtnW, recordBtnW}};
    self.recordImgBtn.layer.cornerRadius = CGRectGetWidth(self.recordImgBtn.bounds)/2.f;
}

#pragma mark - StockRecorderDelegate Methods

- (void)convertSuccessAmrData:(NSData *)amrData amrPath:(NSString *)amrPath
{
    _amrData = amrData;
    
    // 录制结束
    self.re_recordingBtn.hidden = NO;
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

- (void)realTimeUpdateVolume:(CGFloat)volume
{
    [self drawCircleWithVolume:volume];
}

- (void)drawCircleWithVolume:(CGFloat)volume
{
    if (_style == StockRecord_Touched) {
        
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

- (void)re_recordingBtnClick:(UIButton *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"是否重新录制？" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *knowAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *configAction = [UIAlertAction actionWithTitle:@"重新录制" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        // 删除amr、wav文件
        [TKRecordManager remove_Amr_Wav_Record];
        
        // 视图
        self.re_recordingBtn.hidden = YES;
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

- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [UIView new];
        _bottomView.backgroundColor = [UIColor whiteColor];
    }
    return _bottomView;
}

- (UIView *)bottomViewTopGrayViewTopLine {
    if (!_bottomViewTopGrayViewTopLine) {
        _bottomViewTopGrayViewTopLine = [UIView new];
        _bottomViewTopGrayViewTopLine.backgroundColor = TKSeparatorColor;
    }
    return _bottomViewTopGrayViewTopLine;
}

- (UIView *)bottomViewTopLine {
    if (!_bottomViewTopLine) {
        _bottomViewTopLine = [UIView new];
        _bottomViewTopLine.backgroundColor = TKSeparatorColor;
    }
    return _bottomViewTopLine;
}

- (UIView *)bottomViewTopGrayView {
    if (!_bottomViewTopGrayView) {
        _bottomViewTopGrayView = [UIView new];
        _bottomViewTopGrayView.backgroundColor = UIColor.groupTableViewBackgroundColor;
    }
    return _bottomViewTopGrayView;
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

- (UIButton *)re_recordingBtn
{
    if (!_re_recordingBtn) {
        _re_recordingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _re_recordingBtn.hidden = YES;
        _re_recordingBtn.adjustsImageWhenHighlighted = NO;
        _re_recordingBtn.bounds = (CGRect){{0.f, 0.f}, {90.f, 90.f}};
        [_re_recordingBtn setImage:[UIImage imageNamed:@"icon_delete_audio"]
                          forState:UIControlStateNormal];
        _re_recordingBtn.contentMode = UIViewContentModeScaleAspectFit;
        _re_recordingBtn.layer.cornerRadius = CGRectGetWidth(_re_recordingBtn.bounds)/2.f;
        _re_recordingBtn.layer.masksToBounds = YES;
        _re_recordingBtn.layer.borderColor = TKSeparatorColor.CGColor;
        _re_recordingBtn.layer.borderWidth = 1.f;
        [_re_recordingBtn addTarget:self
                             action:@selector(re_recordingBtnClick:)
                   forControlEvents:UIControlEventTouchUpInside];
    }
    return _re_recordingBtn;
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
        _recordItem = [[TKRecordItem alloc] initWithFrame:CGRectMake(0.f, 100.f, self.view.frame.size.width, 40.f)];
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

- (void)setupUI
{
    [self.view addSubview:self.bottomView];
    
    // 录制语音状态显示的视图
    [self.bottomView addSubview:self.recordImgBtn];
    [self.bottomView addSubview:self.recordTitleLabel];
    [self.bottomView addSubview:self.titleBottomLine];
    [self.bottomView addSubview:self.recordLabel];
    [self.bottomView addSubview:self.recordProgressLine];
    
    // 重新录制
    [self.bottomView addSubview:self.re_recordingBtn];
    
    [self.view addSubview:self.bottomViewTopLine];
    [self.view addSubview:self.bottomViewTopGrayView];
    [self.view addSubview:self.bottomViewTopGrayViewTopLine];
    
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(240);
    }];
    [self.bottomViewTopLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(kSINGLE_LINE);
        make.bottom.equalTo(self.bottomView.mas_top);
    }];
    [self.bottomViewTopGrayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(10.f);
        make.bottom.equalTo(self.bottomViewTopLine.mas_top);
    }];
    [self.bottomViewTopGrayViewTopLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.bottomViewTopGrayView.mas_top);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(kSINGLE_LINE);
    }];
    
    // 录制语音状态显示的视图
    [self.recordTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.bottomView);
        make.height.mas_equalTo(44.f);
    }];
    [self.titleBottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.recordTitleLabel.mas_bottom);
        make.left.right.equalTo(self.bottomView);
        make.height.mas_equalTo(kSINGLE_LINE);
    }];
    [self.recordProgressLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleBottomLine.mas_bottom);
        make.left.equalTo(self.bottomView);
        make.size.mas_equalTo(CGSizeMake(0.f, 2.f));
    }];
    [self.recordImgBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.bottomView.mas_centerX);
        make.top.equalTo(self.titleBottomLine.mas_bottom).offset(37.f);
        make.size.mas_equalTo(self.recordImgBtn.frame.size);
    }];
    [self.recordLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.bottomView);
        make.bottom.equalTo(self.bottomView).offset(-37.f);
    }];
    
    // 重新录制
    [self.re_recordingBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.bottomView.mas_centerX);
        make.top.equalTo(self.titleBottomLine.mas_bottom).offset(37.f);
        make.size.mas_equalTo(self.recordImgBtn.frame.size);
    }];
}
@end
