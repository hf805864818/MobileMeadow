#import "UIFont-TTF.h"
#import <CoreText/CoreText.h>

@implementation UIFont (TTF)

+ (UIFont *)ttfFontOfSize:(CGFloat)size ttfPath:(NSString *)path {
    if (!path || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
    }

    NSURL *fontURL = [NSURL fileURLWithPath:path];
    CGDataProviderRef dataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef)fontURL);
    if (!dataProvider) {
        return [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
    }

    CGFontRef cgFont = CGFontCreateWithDataProvider(dataProvider);
    CGDataProviderRelease(dataProvider);
    if (!cgFont) {
        return [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
    }

    CFErrorRef error = NULL;
    CTFontManagerRegisterGraphicsFont(cgFont, &error);

    NSString *psName = (__bridge_transfer NSString *)CGFontCopyPostScriptName(cgFont);
    CGFontRelease(cgFont);

    if (error) {
        CFRelease(error);
        return [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
    }

    UIFont *font = [UIFont fontWithName:psName size:size];
    return font ?: [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
}

@end
