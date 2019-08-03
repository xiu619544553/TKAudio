//
//  TKRootViewController.m
//  TKAudio
//
//  Created by hanxiuhui on 2019/8/3.
//  Copyright © 2019 TK. All rights reserved.
//

#import "TKRootViewController.h"
#import "TKAudioVC.h"

#import <Masonry.h>
#import <AVFoundation/AVFoundation.h>

@interface TKRootViewController () <UIAlertViewDelegate>

@end

@implementation TKRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGFloat buttonWH = 200.f;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.layer.cornerRadius = buttonWH/2.f;
    button.layer.masksToBounds = YES;
    button.backgroundColor = UIColor.orangeColor;
    [button setTitle:@"点我" forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(buttonAction)
     forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(buttonWH, buttonWH));
    }];
}

- (void)buttonAction {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) { // 有使用麦克风的权限
                [self.navigationController pushViewController:[TKAudioVC new] animated:YES];
            } else { // 没有麦克风权限
                UIAlertView *alertView =
                [[UIAlertView alloc] initWithTitle:@"未获得使用麦克风授权"
                                           message:@"请在“设置”-“隐私”-“麦克风”中打开"
                                          delegate:self
                                 cancelButtonTitle:@"设置"
                                 otherButtonTitles:@"知道了", nil];
                [alertView show];
            }
        });
    }];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // 打开设置
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if([[UIApplication sharedApplication] canOpenURL:url]) {
        NSURL *url =[NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
        
    } else {
        
    }
}
@end
