import Preferences
import MobileMeadowRebornPrefsC

extension PSListController {

    /// iOS 17 兼容：安全获取 tableView
    /// PSListController 在 iOS 17 中可能不再直接暴露 tableView 属性给 Swift
    func safeTableView() -> UITableView? {
        // 方案 1：尝试 KVC 访问 tableView 属性
        if let tv = self.value(forKey: "tableView") as? UITableView {
            return tv
        }
        // 方案 2：尝试 KVC 访问 _tableView 私有属性
        if let tv = self.value(forKey: "_tableView") as? UITableView {
            return tv
        }
        // 方案 3：尝试将 self.view 转为 UITableView
        if let tv = self.view as? UITableView {
            return tv
        }
        // 方案 4：遍历子视图查找 UITableView
        for subview in self.view.subviews {
            if let tv = subview as? UITableView {
                return tv
            }
        }
        return nil
    }

    /// iOS 17 兼容：安全设置 tableHeaderView
    func setTableHeaderView(_ headerView: UIView) {
        safeTableView()?.tableHeaderView = headerView
    }

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
