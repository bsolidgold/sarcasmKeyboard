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
    @State private var hasAutoPresentedGuide = false
    @State private var copiedOutput = false

    private var patterns: [any SarcasmPattern] { SarcasmEngine.allPatterns }
    private var currentPattern: any SarcasmPattern {
        SarcasmEngine.pattern(id: selectedPatternID) ?? AlternatingPattern()
    }
    private var accent: Color { Palette.default.accent(for: colorScheme) }
    private var transformedOutput: String {
        let input = playgroundInput.trimmingCharacters(in: .whitespaces)
        return currentPattern.transform(input.isEmpty ? "type something" : input)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if needsSetup {
                    setupBanner
                        .padding(.horizontal, 16)
                }
                playgroundCard
                    .padding(.horizontal, 16)
                patternSection
                themeSection
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .navigationTitle(currentPattern.transform("Sarcasm Keyboard"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { rerollPattern() } label: {
                    Image(systemName: "sparkles")
                        .symbolEffect(.bounce, value: selectedPatternID)
                }
                .accessibilityLabel("Shuffle pattern")
            }
        }
        .sheet(isPresented: $showInstallGuide) { InstallGuideSheet() }
        .sheet(item: $proPatternToUpsell) { ProUpsellSheet(lockedPattern: $0.pattern) }
        .sheet(item: $proThemeToUpsell) { ProUpsellSheet(lockedTheme: $0) }
        .tint(accent)
        .task {
            guard !hasAutoPresentedGuide else { return }
            hasAutoPresentedGuide = true
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

    // MARK: - Setup Banner

    private var setupBanner: some View {
        Button { showInstallGuide = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "keyboard.badge.ellipsis")
                    .font(.title3)
                    .foregroundStyle(accent)
                    .frame(width: 40, height: 40)
                    .background(accent.opacity(0.15), in: Circle())
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
            .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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

    private static let cardGreen = Color(red: 0.722, green: 1.0, blue: 0.165)

    private var playgroundCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Type something...", text: $playgroundInput, axis: .vertical)
                .font(.body)
                .lineLimit(1...3)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(Color.white.opacity(0.75))
                .tint(Self.cardGreen)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)

            Divider()
                .overlay(Color.white.opacity(0.1))
                .padding(.horizontal, 20)

            Text(transformedOutput)
                .font(.sarcasmMono)
                .foregroundStyle(Self.cardGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .minimumScaleFactor(0.65)
                .lineLimit(4)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            HStack {
                Text(currentPattern.displayName.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .tracking(1)
                Spacer(minLength: 0)
                Button { copyOutput() } label: {
                    HStack(spacing: 5) {
                        Image(systemName: copiedOutput ? "checkmark" : "doc.on.doc")
                            .contentTransition(.symbolEffect(.replace))
                        Text(copiedOutput ? "Copied" : "Copy")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(copiedOutput ? Color.white.opacity(0.5) : Self.cardGreen)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(Color.black, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
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
        withAnimation(.bouncy) { selectedPatternID = pattern.id }
        SharedDefaults.selectedPatternID = pattern.id
    }

    private func tapTheme(_ theme: Theme) {
        if theme.isPremium && !store.isPro {
            proThemeToUpsell = theme
            return
        }
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
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 4) {
                    Text(pattern.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? accent : .primary)
                        .lineLimit(1)
                    if pattern.isPremium && !isPro {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(isSelected ? accent : .secondary)
                            .padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                }
                Text(pattern.transform("Hello World"))
                    .font(.sarcasmMonoSmall)
                    .foregroundStyle(isSelected ? accent.opacity(0.8) : .secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(width: 150, alignment: .leading)
            .background(
                isSelected ? accent.opacity(0.12) : Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? accent.opacity(0.5) : Color.clear, lineWidth: 1.5)
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
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(theme.palette.ink)
                        .frame(width: 80, height: 52)
                        .overlay {
                            HStack(spacing: 4) {
                                keyMock("A", fg: theme.palette.text, bg: theme.palette.keyFill)
                                keyMock("b", fg: theme.palette.accent, bg: theme.palette.keyFill)
                                keyMock("C", fg: theme.palette.text, bg: theme.palette.keyFill)
                            }
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
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
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

    private func keyMock(_ label: String, fg: Color, bg: Color) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(bg)
            .frame(width: 20, height: 24)
            .overlay {
                Text(label)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(fg)
            }
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
