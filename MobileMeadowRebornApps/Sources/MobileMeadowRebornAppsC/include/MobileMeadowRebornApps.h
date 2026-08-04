#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "RemoteLog.h"

@interface UIView(Private)
- (__kindof UIViewController *)_viewControllerForAncestor;
@end

@interface _UIBarBackground : UIView
- (void)createMeadowGround;
@end

// ============================================================
// Swift 可调用的 ObjC 异常安全函数
// ============================================================

/// 安全执行 block，捕获 NSException
/// Swift 无法直接捕获 NSException，必须通过此 ObjC 函数
BOOL MMSafeActivate(NSString * _Nullable context, void(^block)(void));

/// 使用 objc_setAssociatedObject 设置关联对象（替代 Orion @Property）
void MMSetProperty(id object, NSString *key, id _Nullable value);

/// 获取关联对象
id _Nullable MMGetProperty(id object, NSString *key);
