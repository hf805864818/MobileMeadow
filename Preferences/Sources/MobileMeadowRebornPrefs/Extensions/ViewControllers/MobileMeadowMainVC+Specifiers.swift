import Foundation

extension MobileMeadowMainVC {
    
    override var specifiers: NSMutableArray? {
        get {
            // iOS 17 兼容：使用 ObjC 异常安全包装器访问 _specifiers
            if let specifiers = safeGetSpecifiers() {
                return specifiers
            } else {
                // 使用 ObjC 异常安全包装器加载 specifiers
                // loadSpecifiers 在 iOS 17 上可能抛出 ObjC 异常，Swift 无法捕获
                let specifiers = safeLoadSpecifiers(fromPlistName: "Root")
                safeSetSpecifiers(specifiers)
                return specifiers
            }
        }
        set {
            super.specifiers = newValue
        }
    }
}
