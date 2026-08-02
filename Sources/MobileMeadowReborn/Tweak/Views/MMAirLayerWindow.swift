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
        self.windowLevel = UIWindow.Level.alert - 1
        self.rootViewController = MMAirLayerViewController.shared
        remLog("MMAirLayerWindow: commonInit, windowLevel=\(self.windowLevel.rawValue), hasScene=\(self.windowScene != nil)")
    }

    deinit {
        remLog("MMAirLayerWindow: deinit")
    }

    //MARK: - Overrides

    /// 飞鸟窗口不应成为 key window，否则会抢夺 SpringBoard 主窗口的 key 状态
    /// 覆盖此方法仅设置 isHidden = false，不调用 super.makeKeyAndVisible()
    override func makeKeyAndVisible() {
        self.isHidden = false
        remLog("MMAirLayerWindow: isHidden=false (NOT making key), hasScene=\(self.windowScene != nil), frame=\(self.frame)")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self || view == self.rootViewController?.view ? nil : view
    }
}