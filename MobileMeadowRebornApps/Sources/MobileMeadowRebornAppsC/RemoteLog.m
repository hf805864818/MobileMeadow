#import "RemoteLog.h"
#import <dlfcn.h>
#import <unistd.h>
#import <time.h>

// ============================================================
// jbroot 路径检测
// ============================================================

static NSString *mm_cachedJbroot = nil;
static dispatch_once_t mm_jbrootOnce;

static NSString *detectJbroot(void) {
    NSFileManager *fm = [NSFileManager defaultManager];

    if ([fm fileExistsAtPath:@"/var/jb/"]) {
        return @"/var/jb";
    }

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

    Dl_info info;
    if (dladdr((void *)RLogv, &info) && info.dli_fname) {
        NSString *dylibPath = [NSString stringWithUTF8String:info.dli_fname];
        NSArray *components = [dylibPath pathComponents];
        for (NSUInteger i = 0; i < components.count; i++) {
            if ([components[i] hasPrefix:@".jbroot"]) {
                NSArray *jbrootComponents = [components subarrayWithRange:NSMakeRange(0, i + 1)];
                return [jbrootComponents componentsJoinedByString:@"/"];
            }
        }
    }

    const char *jbrootEnv = getenv("JBROOT");
    if (jbrootEnv && jbrootEnv[0]) {
        return [NSString stringWithUTF8String:jbrootEnv];
    }

    return nil;
}

NSString *MMGetJbrootPath(void) {
    dispatch_once(&mm_jbrootOnce, ^{
        mm_cachedJbroot = detectJbroot();
    });
    return mm_cachedJbroot;
}

NSString *MMGetAssetsPath(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *relativePath = @"Library/Application Support/MobileMeadow/Assets";

    NSString *jbroot = MMGetJbrootPath();
    if (jbroot) {
        NSString *path = [jbroot stringByAppendingPathComponent:relativePath];
        if ([fm fileExistsAtPath:path]) return path;
    }

    NSString *varJbPath = [@"/var/jb" stringByAppendingPathComponent:relativePath];
    if ([fm fileExistsAtPath:varJbPath]) return varJbPath;

    NSString *rootfulPath = [@"/" stringByAppendingPathComponent:relativePath];
    if ([fm fileExistsAtPath:rootfulPath]) return rootfulPath;

    NSString *varMobilePath = [@"/var/mobile" stringByAppendingPathComponent:relativePath];
    if ([fm fileExistsAtPath:varMobilePath]) return varMobilePath;

    if (jbroot) return [jbroot stringByAppendingPathComponent:relativePath];
    return varJbPath;
}

NSString *MMGetPreferencesPath(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *relativePath = @"var/mobile/Library/Preferences/com.pkgfiles.mobilemeadowrebornprefs.plist";

    NSString *jbroot = MMGetJbrootPath();
    if (jbroot) {
        NSString *path = [jbroot stringByAppendingPathComponent:relativePath];
        if ([fm fileExistsAtPath:path]) return path;
    }

    NSString *varJbPath = [@"/var/jb" stringByAppendingPathComponent:relativePath];
    if ([fm fileExistsAtPath:varJbPath]) return varJbPath;

    NSString *varMobilePath = @"/var/mobile/Library/Preferences/com.pkgfiles.mobilemeadowrebornprefs.plist";
    if ([fm fileExistsAtPath:varMobilePath]) return varMobilePath;

    if (jbroot) return [jbroot stringByAppendingPathComponent:relativePath];
    return varMobilePath;
}

// ============================================================
// 日志输出
// ============================================================

static dispatch_queue_t mm_logQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        queue = dispatch_queue_create("com.pkgfiles.mobilemeadowapps.log", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

static NSString *getLogFilePath(void) {
    NSString *jbroot = MMGetJbrootPath();
    if (jbroot) {
        NSString *path = [jbroot stringByAppendingPathComponent:@"var/mobile/Library/Logs/MobileMeadow.log"];
        NSString *dir = [path stringByDeletingLastPathComponent];
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        return path;
    }
    return @"/var/mobile/Library/Logs/MobileMeadow.log";
}

void RLogv(NSString *fmt, va_list args) {
    NSString *message = [[NSString alloc] initWithFormat:fmt arguments:args];
    NSString *logLine = [NSString stringWithFormat:@"[MobileMeadowApps] %@", message];
    NSLog(@"%@", logLine);

    NSString *filePath = getLogFilePath();
    dispatch_async(mm_logQueue(), ^{
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        if (!handle) {
            [@"" writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        }
        if (handle) {
            [handle seekToEndOfFile];
            // 使用 strftime 替代 NSDateFormatter，避免 ICU 库崩溃
            time_t t = (time_t)[[NSDate date] timeIntervalSince1970];
            struct tm *tm_info = localtime(&t);
            char timeBuf[64];
            strftime(timeBuf, sizeof(timeBuf), "%Y-%m-%d %H:%M:%S", tm_info);
            NSString *timestamp = [NSString stringWithUTF8String:timeBuf];
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
