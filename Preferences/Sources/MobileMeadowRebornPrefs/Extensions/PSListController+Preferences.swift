import Preferences
import MobileMeadowRebornPrefsC

extension PSListController {

    /// iOS 17 兼容：安全获取 tableView
    /// 完全不使用 KVC（valueForKey），改用递归视图层级遍历
    /// 同时添加运行时类型检查，防止类型混淆
    func safeTableView() -> UITableView? {
        // 方案 1：尝试将 self.view 转为 UITableView
        // 使用 type(of:) 进行严格类型检查，防止 ObjC 类型混淆
        if type(of: self.view) == UITableView.self || self.view is UITableView {
            if let tv = self.view as? UITableView {
                return tv
            }
        }

        // 方案 2：递归遍历所有子视图查找 UITableView
        func findTableView(in view: UIView) -> UITableView? {
            for subview in view.subviews {
                // 严格类型检查：确保是 UITableView 而非普通 UIView
                if type(of: subview) == UITableView.self || subview is UITableView {
                    if let tv = subview as? UITableView {
                        return tv
                    }
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
    /// 注意：方法名不能使用 setTableHeaderView，因为它会与 UITableView 的
    /// setTableHeaderView: 选择器冲突，导致 ObjC 消息转发到 UIView 时崩溃
    /// 改用 mm_applyHeaderToTable 名称，并通过 ObjC 异常安全包装器设置
    func mm_applyHeaderToTable(_ headerView: UIView) {
        guard let tableView = safeTableView() else {
            // tableView 尚未加载，延迟重试
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                if let tv = self.safeTableView() {
                    _ = MMSafeSetTableHeader(tv, headerView)
                }
            }
            return
        }
        // 使用 ObjC 异常安全包装器设置 tableHeaderView
        _ = MMSafeSetTableHeader(tableView, headerView)
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
}
