#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "SpringBoard.h"
#import "RemoteLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIView(Private)
- (__kindof UIViewController * _Nullable)_viewControllerForAncestor;
@end

@interface UIImage (Private)
+ (id)_applicationIconImageForBundleIdentifier:(id)identifier format:(int)format scale:(double)scale;
@end

@interface SBDockIconListView : UIView
- (void)createMeadowDockGround;
@end

@interface SBNestingViewController : UIViewController
@end

@interface SBFolderController : SBNestingViewController
@end

@interface SBRootFolderController : SBFolderController
@end

@interface NCNotificationViewController : UIViewController
@end

@interface NCNotificationShortLookViewController : NCNotificationViewController
@end

// ============================================================
// Swift 可调用的 ObjC 异常安全函数
// ============================================================

/// 安全执行 block，捕获 NSException
/// Swift 无法直接捕获 NSException，必须通过此 ObjC 函数
BOOL MMSafeActivate(NSString * _Nullable context, void (^_Nonnull block)(void));

/// 使用 objc_setAssociatedObject 设置关联对象（替代 Orion @Property）
void MMSetProperty(id object, NSString *key, id _Nullable value);

/// 获取关联对象
id _Nullable MMGetProperty(id object, NSString *key);

NS_ASSUME_NONNULL_END
