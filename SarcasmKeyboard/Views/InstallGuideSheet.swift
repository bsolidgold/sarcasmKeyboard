import SwiftUI
import UIKit
import SarcasmKit

struct InstallGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var accent: Color { Palette.default.accent(for: colorScheme) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Label("Open Settings", systemImage: "arrow.up.right.square.fill")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(accent)
                            Spacer()
                        }
                    }
                } header: {
                    Text("One tap, then three more inside Settings. Apple's rules.")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    stepRow(
                        number: 1,
                        title: "Tap Keyboards",
                        detail: "You'll land on the Sarcasm Keyboard settings page.",
                        symbol: "keyboard"
                    )
                    stepRow(
                        number: 2,
                        title: "Toggle it on",
                        detail: "Flip the switch next to \"Sarcasm Keyboard\".",
                        symbol: "switch.2"
                    )
                    stepRow(
                        number: 3,
                        title: "Allow Full Access",
                        detail: "Optional. Enables history and haptics. Nothing you type leaves your device.",
                        symbol: "lock.shield.fill"
                    )
                } header: {
                    Text("Inside Settings")
                        .textCase(nil)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                Section {
                    stepRow(
                        number: 4,
                        title: "Hold the 🌐 globe",
                        detail: "In any app with a text field, hold the globe key on any keyboard and pick Sarcasm Keyboard.",
                        symbol: "globe"
                    )
                } header: {
                    Text("Then anywhere you type")
                        .textCase(nil)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
            .navigationTitle("How to install")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func stepRow(number: Int, title: String, detail: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Label {
                    Text(title)
                        .font(.body.weight(.semibold))
                } icon: {
                    Image(systemName: symbol)
                        .foregroundStyle(.secondary)
                }
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 2)
    }
}
