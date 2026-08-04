import Orion
import UIKit
import MobileMeadowRebornC

// MobileMeadow Reborn - Turn your phone into a meadow. Add flowers to your apps. Let birds fly on your screen.
// Rewrite for modern iOS 14.0 - 17.x
// based on original from @pixelomer: https://github.com/pixelomer/MobileMeadow

//MARK: - iOS Compatibility Helpers
/// 检查 ObjC 运行时中某个类是否存在
private func classExists(_ className: String) -> Bool {
    return NSClassFromString(className) != nil
}

/// 获取 SpringBoard 的活跃 UIWindowScene（iOS 17 兼容）
private func getActiveWindowScene() -> UIWindowScene? {
    return UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first(where: { $0.activationState == .foregroundActive })
        ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
}

/// 获取 SpringBoard 的 key window（iOS 17 兼容）
private func getSpringBoardKeyWindow() -> UIWindow? {
    guard let scene = getActiveWindowScene() else { return nil }
    return scene.windows.first(where: { $0.isKeyWindow })
        ?? scene.windows.first
}

//MARK: - Variables
var tweakPrefs: SettingsModel = SettingsModel()

/// 全局飞鸟覆盖层窗口引用（与 SBInterfaceHook.airLayerWindow 同步）
var globalAirLayerWindow: MMAirLayerWindow?
var globalSceneObserver: NSObjectProtocol?

//MARK: - 全局飞鸟覆盖层初始化
func setupBirdOverlayIfNeeded() {
    guard globalAirLayerWindow == nil else { return }
    remLog("setupBirdOverlayIfNeeded: starting...")

    if let scene = getActiveWindowScene() {
        remLog("setupBirdOverlayIfNeeded: found active scene, creating window via init(windowScene:)")
        let window = MMAirLayerWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.makeKeyAndVisible()
        globalAirLayerWindow = window
        remLog("setupBirdOverlayIfNeeded: window created and visible, isKeyWindow=\(window.isKeyWindow)")
        return
    }

    remLog("setupBirdOverlayIfNeeded: no active scene yet, registering observer...")
    globalSceneObserver = NotificationCenter.default.addObserver(
        forName: UIScene.didActivateNotification,
        object: nil,
        queue: .main
    ) { notification in
        guard globalAirLayerWindow == nil,
              let scene = notification.object as? UIWindowScene else { return }
        remLog("setupBirdOverlayIfNeeded: scene activated, creating window")
        let window = MMAirLayerWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.makeKeyAndVisible()
        globalAirLayerWindow = window
        if let obs = globalSceneObserver {
            NotificationCenter.default.removeObserver(obs)
            globalSceneObserver = nil
        }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        guard globalAirLayerWindow == nil else { return }
        remLog("setupBirdOverlayIfNeeded: fallback — injecting view into keyWindow")
        if let keyWindow = getSpringBoardKeyWindow() {
            let birdVC = MMAirLayerViewController.shared
            let birdView: UIView = birdVC.view
            birdView.frame = keyWindow.bounds
            birdView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            birdView.isUserInteractionEnabled = false
            keyWindow.addSubview(birdView)
            remLog("setupBirdOverlayIfNeeded: bird view injected, frame=\(birdView.frame)")
        } else {
            remLog("setupBirdOverlayIfNeeded: FATAL — no keyWindow found")
        }
    }
}

//MARK: - Hook Groups
// 注意：HookGroup 不能包含任何属性！
// Orion 的 _activate() 会通过 KVC (setValue:forKey:) 将属性设置到 Hook 目标对象上，
// 系统类（如 SBDockView、MTMaterialView 等）没有这些属性，会抛出 NSUnknownKeyException 导致安全模式。
// 所有配置通过全局变量 tweakPrefs 传递。
struct SBPlants: HookGroup {}
struct SBPlantsDock_iOS17: HookGroup {}
struct SBPlantsVisual: HookGroup {}
struct SBBirds: HookGroup {}
struct SBMailBoxBird: HookGroup {}
struct SBMailBoxBirdNotification: HookGroup {}

//MARK: - Safe Activation Helper
/// 安全激活 Hook 组，捕获 NSException 防止安全模式
func safeActivate(_ name: String, _ block: @escaping () -> Void) {
    let success = MMSafeActivate(name) {
        block()
    }
    if success {
        remLog("✅ Hook activated: \(name)")
    } else {
        remLog("❌ Hook activation FAILED: \(name)")
    }
}

//MARK: - Initialize Tweak
struct MobileMeadowReborn: Tweak {
    /// 重写 Orion 的错误处理器，阻止 fatalError 崩溃
    /// Orion 默认的 handleErrorDefault 会调用 orionError → fatalError → EXC_BREAKPOINT
    /// 这无法被 ObjC @try/@catch 捕获，必须在此拦截
    static func handleError(_ error: Error) {
        remLog("⚠️ Orion hook error (suppressed): \(error.localizedDescription)")
        // 不调用 fatalError，静默继续
    }

    init() {
        remLog("=== MobileMeadowReborn init() ===")
        remLog("iOS Version: \(UIDevice.current.systemVersion)")
        remLog("Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
        remLog("jbroot: \(MMGetJbrootPath() ?? "nil")")
        remLog("log file: \(MMGetLogFilePath())")
        remLog("assets path: \(MMGetAssetsPath())")
        remLog("Preferences Loading...")
        tweakPrefs = TweakPreferences.preferences.loadPreferences()
        remLog("Prefs: enabled=\(tweakPrefs.isTweakEnabled), plants=\(tweakPrefs.plantsEnabled), birds=\(tweakPrefs.birdsEnabled), mailbox=\(tweakPrefs.mailBoxEnabled)")

        switch tweakPrefs.isTweakEnabled {
        case true:
            remLog("Tweak is Enabled! :)")
            if tweakPrefs.plantsEnabled {
                // SBPlantsVisual 组包含 MTMaterialViewHook 和 SBIconListPageControlHook
                // 必须检查两个类都存在才能激活，否则 Orion 会 fatalError
                let mtMaterialExists = classExists("MTMaterialView")
                let pageControlExists = classExists("SBIconListPageControl")
                remLog("SBPlantsVisual prereq: MTMaterialView=\(mtMaterialExists), SBIconListPageControl=\(pageControlExists)")

                if mtMaterialExists && pageControlExists {
                    safeActivate("SBPlantsVisual") {
                        SBPlantsVisual().activate()
                    }
                } else {
                    remLog("⚠️ SBPlantsVisual skipped — MTMaterialView or SBIconListPageControl not found on this iOS")
                    // iOS 17: 单独尝试 MTMaterialView（如果存在），跳过 SBIconListPageControl
                    if mtMaterialExists {
                        remLog("  MTMaterialView exists, but SBPlantsVisual requires both classes — skipping entire group")
                    }
                }

                if classExists("SBDockIconListView") {
                    safeActivate("SBPlants (SBDockIconListView)") {
                        SBPlants().activate()
                    }
                } else if classExists("SBDockView") {
                    safeActivate("SBPlantsDock_iOS17 (SBDockView)") {
                        SBPlantsDock_iOS17().activate()
                    }
                } else {
                    remLog("⚠️ Neither SBDockIconListView nor SBDockView found — plants dock hook skipped")
                }
            }
            if tweakPrefs.birdsEnabled {
                // SBBirds 组包含 SBInterfaceHook: ClassHook<SpringBoard>
                // SpringBoard 类在 SpringBoard 进程中必然存在
                safeActivate("SBBirds") {
                    SBBirds().activate()
                }

                if tweakPrefs.mailBoxEnabled {
                    if classExists("SBRootFolderController") {
                        safeActivate("SBMailBoxBird") {
                            SBMailBoxBird().activate()
                        }
                    } else {
                        remLog("⚠️ SBRootFolderController not found — mailbox hook skipped")
                    }

                    if classExists("NCNotificationShortLookViewController") {
                        safeActivate("SBMailBoxBirdNotification") {
                            SBMailBoxBirdNotification().activate()
                        }
                    } else {
                        remLog("⚠️ NCNotificationShortLookViewController not found — notification hook skipped")
                    }
                }

                DispatchQueue.main.async {
                    setupBirdOverlayIfNeeded()
                    remLog("setupBirdOverlayIfNeeded() called from Tweak.init()")
                }
            }
        case false:
            remLog("Tweak is Disabled! :(")
            break
        }
        remLog("=== MobileMeadowReborn init() complete ===")
    }
}

//MARK: - Hooks
class SBInterfaceHook: ClassHook<SpringBoard> {
    typealias Group = SBBirds

    func applicationDidFinishLaunching(_ application: Any) {
        orig.applicationDidFinishLaunching(application)
        setupBirdOverlayIfNeeded()
    }

    func applicationDidBecomeActive(_ application: Any) {
        orig.applicationDidBecomeActive(application)
        setupBirdOverlayIfNeeded()
    }
}

class SBDockHook: ClassHook<SBDockIconListView> {
    typealias Group = SBPlants

    func didMoveToWindow() {
        orig.didMoveToWindow()

        guard target.superview != nil else { return }

        // 使用 objc_setAssociatedObject 替代 @Property，避免 KVC 崩溃
        let key = "mm_dockGround"
        if MMGetProperty(target, key) != nil { return }

        remLog("SBDockHook: creating MMGroundContainerView...")
        let ground = MMGroundContainerView.shared
        MMSetProperty(target, key, ground)
        remLog("MeadowGroundDock created...")
        target.superview?.addSubview(ground)
        remLog("SBDockHook: ground added to superview, frame=\(ground.frame)")
    }
}

/// 强制 Dock 背景材质视图不透明，使植物可见
class MTMaterialViewHook: ClassHook<MTMaterialView> {
    typealias Group = SBPlantsVisual

    func setAlpha(_ alpha: CGFloat) {
        if let superview = target.superview, NSStringFromClass(type(of: superview)) == "SBDockView" {
            orig.setAlpha(1.0)
        } else {
            orig.setAlpha(alpha)
        }
    }

    func setHidden(_ hidden: Bool) {
        if let superview = target.superview, NSStringFromClass(type(of: superview)) == "SBDockView" {
            orig.setHidden(false)
        } else {
            orig.setHidden(hidden)
        }
    }
}

/// 隐藏主屏幕页面指示器小圆点
class SBIconListPageControlHook: ClassHook<SBIconListPageControl> {
    typealias Group = SBPlantsVisual

    func setHidden(_ hidden: Bool) {
        orig.setHidden(true)
    }

    func didMoveToWindow() {
        orig.didMoveToWindow()
        target.isHidden = true
    }
}

/// iOS 17+ 替代 Hook：直接 Hook SBDockView 而非 SBDockIconListView
class SBDockViewHook: ClassHook<SBDockView> {
    typealias Group = SBPlantsDock_iOS17

    func didMoveToWindow() {
        orig.didMoveToWindow()

        guard target.superview != nil else {
            remLog("SBDockViewHook: superview is nil, will retry on next didMoveToWindow")
            return
        }

        // 使用 objc_setAssociatedObject 替代 @Property，避免 KVC 崩溃
        let key = "mm_dockGround_ios17"
        if MMGetProperty(target, key) != nil { return }

        remLog("SBDockViewHook: creating MMGroundContainerView (iOS 17+)...")
        let ground = MMGroundContainerView.shared
        MMSetProperty(target, key, ground)
        remLog("MeadowGroundDock created (iOS 17+)...")
        target.addSubview(ground)
        remLog("SBDockViewHook: ground added to dock view, frame=\(ground.frame)")
    }
}

class SBHomescreenHook: ClassHook<SBRootFolderController> {
    typealias Group = SBMailBoxBird

    func viewDidAppear(_ animated: Bool) {
        orig.viewDidAppear(animated)

        SBApplicationManager.shared.getBadgeValues { result in
            switch result {
            case .success(let value):
                let mailBoxView: MMMailBoxView = MMGroundContainerView.shared.mailBoxView
                if mailBoxView.iconType == .appIcon {
                    mailBoxView.mailBoxIconImageView.image = value.map{ $0.icon }.first
                }
                if value.count <= 0 {
                    SBBirdsManager.shared.handleFlyingAwayDeliveryBird()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        mailBoxView.handleState(.empty)
                    }
                }
            case .failure(let error):
                remLog("SBHomescreenHook error: \(error.localizedDescription)")
            }
        }
    }
}

class NCNotificationHook: ClassHook<NCNotificationShortLookViewController> {
    typealias Group = SBMailBoxBirdNotification

    func viewDidLoad() {
        orig.viewDidLoad()

        SBApplicationManager.shared.getBadgeValues { result in
            switch result {
            case .success(let value):
                let mailBoxView = MMGroundContainerView.shared.mailBoxView
                if mailBoxView.iconType == .appIcon {
                    mailBoxView.mailBoxIconImageView.image = value.map{ $0.icon }.first
                }
                if value.count > 0 {
                    SBBirdsManager.shared.handleLandingDeliveryBird()
                }
            case .failure(let error):
                remLog("NCNotificationHook error: \(error.localizedDescription)")
            }
        }
    }
}
