import Foundation

public enum SharedDefaults {
    public static let appGroupIdentifier = "group.com.sarcasmkeyboard.app"

    public static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    private enum Keys {
        static let selectedPatternID = "sarcasm.selectedPatternID"
        static let selectedThemeID   = "sarcasm.selectedThemeID"
        static let isPro             = "sarcasm.isPro"
    }

    // MARK: Pattern

    public static var selectedPatternID: String {
        get { defaults.string(forKey: Keys.selectedPatternID) ?? AlternatingPattern().id }
        set { defaults.setValue(newValue, forKey: Keys.selectedPatternID) }
    }

    public static var selectedPattern: any SarcasmPattern {
        SarcasmEngine.pattern(id: selectedPatternID) ?? AlternatingPattern()
    }

    // MARK: Theme

    public static var selectedThemeID: String {
        get { defaults.string(forKey: Keys.selectedThemeID) ?? ThemeCatalog.acid.id }
        set { defaults.setValue(newValue, forKey: Keys.selectedThemeID) }
    }

    public static var selectedTheme: Theme {
        ThemeCatalog.theme(id: selectedThemeID) ?? ThemeCatalog.acid
    }

    // MARK: Pro entitlement
    //
    // Written by the app after StoreKit validates Transaction.currentEntitlements.
    // Read by both the app (for gating) and the keyboard extension (for
    // premium pattern/theme fallback on refund/revoke). Extensions cannot
    // initiate purchases, so they only ever read this flag.

    public static var isPro: Bool {
        get { defaults.bool(forKey: Keys.isPro) }
        set { defaults.setValue(newValue, forKey: Keys.isPro) }
    }
}
