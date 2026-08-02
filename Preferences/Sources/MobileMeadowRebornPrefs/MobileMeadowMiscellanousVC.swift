import Preferences
import MobileMeadowRebornPrefsC

class MobileMeadowMiscellanousVC: PSListController {
    
    let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 150, height: 350))
    private var headerApplied = false
    private var specifiersLoaded = false
    
    override var specifiers: NSMutableArray? {
        get {
            if !specifiersLoaded {
                specifiersLoaded = true
                if let loaded = safeLoadSpecifiers(fromPlistName: "MobileMeadowMiscellanous") {
                    safeSetSpecifiers(loaded)
                }
            }
            return safeGetSpecifiers()
        }
        set {
            safeSetSpecifiers(newValue)
        }
    }
    
    override init(forContentSize contentSize: CGSize) {
        super.init(forContentSize: contentSize)
        
        let bannerImageView = UIImageView(frame: headerView.bounds)
        bannerImageView.contentMode = .scaleAspectFit
        bannerImageView.image = UIImage(contentsOfFile: prefsAssetsPath + "MMMiscellanousBanner.png")
        bannerImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(bannerImageView)
        
        NSLayoutConstraint.activate( [
            bannerImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 25),
            bannerImageView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -25),
            bannerImageView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // iOS 17 兼容：不在 viewDidLoad 中设置 headerView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 在 viewDidAppear 中设置 headerView
        if !headerApplied {
            mm_applyHeaderToTable(headerView)
            headerApplied = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NavigationBarManager.setNavBarThemed(enabled: true, vc: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NavigationBarManager.setNavBarThemed(enabled: false, vc: self)
    }
    
    //MARK: - Required
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
}
