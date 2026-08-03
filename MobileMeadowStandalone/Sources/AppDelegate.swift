import UIKit
import CoreGraphics

// MARK: - Standalone App Entry Point
// 绕过 RootHide SpringBoard 注入限制的独立应用方案
// 该 App 启动后创建一个透明覆盖窗口，在屏幕上渲染飞鸟动画
// 安装后通过 TrollStore 运行，进入后台即可持续显示

// MARK: - 简易飞鸟视图（独立 App 自包含，不依赖 tweak 源码）
class StandaloneBirdView: UIView {
    let birdName: String
    private var birdImageView: UIImageView?
    private var animationTimer: Timer?
    private var currentFrame: Int = 0
    private let frameCount: Int
    
    init(birdName: String) {
        self.birdName = birdName
        // 根据鸟的类型确定帧数
        switch birdName {
        case "greenbird", "redbird": frameCount = 3
        case "ufo": frameCount = 4
        case "deliverybird": frameCount = 3
        default: frameCount = 1
        }
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .clear
        
        // 尝试从 Assets 目录加载飞鸟图片
        let assetsPath = StandaloneAssets.assetsPath
        let firstFramePath = "\(assetsPath)/\(birdName)_0.png"
        
        if FileManager.default.fileExists(atPath: firstFramePath) {
            // 使用真实图片资源
            birdImageView = UIImageView()
            birdImageView?.contentMode = .scaleAspectFit
            birdImageView?.frame = bounds
            birdImageView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(birdImageView!)
            updateBirdFrame()
            startAnimation()
        } else {
            // 回退到 emoji 显示
            let label = UILabel()
            let emoji: String
            switch birdName {
            case "greenbird": emoji = "🐦"
            case "redbird": emoji = "🦜"
            case "ufo": emoji = "🛸"
            case "deliverybird": emoji = "🕊️"
            default: emoji = "🐦"
            }
            label.text = emoji
            label.font = UIFont.systemFont(ofSize: 40)
            label.textAlignment = .center
            label.frame = bounds
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(label)
        }
        
        // 随机缩放
        let scale = CGFloat.random(in: 0.8...1.5)
        transform = CGAffineTransform(scaleX: scale, y: scale)
    }
    
    private func startAnimation() {
        guard frameCount > 1 else { return }
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.updateBirdFrame()
        }
    }
    
    private func updateBirdFrame() {
        let assetsPath = StandaloneAssets.assetsPath
        let imagePath = "\(assetsPath)/\(birdName)_\(currentFrame).png"
        if FileManager.default.fileExists(atPath: imagePath) {
            birdImageView?.image = UIImage(contentsOfFile: imagePath)
        }
        currentFrame = (currentFrame + 1) % frameCount
    }
    
    deinit {
        animationTimer?.invalidate()
    }
}

// MARK: - 资源路径管理
class StandaloneAssets {
    static var assetsPath: String {
        // 尝试多个路径
        var path = "/var/jb/Library/Application Support/MobileMeadow/Assets"
        if FileManager.default.fileExists(atPath: path) { return path }
        
        path = "/Library/Application Support/MobileMeadow/Assets"
        if FileManager.default.fileExists(atPath: path) { return path }
        
        path = "/var/mobile/Library/Application Support/MobileMeadow/Assets"
        if FileManager.default.fileExists(atPath: path) { return path }
        
        // 尝试从 App bundle 中加载
        if let bundlePath = Bundle.main.path(forResource: "Assets", ofType: nil),
           FileManager.default.fileExists(atPath: bundlePath) {
            return bundlePath
        }
        
        // 返回默认路径（即使不存在）
        return "/var/jb/Library/Application Support/MobileMeadow/Assets"
    }
}

// MARK: - 飞鸟覆盖层 ViewController
class BirdOverlayViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }
}

// MARK: - 透明覆盖窗口
class StandaloneOverlayWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
}

// MARK: - App Delegate
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var birdOverlayWindow: StandaloneOverlayWindow?
    var birdTimer: Timer?
    
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
        let overlay = StandaloneOverlayWindow(windowScene: scene)
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
        
        let birdView = StandaloneBirdView(birdName: birdName)
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