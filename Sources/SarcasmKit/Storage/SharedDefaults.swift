import Foundation

public enum SharedDefaults {
    public static let appGroupIdentifier = "group.com.sarcasmkeyboard.app"

    public static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    private enum Keys {
        static let selectedPatternID = "sarcasm.selectedPatternID"
    }

    public static var selectedPatternID: String {
        get { defaults.string(forKey: Keys.selectedPatternID) ?? AlternatingPattern().id }
        set { defaults.setValue(newValue, forKey: Keys.selectedPatternID) }
    }

    public static var selectedPattern: any SarcasmPattern {
        SarcasmEngine.pattern(id: selectedPatternID) ?? AlternatingPattern()
    }
}
