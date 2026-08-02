#import "MobileMeadowRebornPrefs.h"

// Thanks to @Nightwind for his respring method (changed from "sbreload" to "killall SpringBoard")
void respring(void) {
    extern char **environ;
    const char *args[] = {"killall", "SpringBoard", NULL};
    pid_t pid;

    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:@"/var/Liy/.procursus_strapped"] || [fileManager fileExistsAtPath:@"/var/jb/.procursus_strapped"]) {
        posix_spawn(&pid, "/var/jb/usr/bin/killall", NULL, NULL, (char *const *)args, environ);
        return;
    }

    posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char *const *)args, environ);
}

/// iOS 17 兼容：ObjC 异常安全的 KVC 读取
/// Swift 无法捕获 ObjC NSException，必须在 ObjC 层用 @try/@catch 包装
id MMSafeValueForKey(id obj, NSString *key) {
    @try {
        return [obj valueForKey:key];
    } @catch (NSException *exception) {
        NSLog(@"[MobileMeadow] MMSafeValueForKey: caught exception for key '%@': %@", key, exception.reason);
        return nil;
    }
}

/// iOS 17 兼容：ObjC 异常安全的 KVC 写入
void MMSafeSetValueForKey(id obj, id value, NSString *key) {
    @try {
        [obj setValue:value forKey:key];
    } @catch (NSException *exception) {
        NSLog(@"[MobileMeadow] MMSafeSetValueForKey: caught exception for key '%@': %@", key, exception.reason);
    }
}
