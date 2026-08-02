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
import MobileMeadowRebornC

/// 飞鸟动画的覆盖层窗口
/// 在 iOS 17 上必须使用 init(windowScene:) 初始化，否则窗口无法关联到 Scene 而不可见
class MMAirLayerWindow: UIWindow {

    //MARK: - Initializers

    /// 使用 UIWindowScene 初始化（iOS 17 推荐方式）
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        commonInit()
        remLog("MMAirLayerWindow: init(windowScene:) with scene \(windowScene)")
    }

    /// 使用 frame 初始化（iOS 13+ 已废弃，仅作为兜底保留）
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        remLog("MMAirLayerWindow: init(frame:) — scene-less creation, window may not be visible on iOS 17")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        self.backgroundColor = .clear
        self.windowLevel = UIWindow.Level.alert - 1
        self.rootViewController = MMAirLayerViewController.shared
        remLog("MMAirLayerWindow: commonInit, windowLevel=\(self.windowLevel.rawValue), hasScene=\(self.windowScene != nil)")
    }

    deinit {
        remLog("MMAirLayerWindow: deinit")
    }

    //MARK: - Overrides

    override func makeKeyAndVisible() {
        super.makeKeyAndVisible()
        remLog("MMAirLayerWindow: makeKeyAndVisible, isHidden=\(self.isHidden), windowScene=\(String(describing: self.windowScene)), frame=\(self.frame)")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self || view == self.rootViewController?.view ? nil : view
    }
}