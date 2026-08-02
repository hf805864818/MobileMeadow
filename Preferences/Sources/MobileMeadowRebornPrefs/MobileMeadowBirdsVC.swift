import Preferences
import MobileMeadowRebornPrefsC

class MobileMeadowBirdsVC: PSListController {
    
    let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 150, height: 275))
    private var headerApplied = false
    
    override init(forContentSize contentSize: CGSize) {
        super.init(forContentSize: contentSize)
        
        let bannerImageView = UIImageView(frame: headerView.bounds)
        bannerImageView.contentMode = .scaleAspectFit
        bannerImageView.image = UIImage(contentsOfFile: prefsAssetsPath + "MMBirdsBanner.png")
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
        // iOS 17 兼容：使用安全方法设置 tableHeaderView
        applyHeaderView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 如果 viewDidLoad 中未能设置 header，在 viewDidAppear 中再次尝试
        if !headerApplied {
            applyHeaderView()
        }
    }
    
    private func applyHeaderView() {
        guard !headerApplied else { return }
        if safeTableView() != nil {
            setTableHeaderView(headerView)
            headerApplied = true
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self = self, !self.headerApplied else { return }
                if self.safeTableView() != nil {
                    self.setTableHeaderView(self.headerView)
                    self.headerApplied = true
                }
            }
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
