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
        remLog("Preferences Loading...")
        tweakPrefs = TweakPreferences.preferences.loadPreferences()
        
        let dockHook: SBPlants = SBPlants(plantsEnabled: tweakPrefs.plantsEnabled)
        let sceneHook: SBBirds = SBBirds(birdsEnabled: tweakPrefs.birdsEnabled)
        
        switch tweakPrefs.isTweakEnabled {
        case true:
            remLog("Tweak is Enabled! :)")
            if dockHook.plantsEnabled { dockHook.activate() }
            if sceneHook.birdsEnabled {
                sceneHook.activate()
                let sceneExtraHook: SBMailBoxBird = SBMailBoxBird(mailBoxBirdEnabled: tweakPrefs.mailBoxEnabled)
                if sceneExtraHook.mailBoxBirdEnabled {
                    sceneExtraHook.activate()
                    
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
    }
}

//MARK: - Hooks
class SBInterfaceHook: ClassHook<SpringBoard> {
    typealias Group = SBBirds
    @Property var airLayerWindow: MMAirLayerWindow?
    
    func applicationDidFinishLaunching(_ application: Any) {
        orig.applicationDidFinishLaunching(application)
        
        if (self.airLayerWindow == nil) {
            self.airLayerWindow = MMAirLayerWindow(frame: UIScreen.main.bounds)
        }
    }
}

class SBDockHook: ClassHook<SBDockIconListView> {
    typealias Group = SBPlants
    @Property var dockGround: MMGroundContainerView?
    
    func didMoveToWindow() {
        orig.didMoveToWindow()
        
        DispatchQueue.once {
            self.createMeadowDockGround()
        }
    }
    
    //orion:new
    func createMeadowDockGround() {
        guard let superview = target.superview else { return }
        if (self.dockGround == nil) {
            self.dockGround = MMGroundContainerView.shared
            remLog("MeadowGroundDock created...")
            if let ground = self.dockGround {
                superview.addSubview(ground)
            }
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
