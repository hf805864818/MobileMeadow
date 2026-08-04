#import <Orion/Orion.h>
#import <objc/runtime.h>
#import "MobileMeadowReborn.h"
#import "RemoteLog.h"

// ============================================================
// Swift 可调用的 ObjC 异常捕获函数
// 用于安全地激活 Orion Hook 组
// ============================================================

/// 安全执行 block，捕获 NSException
/// Swift 无法直接捕获 NSException，必须通过此 ObjC 函数
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
