import Foundation

extension MobileMeadowMainVC {
    
    override var specifiers: NSMutableArray? {
        get {
            // iOS 17 兼容：使用 ObjC 异常安全包装器访问 _specifiers
            if let specifiers = safeGetSpecifiers() {
                return specifiers
            } else {
                let specifiers = loadSpecifiers(fromPlistName: "Root", target: self)
                safeSetSpecifiers(specifiers)
                return specifiers
            }
        }
        set {
            super.specifiers = newValue
        }
    }
}
