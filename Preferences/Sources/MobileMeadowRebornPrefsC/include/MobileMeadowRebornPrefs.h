#import <UIKit/UIKit.h>
#import <spawn.h>
#import "RemoteLog.h"
#import "UIFontTTF/UIFont-TTF.h"

// Thanks to @Nightwind for his respring method (changed from "sbreload" to "killall SpringBoard")
void respring(void);

/// iOS 17 兼容：ObjC 异常安全的 KVC 读取
/// 使用 @try/@catch 包装 valueForKey:，防止 valueForUndefinedKey: 崩溃
/// Swift 无法捕获 ObjC 异常，因此必须在 ObjC 层处理
id MMSafeValueForKey(id obj, NSString *key);

/// iOS 17 兼容：ObjC 异常安全的 KVC 写入
/// 使用 @try/@catch 包装 setValue:forKey:，防止异常崩溃
void MMSafeSetValueForKey(id obj, id value, NSString *key);
