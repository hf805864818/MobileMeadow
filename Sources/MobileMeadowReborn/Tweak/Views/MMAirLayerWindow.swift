import UIKit
import MobileMeadowRebornC

/// 飞鸟动画的覆盖层窗口
/// iOS 17 必须使用 init(windowScene:) 初始化，否则窗口无法关联到 Scene 而不可见
class MMAirLayerWindow: UIWindow {

    //MARK: - Initializers

    /// 使用 UIWindowScene 初始化（iOS 17 推荐方式）
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        commonInit()
        remLog("MMAirLayerWindow: init(windowScene:) with scene \(windowScene)")
    }

    /// 使用 frame 初始化（iOS 13+ 已废弃，仅作为兜底保留）
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        remLog("MMAirLayerWindow: init(frame:) — scene-less creation, window may not be visible on iOS 17")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        self.backgroundColor = .clear
        // 使用与原版一致的高窗口层级，确保飞鸟覆盖在所有普通窗口之上
        self.windowLevel = UIWindow.Level(rawValue: CGFLOAT_MAX / 2.0)
        self.rootViewController = MMAirLayerViewController.shared
        remLog("MMAirLayerWindow: commonInit, windowLevel=\(self.windowLevel.rawValue), hasScene=\(self.windowScene != nil)")
    }

    deinit {
        remLog("MMAirLayerWindow: deinit")
    }

    //MARK: - Overrides

    /// 飞鸟窗口需要通过 makeKeyAndVisible 正确加入渲染树
    /// 调用后立即 resign key，将 key 状态还给 SpringBoard 主窗口
    override func makeKeyAndVisible() {
        super.makeKeyAndVisible()
        // 立即放弃 key 状态，避免抢夺 SpringBoard 主窗口
        self.resignKey()
        remLog("MMAirLayerWindow: makeKeyAndVisible + resignKey, frame=\(self.frame)")
    }

    /// 与原版 MobileMeadow 一致：hitTest 恒返回 nil，窗口纯视觉不拦截任何触摸
    /// 这样飞鸟窗口不会影响桌面图标的点击和滑动手势
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }

    /// pointInside 恒返回 false，确保窗口不消费任何触摸事件
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
}