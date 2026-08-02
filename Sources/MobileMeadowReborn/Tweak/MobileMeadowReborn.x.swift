import Orion
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
/// 核心修复：tweak 加载时 SpringBoard 的 applicationDidFinishLaunching 早已调用完毕，
/// 因此不能仅依赖该 hook。改为在 Tweak.init() 中直接调用此函数。
func setupBirdOverlayIfNeeded() {
    guard globalAirLayerWindow == nil else { return }
    remLog("setupBirdOverlayIfNeeded: starting...")

    // 方案 1（推荐）：使用 UIWindowScene 创建覆盖窗口
    if let scene = getActiveWindowScene() {
        remLog("setupBirdOverlayIfNeeded: found active scene, creating window via init(windowScene:)")
        let window = MMAirLayerWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        // 关键修复：只设置 isHidden = false，不调用 makeKeyAndVisible()
        // makeKeyAndVisible() 会抢夺 SpringBoard 主窗口的 key 状态，导致桌面异常
        window.isHidden = false
        globalAirLayerWindow = window
        remLog("setupBirdOverlayIfNeeded: window created, isHidden=\(window.isHidden), isKeyWindow=\(window.isKeyWindow)")
        return
    }

    // 方案 2：场景尚未就绪，注册观察者等待
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
        // 关键修复：只设置 isHidden = false，不调用 makeKeyAndVisible()
        window.isHidden = false
        globalAirLayerWindow = window
        if let obs = globalSceneObserver {
            NotificationCenter.default.removeObserver(obs)
            globalSceneObserver = nil
        }
    }

    // 方案 3（兜底）：3 秒后直接注入到 SpringBoard keyWindow
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        guard globalAirLayerWindow == nil else { return }
        remLog("setupBirdOverlayIfNeeded: fallback — injecting view into keyWindow")
        if let keyWindow = getSpringBoardKeyWindow() {
            let birdVC = MMAirLayerViewController.shared
            // 显式类型标注为 UIView，避免 view! 的 IUO 被 SwiftUI Optional<View> 扩展拦截
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
struct SBPlants: HookGroup { let plantsEnabled: Bool }
struct SBBirds: HookGroup { let birdsEnabled: Bool }
struct SBMailBoxBird: HookGroup { let mailBoxBirdEnabled: Bool }
/// 独立的通知 Hook 组 —— 仅在 NCNotificationShortLookViewController 类存在时激活
struct SBMailBoxBirdNotification: HookGroup { let notificationHookEnabled: Bool }

//MARK: - Initialize Tweak
struct MobileMeadowReborn: Tweak {
    init() {
        remLog("=== MobileMeadowReborn init() ===")
        remLog("Preferences Loading...")
        tweakPrefs = TweakPreferences.preferences.loadPreferences()
        remLog("Prefs: enabled=\(tweakPrefs.isTweakEnabled), plants=\(tweakPrefs.plantsEnabled), birds=\(tweakPrefs.birdsEnabled), mailbox=\(tweakPrefs.mailBoxEnabled)")

        let dockHook: SBPlants = SBPlants(plantsEnabled: tweakPrefs.plantsEnabled)
        let sceneHook: SBBirds = SBBirds(birdsEnabled: tweakPrefs.birdsEnabled)

        switch tweakPrefs.isTweakEnabled {
        case true:
            remLog("Tweak is Enabled! :)")
            if dockHook.plantsEnabled {
                if classExists("SBDockIconListView") {
                    dockHook.activate()
                    remLog("SBPlants hook group activated")
                } else {
                    remLog("⚠️ SBDockIconListView not found — plants hook skipped (iOS 17+ compatibility)")
                }
            }
            if sceneHook.birdsEnabled {
                sceneHook.activate()
                remLog("SBBirds hook group activated")

                let sceneExtraHook: SBMailBoxBird = SBMailBoxBird(mailBoxBirdEnabled: tweakPrefs.mailBoxEnabled)
                if sceneExtraHook.mailBoxBirdEnabled {
                    if classExists("SBRootFolderController") {
                        sceneExtraHook.activate()
                        remLog("SBMailBoxBird hook group activated")
                    } else {
                        remLog("⚠️ SBRootFolderController not found — mailbox hook skipped")
                    }

                    if classExists("NCNotificationShortLookViewController") {
                        let notifHook = SBMailBoxBirdNotification(notificationHookEnabled: true)
                        notifHook.activate()
                        remLog("Notification hook activated")
                    } else {
                        remLog("⚠️ NCNotificationShortLookViewController not found — notification hook skipped")
                    }
                }

                // 核心修复：直接触发飞鸟覆盖层初始化
                // applicationDidFinishLaunching 在 tweak 加载前已调用，hook 不会触发
                // 所以必须在这里主动调用
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
    @Property var airLayerWindow: MMAirLayerWindow?
    @Property var sceneObserver: NSObjectProtocol?

    /// 作为兜底：如果 applicationDidFinishLaunching 还没被调用（少数情况），也会触发
    func applicationDidFinishLaunching(_ application: Any) {
        orig.applicationDidFinishLaunching(application)
        setupBirdOverlayIfNeeded()
    }

    /// 新增：当 SpringBoard 变为活跃时触发（设备解锁、切换回桌面等）
    /// 这是比 applicationDidFinishLaunching 更可靠的触发点
    func applicationDidBecomeActive(_ application: Any) {
        orig.applicationDidBecomeActive(application)
        setupBirdOverlayIfNeeded()
    }
}

class SBDockHook: ClassHook<SBDockIconListView> {
    typealias Group = SBPlants
    @Property var dockGround: MMGroundContainerView?

    func didMoveToWindow() {
        orig.didMoveToWindow()

        // 如果 superview 尚未就绪，直接返回（didMoveToWindow 会被系统多次调用）
        guard target.superview != nil else {
            remLog("SBDockHook: superview is nil, will retry on next didMoveToWindow")
            return
        }
        // 如果已创建则跳过
        guard self.dockGround == nil else { return }

        remLog("SBDockHook: creating MMGroundContainerView...")
        self.dockGround = MMGroundContainerView.shared
        remLog("MeadowGroundDock created...")
        if let ground = self.dockGround {
            target.superview?.addSubview(ground)
            remLog("SBDockHook: ground added to superview, frame=\(ground.frame)")
        }
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
    /// 使用独立的通知 Hook 组，仅在类存在时激活
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