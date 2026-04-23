import SwiftUI
import SarcasmKit

struct ProUpsellSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ProStore.self) private var store
    private var accent: Color { Palette.default.accent(for: colorScheme) }

    private let lockedItemName: String
    @State private var showError = false

    // MARK: Inits

    init(lockedPattern: any SarcasmPattern) {
        self.lockedItemName = lockedPattern.displayName
    }

    init(lockedTheme: Theme) {
        self.lockedItemName = lockedTheme.displayName
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(accent)
                            .padding(.top, 20)
                        Text("Sarcasm Keyboard Pro")
                            .font(.largeTitle.weight(.bold))
                        Text("because the free ones aren't quite enough to ruin your relationships")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    VStack(spacing: 12) {
                        featureRow(
                            icon: "paintpalette.fill",
                            title: "Premium themes",
                            detail: "Neon, Vaporwave, Terminal, and more"
                        )
                        featureRow(
                            icon: "textformat.size",
                            title: "Premium patterns",
                            detail: "ꜱᴍᴀʟʟ ᴄᴀᴘꜱ and Z̊ä̶l̈g̃ȯ unlocked"
                        )
                        featureRow(
                            icon: "clock.arrow.circlepath",
                            title: "Unlimited history",
                            detail: "Keep everything you've typed (on-device only)"
                        )
                    }
                    .padding(.horizontal)

                    VStack(spacing: 10) {
                        Button {
                            Task { await runPurchase() }
                        } label: {
                            ZStack {
                                Text(unlockTitle)
                                    .font(.headline)
                                    .opacity(store.purchaseInFlight ? 0 : 1)
                                if store.purchaseInFlight {
                                    ProgressView()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(store.purchaseInFlight || store.product == nil)

                        Button("Restore Purchase") {
                            Task { await runRestore() }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .disabled(store.purchaseInFlight)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(lockedItemName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert(
                "Something went sideways",
                isPresented: $showError,
                presenting: store.lastError
            ) { _ in
                Button("OK", role: .cancel) { store.lastError = nil }
            } message: { err in
                Text(err)
            }
        }
    }

    private var unlockTitle: String {
        if let price = store.product?.displayPrice {
            return "Unlock for \(price)"
        }
        return "Unlock Pro"
    }

    private func runPurchase() async {
        let ok = await store.purchase()
        if ok {
            dismiss()
        } else if store.lastError != nil {
            showError = true
        }
    }

    private func runRestore() async {
        let ok = await store.restore()
        if ok {
            dismiss()
        } else if store.lastError != nil {
            showError = true
        }
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accent)
                .frame(width: 36, height: 36)
                .background(accent.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}
