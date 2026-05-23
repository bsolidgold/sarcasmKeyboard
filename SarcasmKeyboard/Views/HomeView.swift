import SwiftUI
import UIKit
import SarcasmKit

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(ProStore.self) private var store

    @State private var selectedPatternID: String = SharedDefaults.selectedPatternID
    @State private var selectedThemeID: String = SharedDefaults.selectedThemeID
    @State private var playgroundInput: String = "the quick brown fox"
    @State private var needsSetup: Bool = KeyboardStatus.shouldShowSetupBanner
    @State private var showInstallGuide = false
    @State private var proPatternToUpsell: AnyHashablePattern?
    @State private var proThemeToUpsell: Theme?
    @State private var showDarkModeUpsell = false
    @State private var hasAutoPresentedGuide = false
    @State private var copiedOutput = false

    private var accent: Color {
        colorScheme == .dark ? Color(hex: 0xB5F050) : Color(hex: 0x3F7A00)
    }


    private var patterns: [any SarcasmPattern] { SarcasmEngine.allPatterns }
    private var currentPattern: any SarcasmPattern {
        SarcasmEngine.pattern(id: selectedPatternID) ?? AlternatingPattern()
    }
    private var selectedTheme: Theme {
        ThemeCatalog.theme(id: selectedThemeID) ?? ThemeCatalog.cleanLight
    }
    private var transformedOutput: String {
        let input = playgroundInput.trimmingCharacters(in: .whitespaces)
        return currentPattern.transform(input.isEmpty ? "type something" : input)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                if needsSetup {
                    setupBanner.padding(.horizontal, 16)
                }
                playgroundCard.padding(.horizontal, 16)
                patternSection
                themeSection
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showInstallGuide) { InstallGuideSheet() }
        .sheet(item: $proPatternToUpsell) { ProUpsellSheet(lockedPattern: $0.pattern) }
        .sheet(item: $proThemeToUpsell) { ProUpsellSheet(lockedTheme: $0) }
        .sheet(isPresented: $showDarkModeUpsell) { ProUpsellSheet(featureName: "Dark Mode") }
        .tint(accent)
        .task {
            guard !hasAutoPresentedGuide else { return }
            hasAutoPresentedGuide = true
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--no-install-guide") { return }
            #endif
            if KeyboardStatus.shouldShowSetupBanner {
                showInstallGuide = true
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                needsSetup = KeyboardStatus.shouldShowSetupBanner
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("sArCaSm")
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .foregroundStyle(accent)
                .lineLimit(1)
            Spacer(minLength: 8)
            // Dark mode toggle
            Button { toggleDarkMode() } label: {
                Image(systemName: store.isDarkMode ? "moon.fill" : "moon")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 36, height: 36)
                    .background(accent.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(store.isDarkMode ? "Switch to light mode" : "Switch to dark mode")
            // Shuffle pattern
            Button { rerollPattern() } label: {
                Image(systemName: "sparkles")
                    .symbolEffect(.bounce, value: selectedPatternID)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 36, height: 36)
                    .background(accent.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Shuffle pattern")
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Setup Banner

    private var setupBanner: some View {
        Button { showInstallGuide = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "keyboard.badge.ellipsis")
                    .font(.title3)
                    .foregroundStyle(accent)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(accent.opacity(0.2))
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Install the keyboard")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("4 quick steps in iOS Settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accent.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(accent.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button {
                withAnimation(.bouncy) {
                    KeyboardStatus.isSetupBannerDismissed = true
                    needsSetup = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .padding(10)
        }
    }

    // MARK: - Playground Card

    private var playgroundCard: some View {
        let p = selectedTheme.palette
        return VStack(alignment: .leading, spacing: 0) {
            // "PREVIEW" label
            Text("PREVIEW")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(p.accent.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // Input field
            TextField("Type something...", text: $playgroundInput, axis: .vertical)
                .font(.body)
                .lineLimit(1...3)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(p.text.opacity(0.6))
                .tint(p.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.keyFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(p.topHighlight.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // Output text
            Text(transformedOutput)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(p.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .minimumScaleFactor(0.6)
                .lineLimit(3)
                .padding(.horizontal, 16)
                .padding(.bottom, 48)

        }
        .overlay(alignment: .bottomTrailing) {
            Button { copyOutput() } label: {
                HStack(spacing: 5) {
                    Image(systemName: copiedOutput ? "checkmark" : "doc.on.doc")
                        .contentTransition(.symbolEffect(.replace))
                    Text(copiedOutput ? "Copied" : "Copy")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(copiedOutput ? p.accent.opacity(0.5) : p.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(p.accent.opacity(0.15)))
                .overlay(Capsule().strokeBorder(p.accent.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(14)
        }
        .padding(.bottom, 4)
        .background {
            ZStack {
                p.ink
                RadialGradient(
                    colors: [p.accent.opacity(0.15), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 100
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(p.accent.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Pattern Section

    private var patternSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Style")
                .font(.headline)
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(patterns, id: \.id) { pattern in
                        PatternCard(
                            pattern: pattern,
                            isSelected: pattern.id == selectedPatternID,
                            isPro: store.isPro,
                            accent: accent
                        ) { tap(pattern) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Theme")
                .font(.headline)
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ThemeCatalog.allThemes) { theme in
                        ThemeSwatch(
                            theme: theme,
                            isSelected: theme.id == selectedThemeID,
                            isPro: store.isPro,
                            accent: accent
                        ) { tapTheme(theme) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Actions

    private func toggleDarkMode() {
        guard store.isPro else {
            showDarkModeUpsell = true
            return
        }
        withAnimation(.bouncy) { store.isDarkMode.toggle() }
    }

    private func rerollPattern() {
        let free = patterns.filter { !$0.isPremium && $0.id != selectedPatternID }
        guard let next = free.randomElement() else { return }
        withAnimation(.bouncy) { selectedPatternID = next.id }
        SharedDefaults.selectedPatternID = next.id
    }

    private func tap(_ pattern: any SarcasmPattern) {
        if pattern.isPremium && !store.isPro {
            proPatternToUpsell = AnyHashablePattern(pattern: pattern)
            return
        }
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.bouncy) { selectedPatternID = pattern.id }
        SharedDefaults.selectedPatternID = pattern.id
    }

    private func tapTheme(_ theme: Theme) {
        if theme.isPremium && !store.isPro {
            proThemeToUpsell = theme
            return
        }
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.bouncy) { selectedThemeID = theme.id }
        SharedDefaults.selectedThemeID = theme.id
    }

    private func copyOutput() {
        UIPasteboard.general.string = transformedOutput
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.bouncy) { copiedOutput = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation { copiedOutput = false }
        }
    }
}

// MARK: - PatternCard

private struct PatternCard: View {
    let pattern: any SarcasmPattern
    let isSelected: Bool
    let isPro: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                // Transformed preview first (top), like the mockup
                Text(pattern.transform("Hello World"))
                    .font(.sarcasmMonoSmall)
                    .foregroundStyle(isSelected ? accent : .secondary)
                    .lineLimit(1)
                HStack(alignment: .bottom, spacing: 4) {
                    Text(pattern.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? accent : .primary)
                        .lineLimit(1)
                    if pattern.isPremium && !isPro {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(isSelected ? accent : .secondary)
                            .padding(.bottom, 1)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(14)
            .frame(width: 140, alignment: .leading)
            .background(
                isSelected ? accent.opacity(0.12) : Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? accent.opacity(0.4) : Color(.separator).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ThemeSwatch

private struct ThemeSwatch: View {
    let theme: Theme
    let isSelected: Bool
    let isPro: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    // Swatch: full theme ink color with accent stripe at bottom
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(theme.palette.ink)
                        .frame(width: 80, height: 56)
                        .overlay(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(theme.palette.accent)
                                .frame(width: 44, height: 8)
                                .padding(8)
                        }
                    if theme.isPremium && !isPro {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(.black.opacity(0.55), in: Circle())
                            .padding(5)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isSelected ? accent : Color(.separator).opacity(0.4),
                            lineWidth: isSelected ? 2 : 0.5
                        )
                )
                Text(theme.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? accent : .secondary)
                    .lineLimit(1)
                    .frame(width: 80)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AnyHashablePattern

struct AnyHashablePattern: Identifiable, Hashable {
    let pattern: any SarcasmPattern
    var id: String { pattern.id }
    static func == (lhs: AnyHashablePattern, rhs: AnyHashablePattern) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

#Preview {
    NavigationStack { HomeView() }
        .environment(ProStore())
}
