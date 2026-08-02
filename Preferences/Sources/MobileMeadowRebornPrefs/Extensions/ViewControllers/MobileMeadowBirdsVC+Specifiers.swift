import Foundation

extension MobileMeadowBirdsVC {
    
    override var specifiers: NSMutableArray? {
        get {
            // iOS 17 兼容：使用 ObjC 异常安全包装器访问 _specifiers
            if let specifiers = safeGetSpecifiers() {
                return specifiers
            } else {
                // 使用 ObjC 异常安全包装器加载 specifiers
                let specifiers = safeLoadSpecifiers(fromPlistName: "MobileMeadowBirds")
                safeSetSpecifiers(specifiers)
                return specifiers
            }
        }
        set {
            super.specifiers = newValue
        }
    }
}
