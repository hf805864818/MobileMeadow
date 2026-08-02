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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

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

    @objc func respringDevice() {
        respring()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
}