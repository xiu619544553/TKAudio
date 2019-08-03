//
//  ViewController.m
//  TKAudio
//
//  Created by hanxiuhui on 2019/8/3.
//  Copyright © 2019 TK. All rights reserved.
//

#import "ViewController.h"
#import "AudioVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"录制语音";
    self.view.backgroundColor = UIColor.whiteColor;
    
    UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    recordButton.frame = CGRectMake(100, 100, 100, 100);
    [recordButton setTitle:@"点我" forState:UIControlStateNormal];
    recordButton.backgroundColor = UIColor.redColor;
    [recordButton addTarget:self
                     action:@selector(recordButtonAction)
           forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:recordButton];
}

#pragma mark - Event Methods

- (void)recordButtonAction {
    [self.navigationController pushViewController:[AudioVC new] animated:YES];
}
@end
