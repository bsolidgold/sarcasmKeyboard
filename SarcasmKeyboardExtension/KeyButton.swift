import SwiftUI

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
                .font(style == .letter ? .title3 : .callout)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(backgroundColor)
                        .shadow(color: .black.opacity(0.2), radius: 0, x: 0, y: 1)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeOut(duration: 0.08), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var backgroundColor: Color {
        switch style {
        case .letter: return Color(.systemBackground)
        case .system: return Color(.systemGray3)
        }
    }
}
