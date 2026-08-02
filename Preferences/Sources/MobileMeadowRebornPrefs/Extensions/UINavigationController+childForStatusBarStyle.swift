import UIKit
import Preferences

extension UINavigationController {
    override open var childForStatusBarStyle: UIViewController? {
        // 仅对 PSListController 子类（即本插件的设置页面）覆盖状态栏样式
        // 避免影响 Settings.app 中其他导航控制器的行为（iOS 17 兼容）
        if let topVC = topViewController, topVC is PSListController {
            return topVC
        }
        return nil
    }
}
