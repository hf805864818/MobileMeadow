import UIKit
import MobileMeadowRebornC

class MMAirLayerViewController: UIViewController {

    //MARK: - Variables
    //Singelton
    static let shared = MMAirLayerViewController(withFrame: UIScreen.main.bounds)

    ///MMAirLayerViewController
    private let frame: CGRect
    private let birdsManager: SBBirdsManager = SBBirdsManager.shared
    private weak var timer: Timer?

    // MARK: - Initializers
    private init(withFrame frame: CGRect) {
        self.frame = frame
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    //MARK: - Instance Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(updateAllBirds), name: UIDevice.orientationDidChangeNotification, object: nil)
        setRandomTimer()
    }

    override var shouldAutorotate: Bool { return false }

    //MARK: - Functions
    @objc private func createBirdView() {
        guard let randomBirdName = birdsManager.birdImagesNames.randomElement() else { return }
        guard let springBoard = (UIApplication.shared as? SpringBoard) else { return }

        // iOS 17 防御性检查：isLocked/isShowingHomescreen 可能不存在
        var isSpringBoardLocked: Bool = false
        var isShowingHomescreen: Bool = true

        if springBoard.responds(to: Selector(("isLocked"))) {
            isSpringBoardLocked = springBoard.isLocked()
        }
        if springBoard.responds(to: Selector(("isShowingHomescreen"))) {
            isShowingHomescreen = springBoard.isShowingHomescreen()
        }

        setRandomTimer()

        if !isSpringBoardLocked {
            if tweakPrefs.birdsHiddenInLandscape && UIDevice.current.orientation.isLandscape { return }
            if tweakPrefs.birdsHiddenInApplications && !isShowingHomescreen { return }
            remLog(randomBirdName)
            birdsManager.createRandomWindowBird(withName: randomBirdName) { _ in
                remLog("removed bird")
            }
        }
    }

    private func setRandomTimer() {
        let duration: UInt = UInt.random(in: birdsManager.birdsSpawnRate.min...birdsManager.birdsSpawnRate.max)
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: CGFloat(duration).rounded(), target: self, selector: #selector(createBirdView), userInfo: nil, repeats: false)
    }

    func updateOrientation(for view: MMBirdView) {
        // Let birds change their direction for different orientations
        guard let position = view.position, !UIDevice.current.orientation.isFlat else { return }

        let rotationAngle: CGFloat
        let scaleX: CGFloat

        switch UIDevice.current.orientation {
        case .portrait:
            rotationAngle = 0
            scaleX = 1

        case .portraitUpsideDown:
            rotationAngle = .pi
            scaleX = -1

        case .landscapeLeft:
            if view.isBirdFlipped {
                rotationAngle = position.startY >= position.endY ? .pi / 2 : -.pi / 2
                scaleX = position.startY >= position.endY ? 1 : -1
            } else {
                rotationAngle = position.startY <= position.endY ? .pi / 2 : -.pi / 2
                scaleX = position.startY <= position.endY ? 1 : -1
            }

        case .landscapeRight:
            if !view.isBirdFlipped {
                rotationAngle = position.startY >= position.endY ? -.pi / 2 : .pi / 2
                scaleX = position.startY >= position.endY ? 1 : -1
            } else {
                rotationAngle = position.startY <= position.endY ? -.pi / 2 : .pi / 2
                scaleX = position.startY <= position.endY ? 1 : -1
            }

        default: return
        }

        view.transform = CGAffineTransform.identity
        view.transform = CGAffineTransform(rotationAngle: rotationAngle).concatenating(CGAffineTransform(scaleX: scaleX, y: 1))
    }

    //MARK: - Observers
    @objc private func updateAllBirds() {
        for subview in self.view.subviews {
            if subview.isKind(of: MMBirdView.self) {
                guard let birdView = subview as? MMBirdView else { return }
                updateOrientation(for: birdView)
            }
        }
    }
}
