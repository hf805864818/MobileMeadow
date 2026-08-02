import Preferences
import MobileMeadowRebornPrefsC

extension PSListController {

    /// iOS 17 兼容：安全获取 tableView
    /// 完全不使用 KVC（valueForKey），因为 iOS 17 的 PSListController
    /// 不识别 "tableView" 键，会抛出 ObjC NSException（valueForUndefinedKey:），
    /// 而 Swift 无法捕获 ObjC 异常，导致直接崩溃。
    /// 改用纯视图层级遍历，安全且跨版本兼容。
    func safeTableView() -> UITableView? {
        // 方案 1：尝试将 self.view 转为 UITableView
        if let tv = self.view as? UITableView {
            return tv
        }

        // 方案 2：递归遍历所有子视图查找 UITableView
        func findTableView(in view: UIView) -> UITableView? {
            for subview in view.subviews {
                if let tv = subview as? UITableView {
                    return tv
                }
                if let tv = findTableView(in: subview) {
                    return tv
                }
            }
            return nil
        }

        return findTableView(in: self.view)
    }

    /// iOS 17 兼容：安全设置 tableHeaderView
    /// 使用 safeTableView() 获取 tableView，如果获取失败则跳过
    func setTableHeaderView(_ headerView: UIView) {
        guard let tableView = safeTableView() else {
            // tableView 尚未加载，延迟重试
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.safeTableView()?.tableHeaderView = headerView
            }
            return
        }
        tableView.tableHeaderView = headerView
    }

    /// iOS 17 兼容：安全获取 _specifiers
    /// 使用 ObjC 异常安全包装器，避免 valueForUndefinedKey: 崩溃
    func safeGetSpecifiers() -> NSMutableArray? {
        return MMSafeValueForKey(self, "_specifiers") as? NSMutableArray
    }

    /// iOS 17 兼容：安全设置 _specifiers
    func safeSetSpecifiers(_ specifiers: NSMutableArray?) {
        MMSafeSetValueForKey(self, specifiers, "_specifiers")
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
