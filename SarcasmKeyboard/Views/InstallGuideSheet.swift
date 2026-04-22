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
                        // NOTE: openSettingsURLString is supposed to deep-link to the
                        // app's own Settings page, but on iOS 26 (and in our Simulator
                        // testing) it lands at Settings root. We have a Settings.bundle
                        // registered which is Apple's canonical requirement, but the
                        // behavior doesn't match the docs. Copy below handles landing
                        // at Settings root via Search. Revisit when testing on device
                        // or if iOS behavior changes.
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
                    Text("Apple won't let us flip the switch for you. Three taps inside Settings and you're done.")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    stepRow(
                        number: 1,
                        title: "Scroll to Apps",
                        detail: "Scroll down in Settings, tap Apps, then tap Sarcasm Keyboard.",
                        symbol: "square.grid.2x2.fill"
                    )
                    stepRow(
                        number: 2,
                        title: "Tap Keyboards",
                        detail: "From the Sarcasm Keyboard page.",
                        symbol: "keyboard"
                    )
                    stepRow(
                        number: 3,
                        title: "Toggle it on",
                        detail: "Flip the switch next to \"Sarcasm Keyboard\". That's it.",
                        symbol: "switch.2"
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
