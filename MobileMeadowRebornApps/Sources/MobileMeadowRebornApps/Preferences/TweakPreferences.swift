import Foundation

class TweakPreferences {
    static let preferences = TweakPreferences()
    
    func loadPreferences(retryCount: Int = 0) -> SettingsModel {
        // 防止无限递归：最多重试 2 次，超过则返回默认设置
        let maxRetries = 2
        guard retryCount < maxRetries else {
            remLog("loadPreferences: max retry count (\(maxRetries)) reached, returning default settings")
            return SettingsModel()
        }

        let fileManager = FileManager()
        let plistIdentifier: String = "com.pkgfiles.mobilemeadowrebornprefs.plist"
        let plistPath: String = fileManager.fileExists(atPath: "/var/jb/")
            ? "/var/jb/var/mobile/Library/Preferences/" + plistIdentifier
            : "/var/mobile/Library/Preferences/" + plistIdentifier
        
        if let data = fileManager.contents(atPath: plistPath) {
            remLog(Bundle.main.bundleIdentifier ?? "No bundleIdentifier found")
            do {
                let settings = try PropertyListDecoder().decode(SettingsModel.self, from: data)
                return settings
            } catch let error as NSError {
                remLog("\(error.localizedDescription) (retry \(retryCount + 1)/\(maxRetries))")
                return loadPreferences(retryCount: retryCount + 1)
            }
        } else { remLog("No preference data found!") }
        return SettingsModel()
    }
}
