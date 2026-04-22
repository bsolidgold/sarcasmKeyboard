import SwiftUI
import SarcasmKit

struct KeyboardView: View {
    let onLetter: (Character) -> Void
    let onPunctuation: (Character) -> Void
    let onSpace: () -> Void
    let onDelete: () -> Void
    let onReturn: () -> Void
    let onCyclePattern: () -> Void
    let currentPattern: any SarcasmPattern
    let palette: Palette

    @State private var layout: Layout = .letters

    private enum Layout {
        case letters, numbers, symbols
    }

    // Letters (QWERTY — no shift, see product note)
    private let lettersRow1: [Character] = ["q","w","e","r","t","y","u","i","o","p"]
    private let lettersRow2: [Character] = ["a","s","d","f","g","h","j","k","l"]
    private let lettersRow3: [Character] = ["z","x","c","v","b","n","m"]

    // Numbers (123)
    private let numbersRow1: [Character] = ["1","2","3","4","5","6","7","8","9","0"]
    private let numbersRow2: [Character] = ["-","/",":",";","(",")","$","&","@","\""]
    // Row 3 of numbers + symbols share these punctuation keys.
    private let punctRow3:   [Character] = [".",",","?","!","'"]

    // Symbols (#+=)
    private let symbolsRow1: [Character] = ["[","]","{","}","#","%","^","*","+","="]
    private let symbolsRow2: [Character] = ["_","\\","|","~","<",">","€","£","¥","•"]

    var body: some View {
        VStack(spacing: 0) {
            ActivePatternStrip(pattern: currentPattern, palette: palette, onTap: onCyclePattern)
            keyRows
        }
        .background(palette.ink)
    }

    @ViewBuilder private var keyRows: some View {
        VStack(spacing: 6) {
            switch layout {
            case .letters: lettersLayout
            case .numbers: numbersLayout
            case .symbols: symbolsLayout
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
    }

    // MARK: Layouts

    @ViewBuilder private var lettersLayout: some View {
        letterRow(lettersRow1)
        letterRow(lettersRow2)
            .padding(.horizontal, 18)
        HStack(spacing: 6) {
            ForEach(Array(lettersRow3), id: \.self) { c in
                KeyButton(label: String(c), style: .letter, palette: palette) { onLetter(c) }
            }
            KeyButton(icon: "delete.left", style: .system, palette: palette, action: onDelete)
                .frame(width: 56)
        }
        bottomRow(switcherLabel: "123") { layout = .numbers }
    }

    @ViewBuilder private var numbersLayout: some View {
        charRow(numbersRow1, transform: false)
        charRow(numbersRow2, transform: false)
        HStack(spacing: 6) {
            KeyButton(label: "#+=", style: .system, palette: palette) { layout = .symbols }
                .frame(width: 56)
            ForEach(Array(punctRow3), id: \.self) { c in
                KeyButton(label: String(c), style: .letter, palette: palette) { onPunctuation(c) }
            }
            KeyButton(icon: "delete.left", style: .system, palette: palette, action: onDelete)
                .frame(width: 56)
        }
        bottomRow(switcherLabel: "ABC") { layout = .letters }
    }

    @ViewBuilder private var symbolsLayout: some View {
        charRow(symbolsRow1, transform: false)
        charRow(symbolsRow2, transform: false)
        HStack(spacing: 6) {
            KeyButton(label: "123", style: .system, palette: palette) { layout = .numbers }
                .frame(width: 56)
            ForEach(Array(punctRow3), id: \.self) { c in
                KeyButton(label: String(c), style: .letter, palette: palette) { onPunctuation(c) }
            }
            KeyButton(icon: "delete.left", style: .system, palette: palette, action: onDelete)
                .frame(width: 56)
        }
        bottomRow(switcherLabel: "ABC") { layout = .letters }
    }

    // MARK: Row helpers

    private func letterRow(_ chars: [Character]) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(chars), id: \.self) { c in
                KeyButton(label: String(c), style: .letter, palette: palette) { onLetter(c) }
            }
        }
    }

    /// Row of characters inserted raw (no sarcasm transform). Used by numbers/symbols.
    private func charRow(_ chars: [Character], transform: Bool) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(chars), id: \.self) { c in
                KeyButton(label: String(c), style: .letter, palette: palette) {
                    transform ? onLetter(c) : onPunctuation(c)
                }
            }
        }
    }

    private func bottomRow(switcherLabel: String, switcherAction: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            KeyButton(label: switcherLabel, style: .system, palette: palette, action: switcherAction)
                .frame(width: 64)
            KeyButton(label: "space", style: .system, palette: palette, action: onSpace)
            KeyButton(label: "return", style: .system, palette: palette, action: onReturn)
                .frame(width: 80)
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
