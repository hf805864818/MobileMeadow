import UIKit

class MobileMeadowCreditView: UIView {

    //MARK: - Variables
    let username: (user: String, shorthand: String)
    let avatarUrlString: String
    private var avatarImageView: UIImageView?
    
    //MARK: - Initializer
    init(username: (user: String, shorthand: String), avatarUrlString: String) {
        self.username = username
        self.avatarUrlString = avatarUrlString
        
        super.init(frame: .zero)
        setupCreditView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Instance Methods
    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImageView?.layer.cornerRadius = 10
        avatarImageView?.layer.masksToBounds = true
    }
    
    //MARK: - Functions
    private func setupCreditView() {
        let titleLbl = createLabelWithCustomFont(text: self.username.user, fontSize: 12)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLbl = createLabelWithCustomFont(text: "@" + self.username.shorthand, fontSize: 10)
        subtitleLbl.textColor = UIColor.gray
        subtitleLbl.translatesAutoresizingMaskIntoConstraints = false
        
        let avatarView = createAvatarImageView()
        self.avatarImageView = avatarView
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(loadTwitterPageFromString))
        self.addGestureRecognizer(recognizer)
        
        getProfilePicture(from: self.avatarUrlString)
        
        self.addSubview(avatarView)
        self.addSubview(titleLbl)
        self.addSubview(subtitleLbl)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            avatarView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            avatarView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
            avatarView.heightAnchor.constraint(equalToConstant: 40),
            avatarView.widthAnchor.constraint(equalToConstant: 40),

            titleLbl.topAnchor.constraint(equalTo: self.centerYAnchor, constant: -20),
            titleLbl.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 10),
            titleLbl.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -2.5),
            titleLbl.heightAnchor.constraint(equalToConstant: 20),
            
            subtitleLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: -3),
            subtitleLbl.leadingAnchor.constraint(equalTo: titleLbl.leadingAnchor),
            subtitleLbl.heightAnchor.constraint(equalToConstant: 20),
        ])
    }
    
    private func createAvatarImageView() -> UIImageView {
        var defaultImage: UIImage? = nil
        let iconPath = prefsAssetsPath + "Credits/DefaultIcon.png"
        if FileManager.default.fileExists(atPath: iconPath) {
            defaultImage = UIImage(contentsOfFile: iconPath)
        }
        if defaultImage == nil {
            defaultImage = UIImage(named: "DefaultIcon", in: Bundle(for: MobileMeadowMainVC.self), compatibleWith: nil)
        }
        let imageView = UIImageView(image: defaultImage ?? UIImage())
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }
    
    @objc private func loadTwitterPageFromString() {
        guard let url = URL(string: "https://twitter.com/" + username.shorthand) else { return }
        UIApplication.shared.open(url)
    }
    
    func getProfilePicture(from urlString: String) {
        guard let url = URL(string: "https://pbs.twimg.com/profile_images/" + urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.avatarImageView?.image = image
            }
        }.resume()
    }
}