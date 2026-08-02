#import "MobileMeadowRebornPrefs.h"
#import <objc/message.h>

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

/// iOS 17 兼容：ObjC 异常安全的 tableHeaderView 设置
/// 严格检查对象类型，确保只在 UITableView 上调用 setTableHeaderView:
BOOL MMSafeSetTableHeader(id tableView, UIView *headerView) {
    // 严格类型检查：确保对象确实是 UITableView 或其子类
    if (!tableView || ![tableView isKindOfClass:[UITableView class]]) {
        NSLog(@"[MobileMeadow] MMSafeSetTableHeader: object is not a UITableView (type: %@)", NSStringFromClass([tableView class]));
        return NO;
    }

    // 检查对象是否响应 setTableHeaderView: 选择器
    if (![tableView respondsToSelector:@selector(setTableHeaderView:)]) {
        NSLog(@"[MobileMeadow] MMSafeSetTableHeader: UITableView does not respond to setTableHeaderView:");
        return NO;
    }

    @try {
        UITableView *tv = (UITableView *)tableView;
        tv.tableHeaderView = headerView;
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"[MobileMeadow] MMSafeSetTableHeader: caught exception: %@", exception.reason);
        return NO;
    }
}

/// iOS 17 兼容：ObjC 异常安全的 loadSpecifiers 调用
/// 通过 objc_msgSend 调用 PSListController 的 loadSpecifiersFromPlistName:target:
/// 用 @try/@catch 包装，防止 plist 加载失败或 cell 类实例化失败时崩溃
NSMutableArray *MMSafeLoadSpecifiers(id controller, NSString *plistName) {
    if (!controller || !plistName) {
        NSLog(@"[MobileMeadow] MMSafeLoadSpecifiers: invalid arguments");
        return nil;
    }

    SEL selector = NSSelectorFromString(@"loadSpecifiersFromPlistName:target:");
    if (![controller respondsToSelector:selector]) {
        NSLog(@"[MobileMeadow] MMSafeLoadSpecifiers: controller does not respond to loadSpecifiersFromPlistName:target:");
        return nil;
    }

    @try {
        // 使用 objc_msgSend 调用 loadSpecifiersFromPlistName:target:
        // 方法签名: - (NSMutableArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target
        NSMutableArray *(*msgSend)(id, SEL, NSString *, id) = (void *)objc_msgSend;
        NSMutableArray *result = msgSend(controller, selector, plistName, controller);
        return result;
    } @catch (NSException *exception) {
        NSLog(@"[MobileMeadow] MMSafeLoadSpecifiers: caught exception for plist '%@': %@", plistName, exception.reason);
        return nil;
    }
}

/// iOS 17 兼容：ObjC 异常安全的 PSSpecifier property 读取
/// PSSpecifier 的 propertyForKey: 在 iOS 17 上可能抛出异常
/// 此函数用 @try/@catch 包装，返回属性值或 nil
id MMSafeSpecifierProperty(id specifier, NSString *key) {
    if (!specifier || !key) {
        return nil;
    }

    SEL selector = NSSelectorFromString(@"propertyForKey:");
    if (![specifier respondsToSelector:selector]) {
        NSLog(@"[MobileMeadow] MMSafeSpecifierProperty: specifier does not respond to propertyForKey:");
        return nil;
    }

    @try {
        id (*msgSend)(id, SEL, NSString *) = (void *)objc_msgSend;
        return msgSend(specifier, selector, key);
    } @catch (NSException *exception) {
        NSLog(@"[MobileMeadow] MMSafeSpecifierProperty: caught exception for key '%@': %@", key, exception.reason);
        return nil;
    }
}
