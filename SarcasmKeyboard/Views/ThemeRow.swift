import SwiftUI
import SarcasmKit

struct ThemeRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let theme: Theme
    let isSelected: Bool

    private var accent: Color { Palette.default.accent(for: colorScheme) }

    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            ZStack {
                Circle()
                    .fill(isSelected ? accent.opacity(0.15) : Color(.tertiarySystemFill))
                    .frame(width: 28, height: 28)
                Image(systemName: isSelected ? "checkmark" : "paintpalette")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? accent : Color.secondary)
            }

            // Name + lock badge
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(theme.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    if theme.isPremium {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                }
                Text(theme.id == "cleanLight" || theme.id == "paper"
                     ? "light keyboard"
                     : "dark keyboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            // Mini palette preview
            MiniPalettePreview(palette: theme.palette)
        }
        .contentShape(Rectangle())
    }
}

private struct MiniPalettePreview: View {
    let palette: Palette

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(palette.ink)
            .frame(width: 52, height: 30)
            .overlay {
                HStack(spacing: 3) {
                    // Two mock key shapes showing keyFill and accent text
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(palette.keyFill)
                        .frame(width: 18, height: 20)
                        .overlay {
                            Text("A")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(palette.text)
                        }
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(palette.keyFill)
                        .frame(width: 18, height: 20)
                        .overlay {
                            Text("b")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(palette.accent)
                        }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
    }
}
