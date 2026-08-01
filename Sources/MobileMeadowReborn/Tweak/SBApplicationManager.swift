/*

 MIT License

 Copyright (c) 2024 ★ Install Package Files

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:

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

import Orion
import MobileMeadowRebornC

class SBApplicationManager {

    //MARK: - Variables
    static let shared = SBApplicationManager()

    var result: [(icon: UIImage, name: String, badgeValue: Int)] = []
    private let appController = SBApplicationController.sharedInstance()
    private var allApps: NSArray {
        guard let applications = appController?.allApplications() as? NSArray else { return [] }
        return applications
    }

    //MARK: - Initializer
    private init() {}

    //MARK: - Functions
    func getBadgeValues(_ completion: @escaping (Result<[(icon: UIImage, name: String, badgeValue: Int)], Error>) -> Void) {
        result.removeAll()

        // iOS 17 防御性检查：SBApplicationController 可能不存在或返回 nil
        guard appController != nil else {
            completion(.success(result))
            return
        }

        for app in allApps {
            guard let currentApplication = app as? SBApplication else { continue }
            guard let bundleIdentifier = currentApplication.bundleIdentifier() else { continue }
            guard let badgeValue = currentApplication.badgeValue() as? Int else { continue }

            if let applicationName = currentApplication.displayName() {
                if let iconImage = UIImage._applicationIconImage(forBundleIdentifier: bundleIdentifier, format: 0, scale: UIScreen.main.scale) as? UIImage {
                    // iOS 17 防御性检查：BBServer/BBSectionInfo 可能已变更
                    let savedInfo = BBServer.savedSectionInfo()
                    if let sectionInfo = savedInfo?[bundleIdentifier] as? BBSectionInfo {
                        let notifSettings: BBSectionInfoSettings = sectionInfo.readableSettings
                        if notifSettings.allowsNotifications {
                            result.append((iconImage, applicationName, badgeValue))
                        }
                    } else {
                        // BBSectionInfo 不可用时，直接添加（不过滤通知权限）
                        result.append((iconImage, applicationName, badgeValue))
                    }
                }
            }
        }

        remLog(result)
        completion(.success(result))
    }
}
