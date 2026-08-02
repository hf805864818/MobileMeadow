import Preferences
import MobileMeadowRebornPrefsC

@objc(MobileMeadowDuoCreditCell)
class MobileMeadowDuoCreditCell: PSTableCell {
    
    //MARK: - Propertys
    // 使用 lazy var 延迟初始化，确保在 super.init 完成之后才创建 CreditView
    // 避免在 cell 未完全初始化时进行复杂的 UIKit 操作导致 Swift 运行时陷阱
    private lazy var leftCreditCell: MobileMeadowCreditView = {
        let view = MobileMeadowCreditView(username: (user: "★\u{2002}Install\u{2002}Package\u{2002}Files", shorthand: "pkgFiles"), avatarUrlString: "1651534033019437056/BlFUdlQg_200x200.jpg")
        return view
    }()
    
    private lazy var rightCreditCell: MobileMeadowCreditView = {
        let view = MobileMeadowCreditView(username: (user: "Samperson", shorthand: "SamNChiet"), avatarUrlString: "1605080302723878912/KBQBJO5N_200x200.jpg")
        return view
    }()
    
    //MARK: - Initializer
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String, specifier: PSSpecifier) {
        // 必须调用 PSTableCell 的完整初始化器，传递 specifier
        // 否则 self.specifier 属性不会被设置，后续访问会 nil 崩溃
        super.init(style: style, reuseIdentifier: reuseIdentifier, specifier: specifier)
        
        let seperatorView: UIView = UIView()
        seperatorView.backgroundColor = UIColor.gray
        seperatorView.translatesAutoresizingMaskIntoConstraints = false
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(leftCreditCell)
        self.contentView.addSubview(seperatorView)
        self.contentView.addSubview(rightCreditCell)
        
        NSLayoutConstraint.activate([
            leftCreditCell.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            leftCreditCell.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            leftCreditCell.heightAnchor.constraint(equalTo: self.contentView.heightAnchor),
            leftCreditCell.widthAnchor.constraint(equalTo: self.contentView.widthAnchor, multiplier: 0.575),

            rightCreditCell.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            rightCreditCell.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            rightCreditCell.heightAnchor.constraint(equalTo: self.contentView.heightAnchor),
            rightCreditCell.widthAnchor.constraint(equalTo: self.contentView.widthAnchor, multiplier: 0.425),

            seperatorView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            seperatorView.leadingAnchor.constraint(equalTo: self.leftCreditCell.trailingAnchor, constant: 2.5),
            seperatorView.heightAnchor.constraint(equalTo: self.contentView.heightAnchor, multiplier: 0.7),
            seperatorView.widthAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}