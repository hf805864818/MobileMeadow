#ifndef RemoteLog_h
#define RemoteLog_h

#include <Foundation/Foundation.h>
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

void RLogv(NSString *fmt, va_list args);
void RLog(NSString *fmt, ...);

#ifdef __cplusplus
}
#endif

#endif /* RemoteLog_h */
