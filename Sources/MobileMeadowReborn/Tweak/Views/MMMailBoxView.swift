/*
 
 MIT License

 Copyright (c) 2024 ★ Install Package Files

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
*/

import UIKit

class MMMailBoxView: UIView {

    //MARK: - Enums
    enum MailBoxState {
        case empty, full
        
        /// 安全获取邮箱图片，图片缺失时返回空 UIImage 而非崩溃
        fileprivate static func getMailBoxImage(for state: MailBoxState) -> UIImage {
            let imageName: String
            switch state {
            case .empty: imageName = "mailbox_empty"
            case .full: imageName = "mailbox_full"
            }
            // 使用安全加载，图片缺失时回退到空图片
            guard let image = MMAssets.imageNamed(imageName) else {
                remLog("⚠️ MailBox image '\(imageName)' not found, using placeholder")
                return UIImage()
            }
            return image.withHorizontallyFlippedOrientation()
        }
    }
    
    //MARK: - Propertys
    private let mailBoxImageView: UIImageView = {
        let mailBoxImage = UIImage()
        let imageView = UIImageView(image: mailBoxImage)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let mailBoxBirdImageView: UIImageView = {
        // 安全加载 deliverybird_ground 图片，缺失时使用空图片
        let birdImage = MMAssets.imageNamed("deliverybird_ground")?.withHorizontallyFlippedOrientation() ?? UIImage()
        if MMAssets.imageNamed("deliverybird_ground") == nil {
            remLog("⚠️ deliverybird_ground image not found, using placeholder")
        }
        let imageView = UIImageView(image: birdImage)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let mailBoxIconImageView: UIImageView = {
        let imageView = UIImageView(image: MMAssets.imageNamed("mail_icon"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [mailBoxBirdImageView, mailBoxImageView])
        view.alignment = .fill
        view.distribution = .fillProportionally
        view.axis = .vertical
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    //MARK: - Variables
    ///MMMailBoxView
    var isDeliveryBirdLanded: Bool = false
    
    ///Preferences
    let iconType = PreferenceCollection.MailBoxIconType.getIconType()
    
    //MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)
        self.addSubview(mailBoxIconImageView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            mailBoxIconImageView.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            mailBoxIconImageView.widthAnchor.constraint(equalToConstant: mailBoxIconImageView.image?.size.width ?? 26),
            mailBoxIconImageView.heightAnchor.constraint(equalToConstant: mailBoxIconImageView.image?.size.height ?? 26),
            mailBoxIconImageView.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: iconType == .defaultIcon ? 5 : 0),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Functions
    func handleState(_ state: MailBoxState) {
        if state == .empty {
            mailBoxImageView.image = MailBoxState.getMailBoxImage(for: .empty)
            mailBoxIconImageView.isHidden = true
            mailBoxBirdImageView.isHidden = true
            isDeliveryBirdLanded = false
        } else {
            mailBoxImageView.image = MailBoxState.getMailBoxImage(for: .full)
            mailBoxIconImageView.isHidden = false
            mailBoxBirdImageView.isHidden = false
            isDeliveryBirdLanded = true
        }
    }
}
