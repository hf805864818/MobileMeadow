import UIKit
import Preferences

// 禁用此扩展 —— 全局覆盖 UINavigationController.childForStatusBarStyle
// 会影响 Settings.app 中所有导航控制器的行为，iOS 17 上可能触发运行时陷阱
// 待确认基本骨架可运行后，再逐个恢复
/*
extension UINavigationController {
    override open var childForStatusBarStyle: UIViewController? {
        if let topVC = topViewController, topVC is PSListController {
            return topVC
        }
        return nil
    }
}
*/