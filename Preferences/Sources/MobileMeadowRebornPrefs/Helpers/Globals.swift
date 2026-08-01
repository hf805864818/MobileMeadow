import Foundation

let plistPath: String = FileManager.default.fileExists(atPath: "/var/jb/")
                        ? "/var/jb/var/mobile/Library/Preferences/"
                        : "/var/mobile/Library/Preferences/"

/// 动态解析 PreferenceBundle 的资源路径
/// 在 Roothide 等 jailbreak 中，/var/jb/ 可能不存在为符号链接，
/// 使用 Bundle(for:) 获取实际的 bundle 路径是最可靠的方式
var prefsAssetsPath: String {
    // 方案 1：尝试通过 Bundle API 获取（最可靠，适用于所有 jailbreak 类型）
    if let bundlePath = Bundle(for: MobileMeadowMainVC.self).resourcePath {
        return bundlePath + "/"
    }

    // 方案 2：rootless 标准路径
    var path: String = "/var/jb/Library/PreferenceBundles/MobileMeadowRebornPrefs.bundle/"
    if FileManager.default.fileExists(atPath: path) {
        return path
    }

    // 方案 3：rootful 路径
    path = "/Library/PreferenceBundles/MobileMeadowRebornPrefs.bundle/"
    if FileManager.default.fileExists(atPath: path) {
        return path
    }

    // 方案 4：最后回退到 rootless 路径（即使不存在，也作为默认值）
    return "/var/jb/Library/PreferenceBundles/MobileMeadowRebornPrefs.bundle/"
}
