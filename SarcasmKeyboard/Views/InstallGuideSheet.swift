import SwiftUI
import UIKit
import SarcasmKit

struct InstallGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    stepRow(
                        number: 1,
                        title: "Open Settings",
                        detail: "General › Keyboard › Keyboards",
                        symbol: "gearshape.fill"
                    )
                    stepRow(
                        number: 2,
                        title: "Add New Keyboard",
                        detail: "Pick \"Sarcasm Keyboard\" from the list",
                        symbol: "plus.rectangle.on.rectangle"
                    )
                    stepRow(
                        number: 3,
                        title: "Allow Full Access",
                        detail: "Optional. Only needed if you want history and haptics. Nothing you type leaves your device.",
                        symbol: "lock.shield.fill"
                    )
                    stepRow(
                        number: 4,
                        title: "Tap the 🌐 globe",
                        detail: "In any app, switch keyboards until Sarcasm Keyboard appears",
                        symbol: "globe"
                    )
                } header: {
                    Text("Four steps. We regret to inform you Apple wouldn't let us do it for you.")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "arrow.up.right.square.fill")
                            .foregroundStyle(Color.accentColor)
                    }
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
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.accentColor)
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
