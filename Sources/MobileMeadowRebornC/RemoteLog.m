#import "RemoteLog.h"

void RLogv(NSString *fmt, va_list args) {
    NSString *message = [[NSString alloc] initWithFormat:fmt arguments:args];
    NSLog(@"[MobileMeadow] %@", message);
}

void RLog(NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    RLogv(fmt, args);
    va_end(args);
}
