#ifndef RemoteLog_h
#define RemoteLog_h

#include <Foundation/Foundation.h>
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

/// 远程日志输出（格式化 + va_list）
void RLogv(NSString *fmt, va_list args);

/// 远程日志输出（格式化）
void RLog(NSString *fmt, ...);

#ifdef __cplusplus
}
#endif

#endif /* RemoteLog_h */
