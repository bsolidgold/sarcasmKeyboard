import SwiftUI
import SarcasmKit

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ProStore.self) private var store
    @State private var showInstallGuide = false
    @State private var showDarkModeUpsell = false
    @State private var showError = false

    private var accent: Color { Palette.default.accent(for: colorScheme) }
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        List {
            if !store.isPro {
                proSection
            }
            appearanceSection
            keyboardSection
            aboutSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showInstallGuide) { InstallGuideSheet() }
        .sheet(isPresented: $showDarkModeUpsell) { ProUpsellSheet(featureName: "Dark Mode") }
        .alert(
            "Something went sideways",
            isPresented: $showError,
            presenting: store.lastError
        ) { _ in
            Button("OK", role: .cancel) { store.lastError = nil }
        } message: { err in
            Text(err)
        }
        .tint(accent)
    }

    // MARK: - Pro Section

    private var proSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(accent)
                        .frame(width: 44, height: 44)
                        .background(accent.opacity(0.15), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sarcasm Keyboard Pro")
                            .font(.headline)
                        Text("All patterns, themes & unlimited history")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Button {
                    Task {
                        let ok = await store.purchase()
                        if !ok && store.lastError != nil { showError = true }
                    }
                } label: {
                    ZStack {
                        Text(store.product.map { "Unlock for \($0.displayPrice)" } ?? "Unlock Pro")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .opacity(store.purchaseInFlight ? 0 : 1)
                        if store.purchaseInFlight { ProgressView().scaleEffect(0.8) }
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(store.purchaseInFlight || store.product == nil)

                Button("Restore Purchase") {
                    Task {
                        let ok = await store.restore()
                        if !ok && store.lastError != nil { showError = true }
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(store.purchaseInFlight)
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section("Appearance") {
            Button {
                if store.isPro {
                    withAnimation(.bouncy) { store.isDarkMode.toggle() }
                } else {
                    showDarkModeUpsell = true
                }
            } label: {
                HStack {
                    Label(
                        store.isDarkMode ? "Dark Mode" : "Light Mode",
                        systemImage: store.isDarkMode ? "moon.fill" : "moon"
                    )
                    .foregroundStyle(.primary)
                    Spacer()
                    if store.isPro {
                        Toggle("", isOn: Binding(
                            get: { store.isDarkMode },
                            set: { newValue in
                                withAnimation(.bouncy) { store.isDarkMode = newValue }
                            }
                        ))
                        .labelsHidden()
                        .tint(accent)
                    } else {
                        HStack(spacing: 4) {
                            Text("Pro")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(accent)
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Keyboard Section

    private var keyboardSection: some View {
        Section("Keyboard") {
            Button {
                showInstallGuide = true
            } label: {
                Label("Install Guide", systemImage: "keyboard.badge.ellipsis")
                    .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            if let url = URL(string: "https://sarcasmkeyboard.app/privacy") {
                Link(destination: url) {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                }
            }
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text(version)
                    .foregroundStyle(.secondary)
                    .font(.callout.monospacedDigit())
            }
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(ProStore())
}
