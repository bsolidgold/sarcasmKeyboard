import SwiftUI

// MARK: - Theme

public struct Theme: Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let isPremium: Bool
    public let palette: Palette
}

// MARK: - ThemeCatalog

public enum ThemeCatalog {

    public static let allThemes: [Theme] = [
        acid,        // free
        cleanLight,  // free
        cleanDark,   // free
        neon,        // Pro
        vaporwave,   // Pro
        terminalGreen, // Pro
        sunset,      // Pro
        paper,       // Pro
        y2k,         // Pro
        highlighter, // Pro
    ]

    public static func theme(id: String) -> Theme? {
        allThemes.first { $0.id == id }
    }

    // MARK: Free

    public static let acid = Theme(
        id: "acid",
        displayName: "Acid",
        isPremium: false,
        palette: Palette(
            ink:             Color(hex: 0x0A0A0A),
            keyFill:         Color(hex: 0x1C1C1E),
            systemKeyFill:   Color(hex: 0x2C2C2E),
            topHighlight:    Color(hex: 0x3A3A3C),
            accent:          Color(hex: 0xB8FF2A),
            accentOnLight:   Color(hex: 0x3F7A00),
            text:            Color(hex: 0xF2F2F7),
            subtleText:      Color(hex: 0x8E8E93)
        )
    )

    public static let cleanLight = Theme(
        id: "cleanLight",
        displayName: "Clean Light",
        isPremium: false,
        palette: Palette(
            ink:             Color(hex: 0xF2F2F7),
            keyFill:         Color(hex: 0xFFFFFF),
            systemKeyFill:   Color(hex: 0xD1D1D6),
            topHighlight:    Color(hex: 0xC7C7CC),
            accent:          Color(hex: 0x3F7A00),
            accentOnLight:   Color(hex: 0x3F7A00),
            text:            Color(hex: 0x1C1C1E),
            subtleText:      Color(hex: 0x3C3C43)
        )
    )

    public static let cleanDark = Theme(
        id: "cleanDark",
        displayName: "Clean Dark",
        isPremium: false,
        palette: Palette(
            ink:             Color(hex: 0x000000),
            keyFill:         Color(hex: 0x1C1C1E),
            systemKeyFill:   Color(hex: 0x2C2C2E),
            topHighlight:    Color(hex: 0x48484A),
            accent:          Color(hex: 0x8E8E93),
            accentOnLight:   Color(hex: 0x636366),
            text:            Color(hex: 0xFFFFFF),
            subtleText:      Color(hex: 0x636366)
        )
    )

    // MARK: Pro

    public static let neon = Theme(
        id: "neon",
        displayName: "Neon",
        isPremium: true,
        palette: Palette(
            ink:             Color(hex: 0x0D0018),
            keyFill:         Color(hex: 0x1A0033),
            systemKeyFill:   Color(hex: 0x2A004D),
            topHighlight:    Color(hex: 0x3D0073),
            accent:          Color(hex: 0xFF2D8A),
            accentOnLight:   Color(hex: 0xC4005A),
            text:            Color(hex: 0xF0E6FF),
            subtleText:      Color(hex: 0x9B7BC4)
        )
    )

    public static let vaporwave = Theme(
        id: "vaporwave",
        displayName: "Vaporwave",
        isPremium: true,
        palette: Palette(
            ink:             Color(hex: 0x1A0A2E),
            keyFill:         Color(hex: 0x2D1B4E),
            systemKeyFill:   Color(hex: 0x3D2560),
            topHighlight:    Color(hex: 0x5A3880),
            accent:          Color(hex: 0x00FFDD),
            accentOnLight:   Color(hex: 0x007A6A),
            text:            Color(hex: 0xFFB8D9),
            subtleText:      Color(hex: 0x9F78B8)
        )
    )

    public static let terminalGreen = Theme(
        id: "terminalGreen",
        displayName: "Terminal Green",
        isPremium: true,
        palette: Palette(
            ink:             Color(hex: 0x000000),
            keyFill:         Color(hex: 0x001A00),
            systemKeyFill:   Color(hex: 0x002A00),
            topHighlight:    Color(hex: 0x003D00),
            accent:          Color(hex: 0x00FF41),
            accentOnLight:   Color(hex: 0x006614),
            text:            Color(hex: 0x00CC33),
            subtleText:      Color(hex: 0x006614)
        )
    )

    public static let sunset = Theme(
        id: "sunset",
        displayName: "Sunset",
        isPremium: true,
        palette: Palette(
            ink:             Color(hex: 0x0F0A00),
            keyFill:         Color(hex: 0x1E1408),
            systemKeyFill:   Color(hex: 0x2E2010),
            topHighlight:    Color(hex: 0x4A3318),
            accent:          Color(hex: 0xFF7A2A),
            accentOnLight:   Color(hex: 0xB84A00),
            text:            Color(hex: 0xF5DEB3),
            subtleText:      Color(hex: 0xA0825A)
        )
    )

    public static let paper = Theme(
        id: "paper",
        displayName: "Paper",
        isPremium: true,
        palette: Palette(
            ink:             Color(hex: 0x1C1509),
            keyFill:         Color(hex: 0xD9C9A8),
            systemKeyFill:   Color(hex: 0xC5B491),
            topHighlight:    Color(hex: 0xB8A47E),
            accent:          Color(hex: 0x4A2F00),
            accentOnLight:   Color(hex: 0x4A2F00),
            text:            Color(hex: 0x2C1A00),
            subtleText:      Color(hex: 0x6B4E2A)
        )
    )

    public static let y2k = Theme(
        id: "y2k",
        displayName: "Y2K",
        isPremium: true,
        palette: Palette(
            ink:             Color(hex: 0x0A0A12),
            keyFill:         Color(hex: 0x2A2A3A),
            systemKeyFill:   Color(hex: 0x3A3A4E),
            topHighlight:    Color(hex: 0x5A5A7A),
            accent:          Color(hex: 0x00B4FF),
            accentOnLight:   Color(hex: 0x005A8A),
            text:            Color(hex: 0xC8C8DC),
            subtleText:      Color(hex: 0x7070A0)
        )
    )

    public static let highlighter = Theme(
        id: "highlighter",
        displayName: "Highlighter",
        isPremium: true,
        palette: Palette(
            ink:             Color(hex: 0x0A0800),
            keyFill:         Color(hex: 0x1A1600),
            systemKeyFill:   Color(hex: 0x2A2400),
            topHighlight:    Color(hex: 0x3D3600),
            accent:          Color(hex: 0xFFEE00),
            accentOnLight:   Color(hex: 0x7A6600),
            text:            Color(hex: 0xFFF8E0),
            subtleText:      Color(hex: 0xA09060)
        )
    )
}
