import UIKit

extension UILabel {
    func createLabelWithFontPath(text: String, fontSize: CGFloat) -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        label.text = text

        // 尝试从 bundle 加载自定义字体，失败则回退到系统字体
        let ttfName: String = "OpenDyslexic3-Regular.ttf"
        let fontPath = prefsAssetsPath + "Fonts/\(ttfName)"

        if FileManager.default.fileExists(atPath: fontPath) {
            // 使用 CTFontManager 安全加载字体（避免 ObjC 异常）
            if let fontURL = URL(string: fontPath),
               let dataProvider = CGDataProvider(url: fontURL as CFURL),
               let cgFont = CGFont(dataProvider) {
                var error: Unmanaged<CFError>?
                CTFontManagerRegisterGraphicsFont(cgFont, &error)
                if let psName = cgFont.postScriptName as String? {
                    label.font = UIFont(name: psName, size: fontSize) ?? .systemFont(ofSize: fontSize, weight: .medium)
                } else {
                    label.font = .systemFont(ofSize: fontSize, weight: .medium)
                }
            } else {
                label.font = .systemFont(ofSize: fontSize, weight: .medium)
            }
        } else {
            // 字体文件不存在，回退到系统字体
            label.font = .systemFont(ofSize: fontSize, weight: .medium)
        }

        label.textColor = traitCollection.userInterfaceStyle == .light ? UIColor.black : UIColor.white

        return label
    }
}
