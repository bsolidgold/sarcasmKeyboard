import SwiftUI
import SarcasmKit

struct ContentView: View {
    @State private var selectedPatternID: String = SharedDefaults.selectedPatternID
    @State private var previewInput: String = "the quick brown fox"

    private var patterns: [any SarcasmPattern] { SarcasmEngine.allPatterns }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HowToInstallRow()
                }

                Section("Try it") {
                    TextField("Type anything", text: $previewInput, axis: .vertical)
                        .lineLimit(2...5)
                    if let pattern = SarcasmEngine.pattern(id: selectedPatternID) {
                        Text(pattern.transform(previewInput))
                            .font(.body.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Pattern") {
                    ForEach(patterns, id: \.id) { pattern in
                        PatternRow(
                            pattern: pattern,
                            isSelected: pattern.id == selectedPatternID
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { select(pattern) }
                    }
                }
            }
            .navigationTitle("Sarcasm Keyboard")
        }
    }

    private func select(_ pattern: any SarcasmPattern) {
        selectedPatternID = pattern.id
        SharedDefaults.selectedPatternID = pattern.id
    }
}

private struct PatternRow: View {
    let pattern: any SarcasmPattern
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(pattern.displayName)
                        .font(.body)
                    if pattern.isPremium {
                        Text("PRO")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.tint.opacity(0.15), in: Capsule())
                            .foregroundStyle(.tint)
                    }
                }
                Text(pattern.transform("the quick brown fox"))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            }
        }
    }
}

private struct HowToInstallRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Install the keyboard")
                .font(.headline)
            Text("1. Open Settings › General › Keyboard › Keyboards")
            Text("2. Tap \"Add New Keyboard\" and choose Sarcasm Keyboard")
            Text("3. In any app, tap the globe icon to switch to it")
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .font(.subheadline)
    }
}

#Preview {
    ContentView()
}
