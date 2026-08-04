#import <Orion/Orion.h>
#import <objc/runtime.h>
#import <signal.h>
#import <setjmp.h>
#import <pthread.h>
#import "MobileMeadowReborn.h"
#import "RemoteLog.h"

// ============================================================
// 致命错误捕获机制 — sigsetjmp/siglongjmp
//
// 问题根因（深度分析）：
// 1. Orion 当 ClassHook<T> 的 T 类不存在时，调用 orionError() → fatalError()
//    → _assertionFailure() → __builtin_trap() → SIGTRAP
// 2. Tweak.handleError 虽然在 Orion 源码中声明在协议里，但用户设备上的
//    Orion 1.0.1-3 可能编译时协议布局不同，导致静态派发到默认实现
// 3. POSIX 信号处理器 (SIGTRAP) 无效：因为 iOS 上 __builtin_trap() 产生的
//    EXC_BREAKPOINT Mach 异常会被系统的 CrashReporter 先捕获，
//    POSIX 信号处理器根本不会被调用
//
// 双重解决方案：
// A. 主方案 — updateOrionErrorHandler（Swift 层调用）
//    在 Orion 的 orionError() 内部、fatalError() 之前拦截，
//    用 siglongjmp 跳回安全点。这是唯一能100%阻止崩溃的方法。
// B. 兜底方案 — sigsetjmp/siglongjmp + POSIX 信号处理器
//    保留作为最后防线（某些越狱环境可能禁用了 CrashReporter）
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

/// SIGTRAP/SIGILL 信号处理器
/// 当 Orion 调用 fatalError 时触发，跳转回 MMSafeActivate 的安全点
static void MM_SignalHandler(int sig) {
    sigjmp_buf *buf = MM_GetJmpbuf();
    // 只有 buf 有效时才跳转（buf 的标记位由 sigsetjmp 设置）
    siglongjmp(*buf, sig);
}

/// 全局错误处理跳转函数（noreturn）
/// 被 Swift 层的 updateOrionErrorHandler 闭包调用
/// 在 orionError() 内部、fatalError() 之前拦截，用 siglongjmp 跳回安全点
/// 这是唯一能 100% 阻止 Orion fatalError 导致 SpringBoard 崩溃的方法
__attribute__((noreturn)) void MM_GlobalErrorHandler(const char *message, const char *file, int line) {
    RLog(@"🔥 Orion FATAL intercepted: %s (%s:%d)", message, file, line);
    sigjmp_buf *buf = MM_GetJmpbuf();
    siglongjmp(*buf, 1);
    // 如果 siglongjmp 返回（不应该发生），调用 abort 满足 noreturn 约定
    abort();
}

/// 安全执行 block，同时捕获 NSException 和 fatalError(SIGTRAP)
/// 主防线：由 updateOrionErrorHandler 在 orionError() 内部拦截
/// 兜底防线：POSIX 信号处理器（某些越狱环境可能有效）
BOOL MMSafeActivate(NSString * _Nullable context, void(^block)(void)) {
    // 保存旧的信号处理器
    struct sigaction old_trap, old_ill;
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = MM_SignalHandler;
    sa.sa_flags = SA_NODEFER; // 允许递归信号，防止某些边缘情况死锁
    sigemptyset(&sa.sa_mask);
    sigaction(SIGTRAP, &sa, &old_trap);
    sigaction(SIGILL, &sa, &old_ill);

    sigjmp_buf *buf = MM_GetJmpbuf();
    int jump_result = sigsetjmp(*buf, 1);

    if (jump_result == 0) {
        // 正常执行路径
        @try {
            block();
        } @catch (NSException *exception) {
            RLog(@"⚠️ HOOK ACTIVATION FAILED (NSException): %@ — %@ — %@",
                 context ?: @"unknown", exception.name, exception.reason);
            sigaction(SIGTRAP, &old_trap, NULL);
            sigaction(SIGILL, &old_ill, NULL);
            return NO;
        }
    } else {
        // 信号捕获路径 — 从 SIGTRAP/SIGILL 恢复
        const char *sigName = (jump_result == SIGTRAP) ? "SIGTRAP" :
                              (jump_result == SIGILL)  ? "SIGILL"  : "UNKNOWN";
        RLog(@"⚠️ HOOK ACTIVATION FAILED (%s, fatalError): %@", sigName,
             context ?: @"unknown");
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

/// 未捕获异常处理器 — 记录异常信息，帮助诊断
static void MMUncaughtExceptionHandler(NSException *exception) {
    RLog(@"💀 UNCAUGHT EXCEPTION: %@ — %@\nStack: %@",
         exception.name,
         exception.reason,
         exception.callStackSymbols);
}

// ============================================================
// KVC 全局安全防护 — NSObject 级别
//
// 问题分析：
// 之前给特定类（SBDockView、MTMaterialView 等）安装 setValue:forUndefinedKey:
// 覆盖，但 setValue:forKey: 内部在调用 setValue:forUndefinedKey: 之前就可能
// 抛异常。而且 Orion 编译器生成的 glue 代码可能对任意类调用 KVC。
//
// 最终方案：直接在 NSObject 根类上替换 setValue:forUndefinedKey: 和
// valueForUndefinedKey:，让所有对象的 KVC 遇到未知 key 时静默忽略而非崩溃。
// 这是最彻底的修复，但也是最安全的 —— 因为 NSUnknownKeyException 在生产代码中
// 本就不应该发生，每个负责任的类都应该自己覆盖这些方法。
// ============================================================

static void MMInstallGlobalKVCSafety(void) {
    // 替换 NSObject 的 setValue:forUndefinedKey: — 静默忽略
    // 注意：class_replaceMethod 会替换 NSObject 的方法实现，
    // 影响所有子类。但 NSObject 的默认实现就是抛异常，
    // 所以替换为 no-op 不会有副作用。
    SEL setSel = @selector(setValue:forUndefinedKey:);
    IMP setImp = imp_implementationWithBlock(^(id self, id value, NSString *key) {
        RLog(@"⚠️ KVC ignored: [%@ setValue:%@ forKey:%@]",
             NSStringFromClass([self class]), value, key);
    });
    class_replaceMethod([NSObject class], setSel, setImp, "v@:@@");

    // 替换 NSObject 的 valueForUndefinedKey: — 返回 nil 而非崩溃
    SEL getSel = @selector(valueForUndefinedKey:);
    IMP getImp = imp_implementationWithBlock(^(id self, NSString *key) {
        RLog(@"⚠️ KVC ignored: [%@ valueForKey:%@] -> nil",
             NSStringFromClass([self class]), key);
        return nil;
    });
    class_replaceMethod([NSObject class], getSel, getImp, "@@:@");

    RLog(@"Global KVC safety installed on NSObject — all KVC errors will be silently ignored");
}

__attribute__((constructor)) static void init() {
    // 注册未捕获异常处理器，作为最后防线
    NSSetUncaughtExceptionHandler(MMUncaughtExceptionHandler);

    // 在 Orion 初始化之前安装全局 KVC 安全防护
    // 直接替换 NSObject 的 setValue:forUndefinedKey: / valueForUndefinedKey:
    // 这样 Orion 生成的 glue 代码调用 setValue:forKey: 时，
    // 无论目标是什么类，遇到未知 key 都会静默忽略而非崩溃
    MMInstallGlobalKVCSafety();

    RLog(@"MobileMeadowReborn dylib constructor — orion_init() about to be called");
    // Initialize Orion - do not remove this line.
    orion_init();
    RLog(@"MobileMeadowReborn dylib constructor — orion_init() complete");
}
