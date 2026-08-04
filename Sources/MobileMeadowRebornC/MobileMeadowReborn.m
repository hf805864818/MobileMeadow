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

__attribute__((constructor)) static void init() {
    RLog("MobileMeadowReborn dylib constructor — orion_init() about to be called");
    // Initialize Orion - do not remove this line.
    orion_init();
    RLog("MobileMeadowReborn dylib constructor — orion_init() complete");
}
