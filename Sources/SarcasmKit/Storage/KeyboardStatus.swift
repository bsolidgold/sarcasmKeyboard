import Foundation

public enum KeyboardStatus {
    public static let extensionBundleID = "com.sarcasmkeyboard.app.keyboard"
    private static let heartbeatKey = "sarcasm.keyboardHeartbeatAt"
    private static let dismissedKey = "sarcasm.dismissedSetupBanner"

    public static var isEnabledInSettings: Bool {
        guard let enabled = UserDefaults.standard.array(forKey: "AppleKeyboards") as? [String] else {
            return false
        }
        return enabled.contains(extensionBundleID)
    }

    public static var hasHeartbeat: Bool {
        SharedDefaults.defaults.object(forKey: heartbeatKey) != nil
    }

    public static func recordHeartbeat() {
        SharedDefaults.defaults.set(Date().timeIntervalSince1970, forKey: heartbeatKey)
    }

    public static var isSetupBannerDismissed: Bool {
        get { SharedDefaults.defaults.bool(forKey: dismissedKey) }
        set { SharedDefaults.defaults.set(newValue, forKey: dismissedKey) }
    }

    public static var shouldShowSetupBanner: Bool {
        if isSetupBannerDismissed { return false }
        if hasHeartbeat { return false }
        if isEnabledInSettings { return false }
        return true
    }
}
