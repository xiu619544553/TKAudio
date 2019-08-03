//
//  TKRecordItem.h
//  TKAudio
//
//  Created by hanxiuhui on 2019/8/3.
//  Copyright © 2019 TK. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKRecordItem : UIView
@property (nonatomic, copy) NSString *amrPath;
@property (nonatomic, copy) NSString *recordTime;
- (void)stopPlay;
@end

NS_ASSUME_NONNULL_END
