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

import Foundation
import MobileMeadowRebornC

class TweakPreferences {
    static let preferences = TweakPreferences()

    func createPreferences(atPath path: String) {
        let mirror = Mirror(reflecting: SettingsModel())
        var data: [String: Any] = [:]

        for child in mirror.children {
            guard let key = child.label else { return }
            data.updateValue(child.value, forKey: key)
        }

        let defaultSettings = NSDictionary(dictionary: data)
        defaultSettings.write(toFile: path, atomically: true)
    }

    func updatePreferences(atPath path: String) {
        guard let plistData: NSDictionary = NSDictionary(contentsOfFile: path) else { return }
        let plistKeys: [String] = plistData.allKeys.compactMap { $0 as? String }
        let settingsData = SettingsModel().toDictionary()

        for i in settingsData {
            if !plistKeys.contains(i.key) {
                remLog("The Key: \(i.key) don't exist! Adding to .plist...")
                plistData.setValue(i.value, forKey: i.key)
                plistData.write(toFile: path, atomically: true)
            }
        }
    }

    func loadPreferences(retryCount: Int = 0) -> SettingsModel {
        // 防止无限递归：最多重试 2 次，超过则返回默认设置
        let maxRetries = 2
        guard retryCount < maxRetries else {
            remLog("loadPreferences: max retry count (\(maxRetries)) reached, returning default settings")
            return SettingsModel()
        }

        // 使用 C 函数获取偏好文件路径，自动适配 rootless / Roothide / rootful
        let plistPath = MMGetPreferencesPath()
        remLog("loadPreferences: plistPath = \(plistPath)")
        remLog("loadPreferences: jbroot = \(MMGetJbrootPath() ?? "nil")")
        remLog("loadPreferences: file exists = \(FileManager.default.fileExists(atPath: plistPath))")

        let fileManager = FileManager()

        if let data = fileManager.contents(atPath: plistPath) {
            do {
                let settings = try PropertyListDecoder().decode(SettingsModel.self, from: data)
                remLog(settings)
                return settings
            } catch {
                remLog("Preferences Updating... (retry \(retryCount + 1)/\(maxRetries))")
                updatePreferences(atPath: plistPath)
                return loadPreferences(retryCount: retryCount + 1)
            }
        } else {
            if !fileManager.fileExists(atPath: plistPath) {
                remLog("Preferences don't exist... Creating...")
                createPreferences(atPath: plistPath)
                return loadPreferences(retryCount: retryCount + 1)
            }
        }
        return SettingsModel()
    }
}
