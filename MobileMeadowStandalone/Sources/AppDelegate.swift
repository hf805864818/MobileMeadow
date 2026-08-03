import UIKit
import CoreGraphics

// MARK: - Standalone App Entry Point
// 绕过 RootHide SpringBoard 注入限制的独立应用方案
// 该 App 启动后创建一个透明覆盖窗口，在屏幕上渲染飞鸟动画
// 安装后通过 TrollStore 运行，进入后台即可持续显示

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var birdOverlayWindow: MMAirLayerWindow?
    var birdTimer: Timer?
    private var groundContainerView: MMGroundContainerView?
    
    // 飞鸟相关配置
    private let birdNames: [String] = ["greenbird", "redbird", "ufo"]
    private let spawnRateRange: (min: UInt, max: UInt) = (5, 15)
    private let animationDurationRange: (min: CGFloat, max: CGFloat) = (10, 20)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        NSLog("[MobileMeadow] Standalone app launched")
        
        // 创建极简用户界面窗口
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        let vc = UIViewController()
        vc.view.backgroundColor = .black
        
        // 提示标签
        let label = UILabel()
        label.text = "MobileMeadow"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(label)
        
        let subtitle = UILabel()
        subtitle.text = "飞鸟动画已在后台运行\n切换到桌面即可看到效果"
        subtitle.textColor = .gray
        subtitle.font = UIFont.systemFont(ofSize: 14)
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(subtitle)
        
        let dismissBtn = UIButton(type: .system)
        dismissBtn.setTitle("进入后台运行", for: .normal)
        dismissBtn.setTitleColor(.white, for: .normal)
        dismissBtn.backgroundColor = UIColor(red: 0.2, green: 0.6, blue: 0.4, alpha: 1.0)
        dismissBtn.layer.cornerRadius = 10
        dismissBtn.translatesAutoresizingMaskIntoConstraints = false
        dismissBtn.addTarget(self, action: #selector(goToBackground), for: .touchUpInside)
        vc.view.addSubview(dismissBtn)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor, constant: -60),
            subtitle.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 16),
            subtitle.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            subtitle.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 40),
            subtitle.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -40),
            dismissBtn.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            dismissBtn.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 30),
            dismissBtn.widthAnchor.constraint(equalToConstant: 200),
            dismissBtn.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
        
        // 延迟初始化飞鸟覆盖层，等待 Scene 就绪
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupBirdOverlay()
        }
        
        return true
    }
    
    @objc private func goToBackground() {
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    }
    
    private func setupBirdOverlay() {
        guard birdOverlayWindow == nil else { return }
        
        // 获取活跃的 window scene
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first
        else {
            NSLog("[MobileMeadow] No window scene available, retrying in 2s...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.setupBirdOverlay()
            }
            return
        }
        
        // 创建飞鸟覆盖窗口
        let overlay = UIWindow(windowScene: scene)
        overlay.backgroundColor = .clear
        overlay.windowLevel = UIWindow.Level(rawValue: CGFLOAT_MAX / 2.0)
        overlay.rootViewController = BirdOverlayViewController()
        overlay.frame = scene.coordinateSpace.bounds
        overlay.isUserInteractionEnabled = false
        overlay.makeKeyAndVisible()
        overlay.resignKey()
        
        birdOverlayWindow = overlay
        NSLog("[MobileMeadow] Bird overlay window created, frame=\(overlay.frame)")
        
        // 设置飞鸟生成定时器
        scheduleNextBird()
    }
    
    private func scheduleNextBird() {
        let duration = Double.random(in: Double(spawnRateRange.min)...Double(spawnRateRange.max))
        birdTimer?.invalidate()
        birdTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.spawnBird()
            self?.scheduleNextBird()
        }
    }
    
    private func spawnBird() {
        guard let overlay = birdOverlayWindow,
              let birdVC = overlay.rootViewController as? BirdOverlayViewController,
              let birdName = birdNames.randomElement() else { return }
        
        let birdView = MMBirdView(withBirdName: birdName)
        birdVC.view.addSubview(birdView)
        
        // 随机起始位置和方向
        let screenW = overlay.bounds.width
        let screenH = overlay.bounds.height
        let fromLeft = Bool.random()
        let y = CGFloat.random(in: screenH * 0.1...screenH * 0.6)
        
        birdView.frame = CGRect(
            x: fromLeft ? -100 : screenW + 100,
            y: y,
            width: 60,
            height: 60
        )
        
        let duration = Double.random(in: Double(animationDurationRange.min)...Double(animationDurationRange.max))
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear) {
            birdView.frame.origin.x = fromLeft ? screenW + 100 : -100
        } completion: { _ in
            birdView.removeFromSuperview()
        }
    }
}

// MARK: - 飞鸟覆盖层 ViewController
class BirdOverlayViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

// MARK: - 简易飞鸟视图（兼容独立 App 模式）
// 如果 MMBirdView 不可用（编译时），使用此简易版本
class SimpleBirdView: UIView {
    let birdName: String
    
    init(birdName: String) {
        self.birdName = birdName
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .clear
        
        // 使用 emoji 作为简易飞鸟图标
        let emoji: String
        switch birdName {
        case "greenbird": emoji = "🐦"
        case "redbird": emoji = "🦜"
        case "ufo": emoji = "🛸"
        default: emoji = "🐦"
        }
        
        let label = UILabel()
        label.text = emoji
        label.font = UIFont.systemFont(ofSize: 40)
        label.textAlignment = .center
        label.frame = bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(label)
        
        // 随机缩放
        let scale = CGFloat.random(in: 0.8...1.5)
        transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}

// 兼容类型别名
typealias MMBirdView = SimpleBirdView