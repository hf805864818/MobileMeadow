import Preferences

/// 最小化版本 - 测试用
/// 仅包含最基本的 PSListController 子类，无 header、无自定义字体、无导航栏定制
class MobileMeadowMainVC: PSListController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override init(forContentSize contentSize: CGSize) {
        super.init(forContentSize: contentSize)
    }
}