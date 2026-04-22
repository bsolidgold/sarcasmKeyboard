import SwiftUI
import SarcasmKit

struct PatternRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let pattern: any SarcasmPattern
    let isSelected: Bool

    private let sampleText = "The quick brown fox jumps"
    private var accent: Color { Palette.default.accent(for: colorScheme) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isSelected ? accent.opacity(0.15) : Color(.tertiarySystemFill))
                    .frame(width: 28, height: 28)
                Image(systemName: isSelected ? "checkmark" : symbolName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? accent : .secondary)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(pattern.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    if pattern.isPremium {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                }
                Text(pattern.transform(sampleText))
                    .font(.sarcasmMonoSmall)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }

    private var symbolName: String {
        switch pattern.id {
        case "alternating": return "character.cursor.ibeam"
        case "spongebob": return "face.smiling"
        case "random": return "dice"
        case "wordToggle": return "textformat"
        case "smallCaps": return "textformat.size.smaller"
        case "zalgo": return "sparkles"
        default: return "character"
        }
    }
}
