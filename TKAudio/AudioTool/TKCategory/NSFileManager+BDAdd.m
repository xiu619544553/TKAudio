//
//  NSFileManager+BDAdd.m
//  BDKit
//
//  Created by 韩秀辉 on 2016/11/11.
//  Copyright © 2016年 韩秀辉. All rights reserved.
//

#import "NSFileManager+BDAdd.h"

@implementation NSFileManager (BDAdd)

- (CGFloat)getCacheSizeAtAbsolutePath:(NSString*)path {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:path]) { return 0.f; }
    
    /**
     e.g.
     @{ @"KylinCache",
     @"KylinCache/kylin_md5.plist",
     @"KylinCache/kylin_gift.sqlite",
     @"RongCloud",
     @"RongCloud/Data.plist",
     @"RongCloud/Event.plist" }
     */
    NSArray *subpaths = [fileMgr subpathsAtPath:path];
    /**
     subpaths中的每一个对象都是fileName
     e.g.
     fileName = @"KylinCache",
     fileName = @"KylinCache/kylin_md5.plist",
     fileName = @"KylinCache/kylin_gift.sqlite",
     fileName = @"RongCloud",
     fileName = @"RongCloud/Data.plist",
     fileName = @"RongCloud/Event.plist"
     */
    NSString *fileName = nil;
    long long fileSize = 0;
    NSEnumerator *subFilesEnumerator = [subpaths objectEnumerator];
    while ((fileName = [subFilesEnumerator nextObject])) {
        /**
         /var/mobile/xx/Data/Application/FD8C1340-80D2-4610-A7BA-900460B7A7E1/Library/Caches/KylinCache
         /var/mobile/xx/Data/Application/FD8C1340-80D2-4610-A7BA-900460B7A7E1/Library/Caches/KylinCache/kylin_md5.plist
         /var/mobile/xx/Data/Application/FD8C1340-80D2-4610-A7BA-900460B7A7E1/Library/Caches/KylinCache/kylin_gift.sqlite
         /var/mobile/xx/Data/Application/FD8C1340-80D2-4610-A7BA-900460B7A7E1/Library/Caches/RongCloud
         /var/mobile/xx/Data/Application/FD8C1340-80D2-4610-A7BA-900460B7A7E1/Library/Caches/RongCloud/Data.plist
         /var/mobile/xx/Data/Application/FD8C1340-80D2-4610-A7BA-900460B7A7E1/Library/Caches/RongCloud/Event.plist
         */
        NSString *fileAbsolutePath = [path stringByAppendingPathComponent:fileName];
        fileSize += [self fileSizeAtAbsolutePath:fileAbsolutePath];
    }
    return fileSize/(1024.f*1024.f);
}

- (void)clearFileAtAbsolutePath:(NSString *)path
{
    NSFileManager *fileMgr=[NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:path]) { return; }
    
    NSArray *subpaths = [fileMgr subpathsAtPath:path];
    NSEnumerator *subFilesEnumerator = [subpaths objectEnumerator];
    NSString *fileName = nil;
    while ((fileName = [subFilesEnumerator nextObject])) {
        // 过滤不删除的文件
        NSString *absolutePath = [path stringByAppendingPathComponent:fileName];
        [fileMgr removeItemAtPath:absolutePath error:nil];
    }
}

- (void)removeItemAtAbsolutePath:(NSString *)path
{
    NSFileManager *fileMgr=[NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:path]) { return; }
    
    NSError *error = nil;
    BOOL result =  [fileMgr removeItemAtPath:path error:&error];
    if(result) {
        NSLog(@"清除成功");
    } else {
        NSLog(@"%@", error);
    }
}

- (CGFloat)diskOfSystemSize {
    CGFloat size = 0.0;
    NSError *error;
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) {
#ifdef DEBUG
        NSLog(@"error: %@", error.localizedDescription);
#endif
    } else {
        NSNumber *number = [dic objectForKey:NSFileSystemSize];
        size = [number floatValue]/1024.f/1024.f;
    }
    return size;
}

- (CGFloat)diskOfSystemFreeSize {
    CGFloat size = 0.0;
    NSError *error;
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) {
#ifdef DEBUG
        NSLog(@"error: %@", error.localizedDescription);
#endif
    } else {
        NSNumber *number = [dic objectForKey:NSFileSystemFreeSize];
        size = [number floatValue]/1024.f/1024.f;
    }
    return size;
}

+ (NSURL *)documentsURL {
    return [self URLForDirectory:NSDocumentDirectory];
}

+ (NSString *)documentsPath {
    return [self pathForDirectory:NSDocumentDirectory];
}

+ (NSURL *)libraryURL {
    return [self URLForDirectory:NSLibraryDirectory];
}

+ (NSString *)libraryPath {
    return [self pathForDirectory:NSLibraryDirectory];
}

+ (NSURL *)cachesURL {
    return [self URLForDirectory:NSCachesDirectory];
}

+ (NSString *)cachesPath {
    return [self pathForDirectory:NSCachesDirectory];
}

#pragma mark - Private Methods

- (long long)fileSizeAtAbsolutePath:(NSString*)filePath {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:filePath]) { return 0; }
    NSError *error;
    return [[fileMgr attributesOfItemAtPath:filePath error:&error] fileSize];
}

+ (NSURL *)URLForDirectory:(NSSearchPathDirectory)directory {
    return [[[self class] defaultManager] URLsForDirectory:directory inDomains:NSUserDomainMask].lastObject;
}

+ (NSString *)pathForDirectory:(NSSearchPathDirectory)directory {
    return NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES)[0];
}
@end
