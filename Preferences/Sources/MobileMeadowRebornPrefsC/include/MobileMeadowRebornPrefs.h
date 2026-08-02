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

/// iOS 17 兼容：ObjC 异常安全的 tableHeaderView 设置
/// 检查对象是否为 UITableView 且响应 setTableHeaderView:，然后用 @try/@catch 包裹
/// 返回 YES 表示设置成功，NO 表示失败
BOOL MMSafeSetTableHeader(id tableView, UIView *headerView);
