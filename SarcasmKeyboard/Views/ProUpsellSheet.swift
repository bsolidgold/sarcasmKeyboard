import SwiftUI
import SarcasmKit

struct ProUpsellSheet: View {
    let lockedPattern: any SarcasmPattern
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var accent: Color { Palette.default.accent(for: colorScheme) }

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
                            // StoreKit 2 wiring comes in Phase 6
                        } label: {
                            Text("Unlock for $2.99")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button("Restore Purchase") {
                            // StoreKit 2 wiring comes in Phase 6
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(lockedPattern.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
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
