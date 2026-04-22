import SwiftUI
import SarcasmKit

struct KeyboardView: View {
    let onLetter: (Character) -> Void
    let onPunctuation: (Character) -> Void
    let onSpace: () -> Void
    let onDelete: () -> Void
    let onReturn: () -> Void
    let onGlobe: () -> Void
    let onCyclePattern: () -> Void
    let currentPattern: any SarcasmPattern
    let palette: Palette

    private let row1: [Character] = ["q","w","e","r","t","y","u","i","o","p"]
    private let row2: [Character] = ["a","s","d","f","g","h","j","k","l"]
    private let row3: [Character] = ["z","x","c","v","b","n","m"]

    var body: some View {
        VStack(spacing: 0) {
            ActivePatternStrip(pattern: currentPattern, palette: palette, onTap: onCyclePattern)
            keyRows
        }
        .background(palette.ink)
    }

    private var keyRows: some View {
        VStack(spacing: 6) {
            letterRow(row1)
            letterRow(row2)
                .padding(.horizontal, 18)
            HStack(spacing: 6) {
                ForEach(Array(row3), id: \.self) { c in
                    KeyButton(label: String(c), style: .letter, palette: palette) { onLetter(c) }
                }
                KeyButton(label: "⌫", style: .system, palette: palette, action: onDelete)
                    .frame(width: 56)
            }
            HStack(spacing: 6) {
                KeyButton(label: "🌐", style: .system, palette: palette, action: onGlobe)
                    .frame(width: 44)
                KeyButton(label: ".", style: .system, palette: palette) { onPunctuation(".") }
                    .frame(width: 40)
                KeyButton(label: ",", style: .system, palette: palette) { onPunctuation(",") }
                    .frame(width: 40)
                KeyButton(label: "space", style: .system, palette: palette, action: onSpace)
                KeyButton(label: "return", style: .system, palette: palette, action: onReturn)
                    .frame(width: 80)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
    }

    private func letterRow(_ chars: [Character]) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(chars), id: \.self) { c in
                KeyButton(label: String(c), style: .letter, palette: palette) { onLetter(c) }
            }
        }
    }
}

private struct ActivePatternStrip: View {
    let pattern: any SarcasmPattern
    let palette: Palette
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text("•")
                    .font(.sarcasmMonoSmall)
                    .foregroundStyle(palette.accent)
                Text(pattern.transform(pattern.displayName))
                    .font(.sarcasmMonoSmall)
                    .foregroundStyle(palette.accent)
                Text("▾")
                    .font(.sarcasmMonoSmall)
                    .foregroundStyle(palette.accent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(
                ZStack {
                    palette.ink
                    if isPressed {
                        palette.accent.opacity(0.15)
                    }
                    VStack {
                        palette.accent.frame(height: 1)
                        Spacer()
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
