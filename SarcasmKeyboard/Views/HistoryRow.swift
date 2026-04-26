import SwiftUI
import SarcasmKit

struct HistoryRow: View {
    let entry: HistoryEntry

    private static let dateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    private var patternDisplayName: String {
        SarcasmEngine.pattern(id: entry.patternID)?.displayName ?? entry.patternID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.output)
                .font(.sarcasmMono)
                .lineLimit(2)
                .truncationMode(.tail)
                .foregroundStyle(.primary)
            HStack(spacing: 6) {
                Text(Self.dateFormatter.localizedString(for: entry.createdAt, relativeTo: Date()))
                Text("·")
                Text(patternDisplayName)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
