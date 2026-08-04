#import "RemoteLog.h"
#import <dlfcn.h>
#import <unistd.h>

// ============================================================
// jbroot 路径检测 — 兼容 rootless / Roothide / rootful
// ============================================================

static NSString *mm_cachedJbroot = nil;
static dispatch_once_t mm_jbrootOnce;

static NSString *detectJbroot(void) {
    NSFileManager *fm = [NSFileManager defaultManager];

    // 方法 1: /var/jb 符号链接（标准 rootless: Dopamine, palera1n）
    if ([fm fileExistsAtPath:@"/var/jb/"]) {
        return @"/var/jb";
    }

    // 方法 2: 搜索 .jbroot-* 目录（Roothide / RELAXIN）
    NSString *bundleAppDir = @"/var/containers/Bundle/Application";
    NSArray *contents = [fm contentsOfDirectoryAtPath:bundleAppDir error:nil];
    if (contents) {
        for (NSString *item in contents) {
            if ([item hasPrefix:@".jbroot"]) {
                NSString *path = [bundleAppDir stringByAppendingPathComponent:item];
                if ([fm fileExistsAtPath:path]) {
                    return path;
                }
            }
        }
    }

    // 方法 3: 通过 dladdr 获取当前 dylib 路径，向上推导 jbroot
    Dl_info info;
    if (dladdr((void *)RLogv, &info) && info.dli_fname) {
        NSString *dylibPath = [NSString stringWithUTF8String:info.dli_fname];
        // dylibPath 类似:
        // /var/containers/Bundle/Application/.jbroot-XXXX/Library/MobileSubstrate/DynamicLibraries/MobileMeadowReborn.dylib
        // 需要找到 .jbroot 组件并截取到该位置
        NSArray *components = [dylibPath pathComponents];
        for (NSUInteger i = 0; i < components.count; i++) {
            if ([components[i] hasPrefix:@".jbroot"]) {
                NSArray *jbrootComponents = [components subarrayWithRange:NSMakeRange(0, i + 1)];
                return [jbrootComponents componentsJoinedByString:@"/"];
            }
        }
    }

    // 方法 4: 检查环境变量（某些越狱会设置）
    const char *jbrootEnv = getenv("JBROOT");
    if (jbrootEnv && jbrootEnv[0]) {
        return [NSString stringWithUTF8String:jbrootEnv];
    }

    // 未找到 jbroot — 可能是 rootful 越狱
    return nil;
}

NSString *MMGetJbrootPath(void) {
    dispatch_once(&mm_jbrootOnce, ^{
        mm_cachedJbroot = detectJbroot();
    });
    return mm_cachedJbroot;
}

// ============================================================
// 日志文件路径
// ============================================================

NSString *MMGetLogFilePath(void) {
    NSString *jbroot = MMGetJbrootPath();
    if (jbroot) {
        // rootless / Roothide: jbroot/var/mobile/Library/Logs/MobileMeadow.log
        NSString *path = [jbroot stringByAppendingPathComponent:@"var/mobile/Library/Logs/MobileMeadow.log"];
        // 确保目录存在
        NSString *dir = [path stringByDeletingLastPathComponent];
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        return path;
    }
    // rootful 回退
    return @"/var/mobile/Library/Logs/MobileMeadow.log";
}

// ============================================================
// 资源目录路径
// ============================================================

NSString *MMGetAssetsPath(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *relativePath = @"Library/Application Support/MobileMeadow/Assets";

    // 尝试 jbroot 路径
    NSString *jbroot = MMGetJbrootPath();
    if (jbroot) {
        NSString *path = [jbroot stringByAppendingPathComponent:relativePath];
        if ([fm fileExistsAtPath:path]) {
            return path;
        }
    }

    // 尝试标准 rootless 路径（/var/jb 前缀，即使符号链接不存在，Roothide 可能仍会重定向）
    NSString *varJbPath = [@"/var/jb" stringByAppendingPathComponent:relativePath];
    if ([fm fileExistsAtPath:varJbPath]) {
        return varJbPath;
    }

    // 尝试 rootful 路径
    NSString *rootfulPath = [@"/" stringByAppendingPathComponent:relativePath];
    if ([fm fileExistsAtPath:rootfulPath]) {
        return rootfulPath;
    }

    // 尝试 /var/mobile 路径
    NSString *varMobilePath = [@"/var/mobile" stringByAppendingPathComponent:relativePath];
    if ([fm fileExistsAtPath:varMobilePath]) {
        return varMobilePath;
    }

    // 最后回退到 jbroot 路径（即使不存在，也返回最可能的路径）
    if (jbroot) {
        return [jbroot stringByAppendingPathComponent:relativePath];
    }

    return varJbPath;
}

// ============================================================
// 偏好文件路径
// ============================================================

NSString *MMGetPreferencesPath(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *relativePath = @"var/mobile/Library/Preferences/com.pkgfiles.mobilemeadowrebornprefs.plist";

    // 尝试 jbroot 路径
    NSString *jbroot = MMGetJbrootPath();
    if (jbroot) {
        NSString *path = [jbroot stringByAppendingPathComponent:relativePath];
        if ([fm fileExistsAtPath:path]) {
            return path;
        }
    }

    // 尝试 /var/jb 前缀
    NSString *varJbPath = [@"/var/jb" stringByAppendingPathComponent:relativePath];
    if ([fm fileExistsAtPath:varJbPath]) {
        return varJbPath;
    }

    // 尝试 /var/mobile 路径（rootful 或 Roothide 重定向）
    NSString *varMobilePath = @"/var/mobile/Library/Preferences/com.pkgfiles.mobilemeadowrebornprefs.plist";
    if ([fm fileExistsAtPath:varMobilePath]) {
        return varMobilePath;
    }

    // 回退：如果 jbroot 存在，用 jbroot 路径（用于创建新文件）
    if (jbroot) {
        return [jbroot stringByAppendingPathComponent:relativePath];
    }

    // 最终回退
    return varMobilePath;
}

// ============================================================
// 日志输出 — NSLog + 文件写入
// ============================================================

static dispatch_queue_t mm_logQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        queue = dispatch_queue_create("com.pkgfiles.mobilemeadow.log", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

void RLogv(NSString *fmt, va_list args) {
    NSString *message = [[NSString alloc] initWithFormat:fmt arguments:args];
    NSString *logLine = [NSString stringWithFormat:@"[MobileMeadow] %@", message];

    // 输出到 syslog
    NSLog(@"%@", logLine);

    // 同时写入文件（异步串行队列，不阻塞主线程）
    NSString *filePath = MMGetLogFilePath();
    dispatch_async(mm_logQueue(), ^{
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        if (!handle) {
            [@"" writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        }
        if (handle) {
            [handle seekToEndOfFile];
            NSString *timestamp = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                              dateStyle:NSDateFormatterShortStyle
                                                                timeStyle:NSDateFormatterMediumStyle];
            NSString *line = [NSString stringWithFormat:@"[%@] %@\n", timestamp, logLine];
            [handle writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
            [handle closeFile];
        }
    });
}

void RLog(NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    RLogv(fmt, args);
    va_end(args);
}
