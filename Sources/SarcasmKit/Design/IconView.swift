import SwiftUI

public struct IconView: View {
    public enum Variant {
        case primary    // lime on ink — default home-screen icon
        case tinted     // white on transparent — iOS 18 tinted mode
    }

    public let variant: Variant

    public init(variant: Variant = .primary) {
        self.variant = variant
    }

    /// Three rows of three, spelling "sarcastic" in alternating case. The
    /// casing breaks the strict alternation on the last row (`TiC` rather than
    /// the algorithm's `tIc`) so the lowercase `i` — with its visible dot —
    /// doesn't read as an `l` at home-screen scale.
    private static let rows: [(text: String, tracking: CGFloat)] = [
        ("sAr", -24),
        ("CaS", -24),
        ("TiC", -18)
    ]

    public var body: some View {
        ZStack {
            background
            VStack(spacing: -180) {
                ForEach(Self.rows, id: \.text) { row in
                    Text(row.text)
                        .font(.system(size: 400, weight: .black, design: .rounded))
                        .foregroundStyle(foreground)
                        .tracking(row.tracking)
                }
            }
        }
        .frame(width: 1024, height: 1024)
    }

    @ViewBuilder private var background: some View {
        switch variant {
        case .primary: Palette.default.ink
        case .tinted:  Color.clear
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary: Palette.default.accent
        case .tinted:  .white
        }
    }
}

#Preview("Primary") { IconView().frame(width: 256, height: 256).scaleEffect(0.25) }
#Preview("Tinted")  { IconView(variant: .tinted).frame(width: 256, height: 256).scaleEffect(0.25) }
