#ifndef RemoteLog_h
#define RemoteLog_h

#include <Foundation/Foundation.h>
#include <stdarg.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/// 远程日志输出（格式化 + va_list）
void RLogv(NSString *fmt, va_list args);

/// 远程日志输出（格式化）
void RLog(NSString *fmt, ...);

/// 获取当前越狱的 jbroot 路径
/// 兼容 rootless (/var/jb) 和 Roothide (/var/containers/Bundle/Application/.jbroot-XXXX)
/// 返回 nil 表示未找到 jbroot（可能是 rootful 越狱）
NSString * _Nullable MMGetJbrootPath(void);

/// 获取日志文件路径
/// 优先使用 jbroot 下的路径，回退到 /var/mobile/Library/Logs/
NSString *MMGetLogFilePath(void);

/// 获取资源目录路径（Library/Application Support/MobileMeadow/Assets）
/// 自动适配 rootless / Roothide / rootful
NSString *MMGetAssetsPath(void);

/// 获取偏好文件路径（Library/Preferences/com.pkgfiles.mobilemeadowrebornprefs.plist）
/// 自动适配 rootless / Roothide / rootful
NSString *MMGetPreferencesPath(void);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END

#endif /* RemoteLog_h */
