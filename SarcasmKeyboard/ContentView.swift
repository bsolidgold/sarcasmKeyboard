import SwiftUI
import SarcasmKit

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedPatternID: String = SharedDefaults.selectedPatternID
    @State private var playgroundInput: String = "the quick brown fox"
    @State private var needsSetup: Bool = KeyboardStatus.shouldShowSetupBanner
    @State private var showInstallGuide = false
    @State private var proPatternToUpsell: AnyHashablePattern?
    @State private var hasAutoPresentedGuide = false

    private var patterns: [any SarcasmPattern] { SarcasmEngine.allPatterns }
    private var currentPattern: any SarcasmPattern {
        SarcasmEngine.pattern(id: selectedPatternID) ?? AlternatingPattern()
    }
    private var accent: Color { Palette.default.accent(for: colorScheme) }

    var body: some View {
        NavigationStack {
            List {
                if needsSetup {
                    setupSection
                }
                playgroundSection
                patternsSection
                aboutSection
            }
            .listStyle(.plain)
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .navigationTitle(currentPattern.transform("Sarcasm Keyboard"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        rerollPattern()
                    } label: {
                        Image(systemName: "sparkles")
                            .symbolEffect(.bounce, value: selectedPatternID)
                    }
                    .accessibilityLabel("Shuffle pattern")
                }
            }
            .sheet(isPresented: $showInstallGuide) {
                InstallGuideSheet()
            }
            .sheet(item: $proPatternToUpsell) { wrapper in
                ProUpsellSheet(lockedPattern: wrapper.pattern)
            }
        }
        .tint(accent)
        .task {
            // On first appearance: if the keyboard isn't enabled yet, open the
            // install guide immediately so the user doesn't have to find the
            // setup banner. Only auto-presents once per app session.
            guard !hasAutoPresentedGuide else { return }
            hasAutoPresentedGuide = true
            if KeyboardStatus.shouldShowSetupBanner {
                showInstallGuide = true
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // When returning from Settings, re-check whether the keyboard is
            // enabled so the setup banner hides itself automatically.
            if phase == .active {
                needsSetup = KeyboardStatus.shouldShowSetupBanner
            }
        }
    }

    private func rerollPattern() {
        let free = patterns.filter { !$0.isPremium && $0.id != selectedPatternID }
        guard let next = free.randomElement() else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedPatternID = next.id
        }
        SharedDefaults.selectedPatternID = next.id
    }

    private var setupSection: some View {
        Section {
            Button {
                showInstallGuide = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "keyboard.badge.ellipsis")
                        .font(.callout)
                        .foregroundStyle(accent)
                        .frame(width: 28, height: 28)
                        .background(accent.opacity(0.15), in: Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Install the keyboard")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("4 quick steps in iOS Settings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        } footer: {
            Text("Not sure if it's installed. Swipe left to dismiss.")
                .font(.caption)
        }
        .listRowBackground(accent.opacity(0.10))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation {
                    KeyboardStatus.isSetupBannerDismissed = true
                    needsSetup = false
                }
            } label: {
                Label("Dismiss", systemImage: "xmark")
            }
        }
    }

    private var playgroundSection: some View {
        Section {
            TextField("Type something to transform", text: $playgroundInput, axis: .vertical)
                .font(.subheadline)
                .lineLimit(1...3)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                    .padding(.top, 2)
                Text(currentPattern.transform(playgroundInput.isEmpty ? "type something to see it transformed" : playgroundInput))
                    .font(.sarcasmMono)
                    .foregroundStyle(accent)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } header: {
            Text("Try it")
        } footer: {
            Text("Preview only — the keyboard transforms text as you type in any app.")
        }
    }

    private var patternsSection: some View {
        Section {
            ForEach(patterns, id: \.id) { pattern in
                Button {
                    tap(pattern)
                } label: {
                    PatternRow(
                        pattern: pattern,
                        isSelected: pattern.id == selectedPatternID
                    )
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Style")
        } footer: {
            Text("Free patterns work right away. Pro unlocks the sparkly stuff.")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("0.1.0")
                    .foregroundStyle(.secondary)
                    .font(.callout.monospacedDigit())
            }
        } header: {
            Text("About")
        }
    }

    private func tap(_ pattern: any SarcasmPattern) {
        if pattern.isPremium {
            proPatternToUpsell = AnyHashablePattern(pattern: pattern)
            return
        }
        selectedPatternID = pattern.id
        SharedDefaults.selectedPatternID = pattern.id
    }
}

struct AnyHashablePattern: Identifiable, Hashable {
    let pattern: any SarcasmPattern
    var id: String { pattern.id }

    static func == (lhs: AnyHashablePattern, rhs: AnyHashablePattern) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#Preview {
    ContentView()
}
