//
//  TKMacro.h
//  TKAudio
//
//  Created by hanxiuhui on 2019/8/3.
//  Copyright © 2019 TK. All rights reserved.
//

#ifndef TKMacro_h
#define TKMacro_h

#define UIColorFromRGB(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
/// 颜色
#define TKSeparatorColor UIColorFromRGB(235,235,235)
#define TKThemeColor     UIColorFromRGB(255,63,3)
#define TKWordColor      UIColorFromRGB(158,158,158)

/// 绘制1像素线
#define kSINGLE_LINE    (1.f / [UIScreen mainScreen].scale)

#endif /* TKMacro_h */
