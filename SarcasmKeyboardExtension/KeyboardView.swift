import SwiftUI

struct KeyboardView: View {
    let onLetter: (Character) -> Void
    let onPunctuation: (Character) -> Void
    let onSpace: () -> Void
    let onDelete: () -> Void
    let onReturn: () -> Void
    let onGlobe: () -> Void

    private let row1: [Character] = ["q","w","e","r","t","y","u","i","o","p"]
    private let row2: [Character] = ["a","s","d","f","g","h","j","k","l"]
    private let row3: [Character] = ["z","x","c","v","b","n","m"]

    var body: some View {
        VStack(spacing: 6) {
            letterRow(row1)
            letterRow(row2)
                .padding(.horizontal, 18)
            HStack(spacing: 6) {
                ForEach(Array(row3), id: \.self) { c in
                    KeyButton(label: String(c), style: .letter) { onLetter(c) }
                }
                KeyButton(label: "⌫", style: .system, action: onDelete)
                    .frame(width: 56)
            }
            HStack(spacing: 6) {
                KeyButton(label: "🌐", style: .system, action: onGlobe)
                    .frame(width: 44)
                KeyButton(label: ".", style: .system) { onPunctuation(".") }
                    .frame(width: 40)
                KeyButton(label: ",", style: .system) { onPunctuation(",") }
                    .frame(width: 40)
                KeyButton(label: "space", style: .system, action: onSpace)
                KeyButton(label: "return", style: .system, action: onReturn)
                    .frame(width: 80)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
    }

    private func letterRow(_ chars: [Character]) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(chars), id: \.self) { c in
                KeyButton(label: String(c), style: .letter) { onLetter(c) }
            }
        }
    }
}
