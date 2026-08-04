import Foundation
import MobileMeadowRebornAppsC

class TweakPreferences {
    static let preferences = TweakPreferences()

    func loadPreferences(retryCount: Int = 0) -> SettingsModel {
        let maxRetries = 2
        guard retryCount < maxRetries else {
            remLog("loadPreferences: max retry count (\(maxRetries)) reached, returning default settings")
            return SettingsModel()
        }

        let plistPath = MMGetPreferencesPath()
        remLog("loadPreferences: plistPath = \(plistPath)")

        let fileManager = FileManager()
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
