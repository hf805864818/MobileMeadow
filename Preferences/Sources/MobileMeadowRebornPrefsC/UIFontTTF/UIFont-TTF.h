#import <UIKit/UIKit.h>

@interface UIFont (TTF)

/// 从指定路径加载 TTF 字体并返回指定大小的 UIFont
+ (UIFont *)ttfFontOfSize:(CGFloat)size ttfPath:(NSString *)path;

@end
