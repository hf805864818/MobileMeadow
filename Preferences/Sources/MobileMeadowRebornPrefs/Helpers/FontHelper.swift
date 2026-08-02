import UIKit

/// 创建一个带自定义字体路径的 UILabel
/// 如果字体文件不存在或加载失败，回退到系统字体
func createLabelWithCustomFont(text: String, fontSize: CGFloat) -> UILabel {
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    label.text = text

    let ttfName: String = "OpenDyslexic3-Regular.ttf"
    let fontPath = prefsAssetsPath + "Fonts/\(ttfName)"

    if FileManager.default.fileExists(atPath: fontPath) {
        let fontURL = URL(fileURLWithPath: fontPath)
        if let dataProvider = CGDataProvider(url: fontURL as CFURL),
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
        label.font = .systemFont(ofSize: fontSize, weight: .medium)
    }

    label.textColor = UIColor.label
    return label
}