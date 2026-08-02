import Orion
import MobileMeadowRebornC

// MobileMeadow Reborn - Turn your phone into a meadow. Add flowers to your apps. Let birds fly on your screen.
// Rewrite for modern iOS 14.0 - 16.7.10
// based on original from @pixelomer: https://github.com/pixelomer/MobileMeadow
// iOS 17 compatibility patches applied

//MARK: - iOS Compatibility Helpers
/// 检查 ObjC 运行时中某个类是否存在（iOS 17 通知系统重构后部分类可能消失）
private func classExists(_ className: String) -> Bool {
    return NSClassFromString(className) != nil
}

/// 获取 SpringBoard 的活跃 UIWindowScene
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

//MARK: - Hook Groups
struct SBPlants: HookGroup { let plantsEnabled: Bool }
struct SBBirds: HookGroup { let birdsEnabled: Bool }
struct SBMailBoxBird: HookGroup { let mailBoxBirdEnabled: Bool }
/// 独立的邮件通知 Hook 组 —— NCNotificationShortLookViewController 在 iOS 17 中可能不存在，
/// 需要在激活前检查类是否存在，避免 tweak 加载时崩溃
struct SBMailBoxBirdNotification: HookGroup { let notificationHookEnabled: Bool }

//MARK: - Initialize Tweak
struct MobileMeadowReborn: Tweak {
    init() {
        remLog("=== MobileMeadowReborn init() ===")
        remLog("Preferences Loading...")
        tweakPrefs = TweakPreferences.preferences.loadPreferences()
        remLog("Preferences loaded: isTweakEnabled=\(tweakPrefs.isTweakEnabled), plants=\(tweakPrefs.plantsEnabled), birds=\(tweakPrefs.birdsEnabled), mailbox=\(tweakPrefs.mailBoxEnabled)")
        
        let dockHook: SBPlants = SBPlants(plantsEnabled: tweakPrefs.plantsEnabled)
        let sceneHook: SBBirds = SBBirds(birdsEnabled: tweakPrefs.birdsEnabled)
        
        switch tweakPrefs.isTweakEnabled {
        case true:
            remLog("Tweak is Enabled! :)")
            if dockHook.plantsEnabled {
                // iOS 17 兼容性检查：SBDockIconListView 在 iOS 17 中可能已被移除或重命名
                if classExists("SBDockIconListView") {
                    dockHook.activate()
                    remLog("SBPlants hook group activated (SBDockIconListView found)")
                } else {
                    remLog("⚠️ SBDockIconListView not found on this iOS version — plants hook skipped")
                    remLog("   This is expected on iOS 17+ where SpringBoard dock classes have changed")
                }
            }
            if sceneHook.birdsEnabled {
                sceneHook.activate()
                remLog("SBBirds hook group activated")
                let sceneExtraHook: SBMailBoxBird = SBMailBoxBird(mailBoxBirdEnabled: tweakPrefs.mailBoxEnabled)
                if sceneExtraHook.mailBoxBirdEnabled {
                    // iOS 17 兼容性检查：SBRootFolderController 在 iOS 17 中可能已变更
                    if classExists("SBRootFolderController") {
                        sceneExtraHook.activate()
                        remLog("SBMailBoxBird hook group activated (SBRootFolderController found)")
                    } else {
                        remLog("⚠️ SBRootFolderController not found — mailbox hook skipped (iOS 17+ compatibility)")
                    }
                    
                    // iOS 17 兼容性检查：NCNotificationShortLookViewController 在 iOS 17 中通知系统重构后可能不存在
                    // 仅当目标类存在时才激活通知 Hook，避免 tweak 加载时因找不到类而崩溃
                    if classExists("NCNotificationShortLookViewController") {
                        let notifHook = SBMailBoxBirdNotification(notificationHookEnabled: true)
                        notifHook.activate()
                        remLog("Notification hook activated (NCNotificationShortLookViewController found)")
                    } else {
                        remLog("⚠️ NCNotificationShortLookViewController not found — notification hook skipped (iOS 17+ compatibility)")
                    }
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
    
    func applicationDidFinishLaunching(_ application: Any) {
        orig.applicationDidFinishLaunching(application)
        
        if (self.airLayerWindow == nil) {
            setupBirdOverlay()
        }
    }
    
    //orion:new
    func setupBirdOverlay() {
        remLog("SBInterfaceHook: setupBirdOverlay called")
        
        // 方案 1（推荐）：使用 UIWindowScene 创建覆盖窗口
        if let scene = getActiveWindowScene() {
            remLog("SBInterfaceHook: found active scene, creating window via init(windowScene:)")
            let window = MMAirLayerWindow(windowScene: scene)
            window.frame = scene.coordinateSpace.bounds
            window.makeKeyAndVisible()
            self.airLayerWindow = window
            remLog("SBInterfaceHook: window created and visible, isHidden=\(window.isHidden)")
            return
        }
        
        // 方案 2：场景尚未就绪，注册观察者等待
        remLog("SBInterfaceHook: no active scene yet, registering for scene activation...")
        sceneObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  self.airLayerWindow == nil,
                  let scene = notification.object as? UIWindowScene else { return }
            remLog("SBInterfaceHook: scene activated, creating window")
            let window = MMAirLayerWindow(windowScene: scene)
            window.frame = scene.coordinateSpace.bounds
            window.makeKeyAndVisible()
            self.airLayerWindow = window
            if let obs = self.sceneObserver {
                NotificationCenter.default.removeObserver(obs)
                self.sceneObserver = nil
            }
        }
        
        // 方案 3（兜底）：3 秒后如果窗口仍未创建，直接注入到 SpringBoard keyWindow
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.airLayerWindow == nil else { return }
            remLog("SBInterfaceHook: fallback — injecting view directly into SpringBoard keyWindow")
            if let keyWindow = getSpringBoardKeyWindow() {
                let birdView = MMAirLayerViewController.shared.view!
                birdView.frame = keyWindow.bounds
                birdView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                birdView.isUserInteractionEnabled = false
                keyWindow.addSubview(birdView)
                remLog("SBInterfaceHook: bird view injected into keyWindow, frame=\(birdView.frame)")
            } else {
                remLog("SBInterfaceHook: FATAL — no keyWindow found, birds will not appear!")
            }
        }
    }
}

class SBDockHook: ClassHook<SBDockIconListView> {
    typealias Group = SBPlants
    @Property var dockGround: MMGroundContainerView?
    
    func didMoveToWindow() {
        orig.didMoveToWindow()
        createDockGroundIfNeeded()
    }
    
    //orion:new
    func createDockGroundIfNeeded() {
        // 如果已创建则跳过
        guard self.dockGround == nil else { return }
        
        // 如果 superview 尚未就绪，直接返回
        // didMoveToWindow 会在视图层级变化时被系统多次调用，无需手动重试
        guard let superview = target.superview else {
            remLog("SBDockHook: superview is nil, will retry on next didMoveToWindow")
            return
        }
        
        remLog("SBDockHook: creating MMGroundContainerView...")
        self.dockGround = MMGroundContainerView.shared
        remLog("MeadowGroundDock created...")
        if let ground = self.dockGround {
            superview.addSubview(ground)
            remLog("SBDockHook: ground added to superview, frame=\(ground.frame)")
        }
    }
}

class SBHomescreenHook: ClassHook<SBRootFolderController> {
    typealias Group = SBMailBoxBird
    
    func viewDidAppear(_ animated: Bool) {
        orig.viewDidAppear(animated)
        
        // iOS 17 防御性检查：确保 mailBoxView 可访问
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
    /// 使用独立的通知 Hook 组，仅在 NCNotificationShortLookViewController 类存在时激活
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
