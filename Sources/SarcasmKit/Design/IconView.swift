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

    public var body: some View {
        ZStack {
            background
            Text("aA")
                .font(.system(size: 640, weight: .black, design: .rounded))
                .foregroundStyle(foreground)
                .tracking(-40)
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
