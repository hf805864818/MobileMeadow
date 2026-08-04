#import <Orion/Orion.h>
#import "MobileMeadowRebornApps.h"
#import "RemoteLog.h"

// ============================================================
// Swift 可调用的 ObjC 异常捕获函数
// ============================================================

/// 安全执行 block，捕获 NSException
BOOL MMSafeActivate(NSString * _Nullable context, void(^block)(void)) {
    @try {
        block();
        return YES;
    } @catch (NSException *exception) {
        RLog(@"⚠️ HOOK ACTIVATION FAILED: %@ — %@ — %@",
             context ?: @"unknown",
             exception.name,
             exception.reason);
        return NO;
    } @catch (id other) {
        RLog(@"⚠️ HOOK ACTIVATION FAILED (unknown exception): %@",
             context ?: @"unknown");
        return NO;
    }
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
