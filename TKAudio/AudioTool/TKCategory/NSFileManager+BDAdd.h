//
//  NSFileManager+BDAdd.h
//  BDKit
//
//  Created by 韩秀辉 on 2016/11/11.
//  Copyright © 2016年 韩秀辉. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSFileManager (BDAdd)

/**
 清除文件夹指定绝对路径的缓存
 e.g. /var/mobile/Containers/Data/Application/7296AA5A-9819-4F67-8782-77732FB2BAE4/Documents
 */
- (void)clearFileAtAbsolutePath:(NSString *)path;

/** 
 清楚指定路径的item
 e.g. /var/mobile/Containers/Data/Application/B30B0FF0-5BB0-4D5E-9469-70A63FDCE0C2/Documents/20161206103258.amr
 */
- (void)removeItemAtAbsolutePath:(NSString *)path;

/**
 计算指定绝对路径的缓存大小 单位:M
 e.g. /var/mobile/Containers/Data/Application/7296AA5A-9819-4F67-8782-77732FB2BAE4/Documents
 */
- (CGFloat)getCacheSizeAtAbsolutePath:(NSString*)path;

/**
 获取磁盘总空间 单位:M
 */
- (CGFloat)diskOfSystemSize;

/** 
 获取磁盘可用空间 单位:M
 */
- (CGFloat)diskOfSystemFreeSize;


/**
 获取 Documents directory URL.
 e.g. file:///var/mobile/Containers/Data/Application/7296AA5A-9819-4F67-8782-77732FB2BAE4/Documents/
 */
+ (NSURL *)documentsURL;

/**
 获取 Documents directory 绝对路径.
 e.g. /var/mobile/Containers/Data/Application/7296AA5A-9819-4F67-8782-77732FB2BAE4/Documents
 */
+ (NSString *)documentsPath;

/**
 获取 Library directory URL.
 e.g. file:///var/mobile/Containers/Data/Application/7296AA5A-9819-4F67-8782-77732FB2BAE4/Library/
 */
+ (NSURL *)libraryURL;

/**
 获取 Library directory 绝对路径.
 e.g. /var/mobile/Containers/Data/Application/7296AA5A-9819-4F67-8782-77732FB2BAE4/Library
 */
+ (NSString *)libraryPath;

/**
 获取 Caches directory URL.
 e.g. file:///var/mobile/Containers/Data/Application/7296AA5A-9819-4F67-8782-77732FB2BAE4/Library/Caches/
 */
+ (NSURL *)cachesURL;

/**
 获取 Caches directory 绝对路径.
 e.g. /var/mobile/Containers/Data/Application/7296AA5A-9819-4F67-8782-77732FB2BAE4/Library/Caches
 */
+ (NSString *)cachesPath;

@end
