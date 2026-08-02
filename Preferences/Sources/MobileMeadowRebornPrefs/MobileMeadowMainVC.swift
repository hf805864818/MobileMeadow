import Preferences
import MobileMeadowRebornPrefsC

class MobileMeadowMainVC: PSListController {

    let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 225))
    private var headerApplied = false

    override init(forContentSize contentSize: CGSize) {
        super.init(forContentSize: contentSize)

        if #available(iOS 13.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.triangle.2.circlepath.circle.fill"), style: .plain, target: self, action: #selector(respringDevice))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Respring", style: .plain, target: self, action: #selector(respringDevice))
        }

        let bannerImageView = UIImageView(frame: headerView.bounds)
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.image = UIImage(contentsOfFile: prefsAssetsPath + "MMBanner.png")
        bannerImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(bannerImageView)

        // 版本号标签 — 显示在 header 底部
        let versionLabel = UILabel()
        versionLabel.text = "MobileMeadow Reborn \(PrefsVersion.displayVersion)"
        versionLabel.font = .systemFont(ofSize: 11, weight: .medium)
        versionLabel.textColor = .white
        versionLabel.alpha = 0.8
        versionLabel.textAlignment = .center
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(versionLabel)

        NSLayoutConstraint.activate([
            bannerImageView.topAnchor.constraint(equalTo: headerView.topAnchor),
            bannerImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            bannerImageView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            bannerImageView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),

            versionLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
            versionLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
            versionLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // iOS 17 兼容：使用安全方法设置 tableHeaderView
        // 完全不使用 KVC，避免 valueForUndefinedKey: 崩溃
        applyHeaderView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 如果 viewDidLoad 中未能设置 header（tableView 尚未创建），
        // 在 viewDidAppear 中再次尝试
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
            // tableView 尚未加载，延迟重试
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

    //MARK: - Actions
    @objc func respringDevice() {
        respring()
    }

    //MARK: - Required
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
}
