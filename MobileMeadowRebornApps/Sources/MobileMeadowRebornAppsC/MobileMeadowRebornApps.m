#import <Orion/Orion.h>
#import <signal.h>
#import <setjmp.h>
#import <pthread.h>
#import "MobileMeadowRebornApps.h"
#import "RemoteLog.h"

// ============================================================
// 致命错误捕获机制 — sigsetjmp/siglongjmp
// 同 MobileMeadowReborn.m 中的实现
// ============================================================

/// 线程局部 jmp_buf，支持多线程并发激活
static pthread_key_t s_jmpbuf_key;
static pthread_once_t s_jmpbuf_key_once = PTHREAD_ONCE_INIT;

static void MM_MakeJmpbufKey(void) {
    pthread_key_create(&s_jmpbuf_key, NULL);
}

static sigjmp_buf *MM_GetJmpbuf(void) {
    pthread_once(&s_jmpbuf_key_once, MM_MakeJmpbufKey);
    sigjmp_buf *buf = pthread_getspecific(s_jmpbuf_key);
    if (!buf) {
        buf = malloc(sizeof(sigjmp_buf));
        pthread_setspecific(s_jmpbuf_key, buf);
    }
    return buf;
}

static void MM_SignalHandler(int sig) {
    sigjmp_buf *buf = MM_GetJmpbuf();
    siglongjmp(*buf, sig);
}

/// 全局错误处理跳转函数（noreturn）
/// 被 Swift 层的 updateOrionErrorHandler 闭包调用
__attribute__((noreturn)) void MM_GlobalErrorHandler(const char *message, const char *file, int line) {
    RLog(@"🔥 Orion FATAL intercepted (Apps): %s (%s:%d)", message, file, line);
    sigjmp_buf *buf = MM_GetJmpbuf();
    siglongjmp(*buf, 1);
    abort();
}

/// 安全执行 block，同时捕获 NSException 和 fatalError(SIGTRAP)
BOOL MMSafeActivate(NSString * _Nullable context, void(^block)(void)) {
    struct sigaction old_trap, old_ill;
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = MM_SignalHandler;
    sa.sa_flags = SA_NODEFER;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGTRAP, &sa, &old_trap);
    sigaction(SIGILL, &sa, &old_ill);

    sigjmp_buf *buf = MM_GetJmpbuf();
    int jump_result = sigsetjmp(*buf, 1);

    if (jump_result == 0) {
        @try {
            block();
        } @catch (NSException *exception) {
            RLog(@"⚠️ HOOK ACTIVATION FAILED (NSException): %@ — %@",
                 context ?: @"unknown", exception.name);
            sigaction(SIGTRAP, &old_trap, NULL);
            sigaction(SIGILL, &old_ill, NULL);
            return NO;
        }
    } else {
        RLog(@"⚠️ HOOK ACTIVATION FAILED (signal %d, fatalError): %@",
             jump_result, context ?: @"unknown");
        sigaction(SIGTRAP, &old_trap, NULL);
        sigaction(SIGILL, &old_ill, NULL);
        return NO;
    }

    sigaction(SIGTRAP, &old_trap, NULL);
    sigaction(SIGILL, &old_ill, NULL);
    return YES;
}

/// 使用 objc_setAssociatedObject 设置关联对象
/// 替代 Orion @Property，避免 KVC setValue:forKey: 崩溃
void MMSetProperty(id object, NSString *key, id value) {
    objc_setAssociatedObject(object, (__bridge const void *)(key), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/// 获取关联对象
id _Nullable MMGetProperty(id object, NSString *key) {
    return objc_getAssociatedObject(object, (__bridge const void *)(key));
}

/// 未捕获异常处理器 — 记录异常信息
static void MMUncaughtExceptionHandler(NSException *exception) {
    RLog(@"💀 UNCAUGHT EXCEPTION (Apps): %@ — %@\nStack: %@",
         exception.name,
         exception.reason,
         exception.callStackSymbols);
}

// ============================================================
// KVC 全局安全防护 — NSObject 级别
// 同 MobileMeadowReborn.m 中的实现，直接在 NSObject 根类上替换
// setValue:forUndefinedKey: 和 valueForUndefinedKey:，
// 让所有对象的 KVC 遇到未知 key 时静默忽略而非崩溃。
// ============================================================

static void MMInstallGlobalKVCSafety(void) {
    SEL setSel = @selector(setValue:forUndefinedKey:);
    IMP setImp = imp_implementationWithBlock(^(id self, id value, NSString *key) {
        RLog(@"⚠️ KVC ignored (Apps): [%@ setValue:%@ forKey:%@]",
             NSStringFromClass([self class]), value, key);
    });
    class_replaceMethod([NSObject class], setSel, setImp, "v@:@@");

    SEL getSel = @selector(valueForUndefinedKey:);
    IMP getImp = imp_implementationWithBlock(^(id self, NSString *key) {
        RLog(@"⚠️ KVC ignored (Apps): [%@ valueForKey:%@] -> nil",
             NSStringFromClass([self class]), key);
        return nil;
    });
    class_replaceMethod([NSObject class], getSel, getImp, "@@:@");

    RLog(@"Global KVC safety installed on NSObject (Apps)");
}

__attribute__((constructor)) static void init() {
    NSSetUncaughtExceptionHandler(MMUncaughtExceptionHandler);

    // 安装全局 KVC 安全防护
    MMInstallGlobalKVCSafety();

    RLog(@"MobileMeadowRebornApps dylib constructor — orion_init() about to be called");
    // Initialize Orion - do not remove this line.
    orion_init();
    RLog(@"MobileMeadowRebornApps dylib constructor — orion_init() complete");
}
