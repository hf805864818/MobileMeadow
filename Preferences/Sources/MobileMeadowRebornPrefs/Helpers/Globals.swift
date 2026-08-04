import Foundation
import MobileMeadowRebornPrefsC

/// 偏好文件目录路径 — 使用 C 函数自动适配 rootless / Roothide / rootful
var plistPath: String {
    let fullpath = MMGetPreferencesPath()
    // 返回目录路径（去掉文件名）
    return (fullpath as NSString).deletingLastPathComponent + "/"
}

/// 动态解析 PreferenceBundle 的资源路径
/// 在 Roothide 等 jailbreak 中，/var/jb/ 可能不存在为符号链接，
/// 使用 Bundle(for:) 获取实际的 bundle 路径是最可靠的方式
var prefsAssetsPath: String {
    // 方案 1：尝试通过 Bundle API 获取（最可靠，适用于所有 jailbreak 类型）
    if let bundlePath = Bundle(for: MobileMeadowMainVC.self).resourcePath {
        return bundlePath + "/"
    }

    // 方案 2：通过 jbroot 构建路径
    if let jbroot = MMGetJbrootPath() {
        let path = "\(jbroot)/Library/PreferenceBundles/MobileMeadowRebornPrefs.bundle/"
        if FileManager.default.fileExists(atPath: path) {
            return path
        }
    }

    // 方案 3：rootless 标准路径
    let varJbPath = "/var/jb/Library/PreferenceBundles/MobileMeadowRebornPrefs.bundle/"
    if FileManager.default.fileExists(atPath: varJbPath) {
        return varJbPath
    }

    // 方案 4：rootful 路径
    let rootfulPath = "/Library/PreferenceBundles/MobileMeadowRebornPrefs.bundle/"
    if FileManager.default.fileExists(atPath: rootfulPath) {
        return rootfulPath
    }

    // 方案 5：最后回退
    return varJbPath
}
