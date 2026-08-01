import Preferences
import MobileMeadowRebornPrefsC

extension PSListController {

    open override func readPreferenceValue(_ specifier: PSSpecifier!) -> Any! {
        guard let defaultPath = specifier.properties["defaults"] as? String else {
            return super.readPreferenceValue(specifier)
        }

        let path = "\(plistPath)\(defaultPath).plist"
        let settings = NSDictionary(contentsOfFile: path)

        return settings?[specifier.property(forKey: "key") as Any] ?? specifier.property(forKey: "default")
    }

    open override func setPreferenceValue(_ value: Any!, specifier: PSSpecifier!) {
        // 安全检查：确保 specifier 有 defaults 和 key 属性
        guard let defaults = specifier.properties["defaults"] as? String,
              let key = specifier.property(forKey: "key") as? String else {
            return
        }

        let path = "\(plistPath)\(defaults).plist"
        let prefs = NSMutableDictionary(contentsOfFile: path) ?? NSMutableDictionary()

        prefs.setValue(value, forKey: key)
        prefs.write(toFile: path, atomically: true)
    }
}
