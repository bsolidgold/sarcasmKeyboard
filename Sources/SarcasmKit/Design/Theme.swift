import SwiftUI

public struct Theme: Sendable, Equatable {
    public let id: String
    public let displayName: String
    public let palette: Palette
    public let radii: Radii
    public let borders: Borders
    public let shadow: Shadow

    public init(
        id: String,
        displayName: String,
        palette: Palette,
        radii: Radii = .chunky,
        borders: Borders = .sticker,
        shadow: Shadow = .hard
    ) {
        self.id = id
        self.displayName = displayName
        self.palette = palette
        self.radii = radii
        self.borders = borders
        self.shadow = shadow
    }
}

extension Theme {
    public struct Palette: Sendable, Equatable {
        public let primary: Color
        public let accent: Color
        public let highlight: Color
        public let ink: Color
        public let paper: Color
        public let subtleText: Color

        public init(primary: Color, accent: Color, highlight: Color, ink: Color, paper: Color, subtleText: Color) {
            self.primary = primary
            self.accent = accent
            self.highlight = highlight
            self.ink = ink
            self.paper = paper
            self.subtleText = subtleText
        }
    }

    public struct Radii: Sendable, Equatable {
        public let card: CGFloat
        public let button: CGFloat
        public let pill: CGFloat

        public static let chunky = Radii(card: 14, button: 10, pill: 999)
        public static let none = Radii(card: 0, button: 0, pill: 0)
    }

    public struct Borders: Sendable, Equatable {
        public let thick: CGFloat
        public let hairline: CGFloat

        public static let sticker = Borders(thick: 2, hairline: 1)
        public static let hairline = Borders(thick: 1, hairline: 1)
    }

    public struct Shadow: Sendable, Equatable {
        public let color: Color
        public let offset: CGSize
        public let radius: CGFloat

        public static let hard = Shadow(color: .black, offset: CGSize(width: 3, height: 3), radius: 0)
        public static let none = Shadow(color: .clear, offset: .zero, radius: 0)
    }
}

extension Theme {
    public static let terminal = Theme(
        id: "terminal",
        displayName: "terminal",
        palette: Palette(
            primary: Color(hex: 0x33FF66),
            accent: Color(hex: 0xFFB000),
            highlight: Color(hex: 0x1E293B),
            ink: Color(hex: 0xF8FAFC),
            paper: Color(hex: 0x020617),
            subtleText: Color(hex: 0x64748B)
        ),
        radii: .none,
        borders: .hairline,
        shadow: .none
    )

    public static let memeMax = Theme(
        id: "memeMax",
        displayName: "Meme-Max",
        palette: Palette(
            primary: Color(hex: 0xF5D547),
            accent: Color(hex: 0xE06A7A),
            highlight: Color(hex: 0xD4E05C),
            ink: Color(hex: 0x1C1C1C),
            paper: Color(hex: 0xFFF5DA),
            subtleText: Color(hex: 0x6E6E6E)
        )
    )
}

extension Color {
    public init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex & 0xFF0000) >> 16) / 255
        let g = Double((hex & 0x00FF00) >> 8) / 255
        let b = Double(hex & 0x0000FF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
