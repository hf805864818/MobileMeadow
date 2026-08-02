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

class MMAirLayerWindow: UIWindow {
    
    private var sceneObserver: NSObjectProtocol?
    private var fallbackTimer: Timer?
    
    //MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        // 关键：设置透明背景，否则会遮挡 SpringBoard 桌面
        self.backgroundColor = .clear
        self.windowLevel = UIWindow.Level.alert - 1
        self.rootViewController = MMAirLayerViewController.shared
        
        // iOS 17 兼容：尝试连接活跃场景
        if let scene = findActiveScene() {
            self.windowScene = scene
            remLog("MMAirLayerWindow: attached to scene \(scene)")
            self.makeKeyAndVisible()
        } else {
            remLog("MMAirLayerWindow: no active scene found, registering observers...")
            // 方案1：监听 didActivateNotification（场景激活后，比 willConnect 更可靠）
            sceneObserver = NotificationCenter.default.addObserver(
                forName: UIScene.didActivateNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self,
                      self.windowScene == nil,
                      let scene = notification.object as? UIWindowScene else { return }
                self.windowScene = scene
                remLog("MMAirLayerWindow: attached to scene via didActivate observer \(scene)")
                self.makeKeyAndVisible()
                self.fallbackTimer?.invalidate()
                self.fallbackTimer = nil
                if let observer = self.sceneObserver {
                    NotificationCenter.default.removeObserver(observer)
                    self.sceneObserver = nil
                }
            }
            
            // 方案2：兜底定时器，如果 3 秒后仍未连接场景，强制尝试连接
            fallbackTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                guard let self = self, self.windowScene == nil else { return }
                if let scene = self.findActiveScene() {
                    self.windowScene = scene
                    remLog("MMAirLayerWindow: attached to scene via fallback timer \(scene)")
                    self.makeKeyAndVisible()
                } else {
                    remLog("MMAirLayerWindow: still no scene after 3s, forcing makeKeyAndVisible")
                    self.makeKeyAndVisible()
                }
            }
        }
    }
    
    private func findActiveScene() -> UIWindowScene? {
        // 优先查找前台活跃的 scene
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) {
            return scene
        }
        // 回退：使用第一个可用的 scene
        return UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
    }
    
    deinit {
        if let observer = sceneObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        fallbackTimer?.invalidate()
    }
    
    //MARK: - Overrides
    override func makeKeyAndVisible() {
        super.makeKeyAndVisible()
        remLog("MMAirLayerWindow: makeKeyAndVisible, isHidden=\(self.isHidden), windowScene=\(String(describing: self.windowScene))")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self || view == self.rootViewController?.view ? nil : view
    }
}

