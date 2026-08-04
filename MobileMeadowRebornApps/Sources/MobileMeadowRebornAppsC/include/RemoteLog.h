#ifndef RemoteLog_h
#define RemoteLog_h

#include <Foundation/Foundation.h>
#include <stdarg.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

void RLogv(NSString *fmt, va_list args);
void RLog(NSString *fmt, ...);

/// 获取当前越狱的 jbroot 路径
NSString * _Nullable MMGetJbrootPath(void);

/// 获取资源目录路径
NSString *MMGetAssetsPath(void);

/// 获取偏好文件路径
NSString *MMGetPreferencesPath(void);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END

#endif /* RemoteLog_h */
