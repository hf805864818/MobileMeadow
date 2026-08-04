import Orion
import UIKit
import MobileMeadowRebornAppsC

// MobileMeadowRebornApps - This subproject is responsible for all apps with a UITabBar and creates (if not custom) a MeadowGround
//MARK: - Variables
var tweakPrefs: SettingsModel = SettingsModel()

//MARK: - Hooks
class UITabBarHook: ClassHook<_UIBarBackground> {
    func didMoveToSuperview() {
        orig.didMoveToSuperview()

        // We don't want an initializer here, as the preferences will load in lots of deamons and other Processes
        // Load preferences only once for each app in it's life cycle
        DispatchQueue.once {
            tweakPrefs = TweakPreferences.preferences.loadPreferences()
        }

        switch tweakPrefs.isTweakEnabled && tweakPrefs.plantsEnabled && !tweakPrefs.plantsHiddenInApps {
        case true: createMeadowGround()
        default: break
        }
    }

    //orion:new
    func createMeadowGround() {
        guard let superview = target.superview else { return }
        guard let viewControllerForAncestor = target._viewControllerForAncestor() else { return }

        // 使用 objc_setAssociatedObject 替代 @Property，避免 KVC 崩溃
        let key = "mm_groundContainer"
        if MMGetProperty(target, key) != nil { return }

        if (superview.isKind(of: UITabBar.self)) {
            if !(viewControllerForAncestor.isKind(of: UITabBarController.self)) { return }
            if (superview != (viewControllerForAncestor as? UITabBarController)?.tabBar) { return }
        } else if (superview.isKind(of: UIToolbar.self)) {
            let convertedPoint: CGPoint = superview.convert(.zero, to: nil)
            if ((convertedPoint.y + superview.frame.size.height) != UIScreen.main.bounds.size.height) && (viewControllerForAncestor.navigationController?.toolbar != superview) { return }
        } else { return }

        let container = MMGroundContainerView()
        MMSetProperty(target, key, container)
        target.addSubview(container)
    }
}
