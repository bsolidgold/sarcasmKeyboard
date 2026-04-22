import SwiftUI
import SarcasmKit

struct KeyButton: View {
    enum Style {
        case letter
        case system
    }

    let label: String
    let style: Style
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(style == .letter ? .sarcasmMono : .sarcasmMonoSmall)
                .foregroundColor(Palette.default.text)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(isPressed ? Palette.default.accent.opacity(0.30) : backgroundColor)
                        VStack(spacing: 0) {
                            Palette.default.topHighlight
                                .frame(height: 1)
                            Color.clear
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }
                )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.08), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var backgroundColor: Color {
        switch style {
        case .letter: return Palette.default.keyFill
        case .system: return Palette.default.systemKeyFill
        }
    }
}
