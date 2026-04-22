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

    /// Renders the literal output of AlternatingPattern on "sarcastic",
    /// split into three rows of three — so the icon IS the product's output
    /// on the product's name.
    private static let rows: [String] = {
        let transformed = AlternatingPattern().transform("sarcastic")  // "sArCaStIc"
        return [
            String(transformed.prefix(3)),
            String(transformed.dropFirst(3).prefix(3)),
            String(transformed.dropFirst(6).prefix(3))
        ]
    }()

    public var body: some View {
        ZStack {
            background
            VStack(spacing: -40) {
                ForEach(Self.rows, id: \.self) { row in
                    Text(row)
                        .font(.system(size: 340, weight: .black, design: .rounded))
                        .foregroundStyle(foreground)
                        .tracking(-18)
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
