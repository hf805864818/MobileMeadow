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
// KVC 安全防护
// Orion 生成的 glue 代码会通过 KVC (setValue:forKey:) 设置属性到系统类上，
// 系统类没有这些属性就会抛出 NSUnknownKeyException 导致安全模式。
// 解决方案：在 Orion 初始化之前，给所有 Hook 目标类添加
// setValue:forUndefinedKey: 和 valueForUndefinedKey: 覆盖，
// 让 KVC 遇到未知 key 时静默忽略而非崩溃。
// ============================================================

static void MMInstallKVCSafeHandler(Class cls) {
    if (!cls) return;

    // 覆盖 setValue:forUndefinedKey: — 静默忽略
    SEL setSel = @selector(setValue:forUndefinedKey:);
    IMP setImp = imp_implementationWithBlock(^(id self, id value, NSString *key) {
        RLog(@"⚠️ KVC ignored: [%@ setValue:%@ forKey:%@]",
             NSStringFromClass([self class]), value, key);
    });
    if (!class_addMethod(cls, setSel, setImp, "v@:@@")) {
        class_replaceMethod(cls, setSel, setImp, "v@:@@");
    }

    // 覆盖 valueForUndefinedKey: — 返回 nil 而非崩溃
    SEL getSel = @selector(valueForUndefinedKey:);
    IMP getImp = imp_implementationWithBlock(^(id self, NSString *key) {
        RLog(@"⚠️ KVC ignored: [%@ valueForKey:%@] -> nil", NSStringFromClass([self class]), key);
        return nil;
    });
    if (!class_addMethod(cls, getSel, getImp, "@@:@")) {
        class_replaceMethod(cls, getSel, getImp, "@@:@");
    }
}

/// 给所有 Hook 目标类安装 KVC 安全处理器
static void MMInstallAllKVCSafeHandlers(void) {
    // SpringBoard 相关
    MMInstallKVCSafeHandler(objc_getClass("SpringBoard"));
    MMInstallKVCSafeHandler(objc_getClass("SBDockIconListView"));
    MMInstallKVCSafeHandler(objc_getClass("SBDockView"));
    MMInstallKVCSafeHandler(objc_getClass("MTMaterialView"));
    MMInstallKVCSafeHandler(objc_getClass("SBIconListPageControl"));
    MMInstallKVCSafeHandler(objc_getClass("SBRootFolderController"));
    MMInstallKVCSafeHandler(objc_getClass("SBFolderController"));
    MMInstallKVCSafeHandler(objc_getClass("SBNestingViewController"));
    MMInstallKVCSafeHandler(objc_getClass("NCNotificationViewController"));
    MMInstallKVCSafeHandler(objc_getClass("NCNotificationShortLookViewController"));

    RLog(@"KVC safe handlers installed on all target classes");
}

__attribute__((constructor)) static void init() {
    // 注册未捕获异常处理器，作为最后防线
    NSSetUncaughtExceptionHandler(MMUncaughtExceptionHandler);

    // 在 Orion 初始化之前安装 KVC 安全处理器
    // 这样 Orion 生成的 glue 代码调用 setValue:forKey: 时，
    // 如果目标类没有对应属性，会静默忽略而非崩溃
    MMInstallAllKVCSafeHandlers();

    RLog(@"MobileMeadowReborn dylib constructor — orion_init() about to be called");
    // Initialize Orion - do not remove this line.
    orion_init();
    RLog(@"MobileMeadowReborn dylib constructor — orion_init() complete");
}
