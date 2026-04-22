import SwiftUI
import SarcasmKit

struct KeyButton: View {
    enum Style {
        case letter
        case system
    }

    enum Content {
        case text(String)
        case icon(String) // SF Symbol name
    }

    let content: Content
    let style: Style
    let palette: Palette
    let action: () -> Void

    @State private var isPressed = false

    init(label: String, style: Style, palette: Palette, action: @escaping () -> Void) {
        self.content = .text(label)
        self.style = style
        self.palette = palette
        self.action = action
    }

    init(icon: String, style: Style, palette: Palette, action: @escaping () -> Void) {
        self.content = .icon(icon)
        self.style = style
        self.palette = palette
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            labelView
                .foregroundColor(palette.text)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(isPressed ? palette.accent.opacity(0.30) : backgroundColor)
                        VStack(spacing: 0) {
                            palette.topHighlight
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

    @ViewBuilder private var labelView: some View {
        switch content {
        case .text(let str):
            Text(str)
                .font(style == .letter ? .sarcasmMono : .sarcasmMonoSmall)
        case .icon(let name):
            Image(systemName: name)
                .font(.system(size: 18, weight: .regular))
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .letter: return palette.keyFill
        case .system: return palette.systemKeyFill
        }
    }
}
