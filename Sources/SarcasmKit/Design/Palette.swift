import SwiftUI

public struct Palette: Sendable, Equatable {
    // Keyboard (always dark)
    public let ink: Color              // #0A0A0A — keyboard background, app dark-mode background
    public let keyFill: Color          // #1C1C1E — letter keys
    public let systemKeyFill: Color    // #2C2C2E — shift/space/return/delete
    public let topHighlight: Color     // #3A3A3C — 1px highlight on the top edge of keys
    public let accent: Color           // #B8FF2A — lime for use on dark surfaces
    public let accentOnLight: Color    // #3F7A00 — deeper lime for use on light surfaces (WCAG AA on white)

    // Text (on dark surfaces)
    public let text: Color             // #F2F2F7 — primary on dark
    public let subtleText: Color       // #8E8E93 — secondary on dark

    public init(
        ink: Color,
        keyFill: Color,
        systemKeyFill: Color,
        topHighlight: Color,
        accent: Color,
        accentOnLight: Color,
        text: Color,
        subtleText: Color
    ) {
        self.ink = ink
        self.keyFill = keyFill
        self.systemKeyFill = systemKeyFill
        self.topHighlight = topHighlight
        self.accent = accent
        self.accentOnLight = accentOnLight
        self.text = text
        self.subtleText = subtleText
    }

    public static var `default`: Palette { ThemeCatalog.acid.palette }
}

extension Palette {
    /// Returns the accent appropriate for the current color scheme — bright lime
    /// on dark surfaces, deeper lime on light surfaces for readable contrast.
    public func accent(for scheme: ColorScheme) -> Color {
        scheme == .dark ? accent : accentOnLight
    }
}

extension Color {
    public init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex & 0xFF0000) >> 16) / 255
        let g = Double((hex & 0x00FF00) >> 8) / 255
        let b = Double(hex & 0x0000FF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
