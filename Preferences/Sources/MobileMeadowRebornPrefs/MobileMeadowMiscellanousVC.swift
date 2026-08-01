import Preferences
import MobileMeadowRebornPrefsC

class MobileMeadowMiscellanousVC: PSListController {
    
    let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 150, height: 350))
    
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
        // iOS 17 兼容：在 viewDidLoad 中安全设置 tableHeaderView
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setTableHeaderView(self.headerView)
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
