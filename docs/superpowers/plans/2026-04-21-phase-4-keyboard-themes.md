# Keyboard Themes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship 10 keyboard themes (3 free, 7 Pro) with a picker in the companion app, palette threading to the keyboard extension, and Pro gating via the existing `ProUpsellSheet`.

**Architecture:** A new `Theme` value type in `SarcasmKit/Design/` bundles palette tokens with catalog identity. `ThemeCatalog` (enum namespace) holds all 10 instances. `SharedDefaults.selectedThemeID` persists the choice across targets via the App Group. The keyboard extension reads the resolved palette from `makeKeyboardView()` and threads it explicitly to `KeyboardView`, `KeyButton`, and `ActivePatternStrip`. The companion app gains a "Theme" section with `ThemeRow` views and wires Pro taps to `ProUpsellSheet(lockedTheme:)`.

**Tech Stack:** Swift 5.9, SwiftUI (iOS 17+), XCTest, SwiftPM (`SarcasmKit` + tests), XcodeGen (regenerates `.xcodeproj`), `xcodebuild`, `xcrun simctl`.

**Spec:** [`docs/superpowers/specs/2026-04-21-phase-4-keyboard-themes-design.md`](../specs/2026-04-21-phase-4-keyboard-themes-design.md)

---

## Conventions used throughout this plan

- **Package root:** `/Users/bretgold/Documents/gitHub/sarcasmKeyboard/`. All `swift test`, `xcodegen`, and `xcodebuild` commands are run from there.
- **Building:** `xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build`
- **Screenshot loop:** `xcrun simctl io booted screenshot /tmp/sk.png` then `Read /tmp/sk.png` to inspect.
- **Commits:** One concern per commit. **No `Co-Authored-By: Claude` trailer** — enforced by `.githooks/commit-msg`.
- **Tests baseline:** `swift test` is currently green at 98 passed + 1 skipped. This must stay true after every task except where a task explicitly adds new tests.

---

## Task 1: `Theme` type + `ThemeCatalog` — TDD with catalog tests

**Files:**
- Create: `Sources/SarcasmKit/Design/Theme.swift`
- Create: `Tests/SarcasmKitTests/ThemeCatalogTests.swift`

This task is pure logic — no UI, no extension changes. Write the tests first, confirm they fail, then implement.

- [ ] **Step 1: Write the failing tests**

Create `Tests/SarcasmKitTests/ThemeCatalogTests.swift`:

```swift
import XCTest
import UIKit
@testable import SarcasmKit

final class ThemeCatalogTests: XCTestCase {

    func testExactlyTenThemes() {
        XCTAssertEqual(ThemeCatalog.allThemes.count, 10)
    }

    func testThemeOrder() {
        let ids = ThemeCatalog.allThemes.map(\.id)
        XCTAssertEqual(ids, [
            "acid", "cleanLight", "cleanDark",
            "neon", "vaporwave", "terminalGreen",
            "sunset", "paper", "y2k", "highlighter"
        ])
    }

    func testFreeThemesNotPremium() {
        let free = ThemeCatalog.allThemes.prefix(3)
        XCTAssert(free.allSatisfy { !$0.isPremium }, "First three themes must be free")
    }

    func testProThemesArePremium() {
        let pro = ThemeCatalog.allThemes.dropFirst(3)
        XCTAssert(pro.allSatisfy { $0.isPremium }, "Last seven themes must be Pro")
    }

    func testAllThemesHaveNonTransparentKeyboardTokens() {
        for theme in ThemeCatalog.allThemes {
            let p = theme.palette
            let inkAlpha    = UIColor(p.ink).cgColor.alpha
            let fillAlpha   = UIColor(p.keyFill).cgColor.alpha
            let accentAlpha = UIColor(p.accent).cgColor.alpha
            XCTAssertGreaterThan(inkAlpha,    0, "\(theme.id): ink is transparent")
            XCTAssertGreaterThan(fillAlpha,   0, "\(theme.id): keyFill is transparent")
            XCTAssertGreaterThan(accentAlpha, 0, "\(theme.id): accent is transparent")
        }
    }

    func testThemeLookupByID() {
        XCTAssertNotNil(ThemeCatalog.theme(id: "acid"))
        XCTAssertNil(ThemeCatalog.theme(id: "nonexistent"))
    }

    func testAcidPaletteDefaultAlias() {
        let acid = ThemeCatalog.acid.palette
        let def  = Palette.default
        XCTAssertEqual(acid, def)
    }
}
```

- [ ] **Step 2: Run the tests to confirm they fail**

```bash
swift test --filter ThemeCatalogTests
```

Expected: compile error — `ThemeCatalog` does not exist yet.

- [ ] **Step 3: Create `Sources/SarcasmKit/Design/Theme.swift`**

```swift
import SwiftUI

// MARK: - Theme

public struct Theme: Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let isPremium: Bool
    public let palette: Palette
}

// MARK: - ThemeCatalog

public enum ThemeCatalog {

    public static let allThemes: [Theme] = [
        acid,        // free
        cleanLight,  // free
        cleanDark,   // free
        neon,        // Pro
        vaporwave,   // Pro
        terminalGreen, // Pro
        sunset,      // Pro
        paper,       // Pro
        y2k,         // Pro
        highlighter, // Pro
    ]

    public static func theme(id: String) -> Theme? {
        allThemes.first { $0.id == id }
    }

    // MARK: Free

    public static let acid = Theme(
        id: "acid",
        displayName: "Acid",
        isPremium: false,
        palette: Palette(
            ink:             Color(hex: 0x0A0A0A),
            keyFill:         Color(hex: 0x1C1C1E),
            systemKeyFill:   Color(hex: 0x2C2C2E),
            topHighlight:    Color(hex: 0x3A3A3C),
            accent:          Color(hex: 0xB8FF2A),
            accentOnLight:   Color(hex: 0x3F7A00),
            text:            Color(hex: 0xF2F2F7),
            subtleText:      Color(hex: 0x8E8E93)
        )
    )

    public static let cleanLight = Theme(
        id: "cleanLight",
        displayName: "Clean Light",
        isPremium: false,
        palette: Palette(
            ink:             Color(hex: 0xF2F2F7),
            keyFill:         Color(hex: 0xFFFFFF),
            systemKeyFill:   Color(hex: 0xD1D1D6),
            topHighlight:    Color(hex: 0xC7C7CC),
            accent:          Color(hex: 0x3F7A00),
            accentOnLight:   Color(hex: 0x3F7A00),
            text:            Color(hex: 0x1C1C1E),
            subtleText:      Color(hex: 0x3C3C43)
        )
    )

    public static let cleanDark = Theme(
        id: "cleanDark",
        displayName: "Clean Dark",
        isPremium: false,
        palette: Palette(
            ink:             Color(hex: 0x000000),
            keyFill:         Color(hex: 0x1C1C1E),
            systemKeyFill:   Color(hex: 0x2C2C2E),
            topHighlight:    Color(hex: 0x48484A),
            accent:          Color(hex: 0x8E8E93),
            accentOnLight:   Color(hex: 0x636366),
            text:            Color(hex: 0xFFFFFF),
            subtleText:      Color(hex: 0x636366)
        )
    )

    // MARK: Pro

    public static let neon = Theme(
        id: "neon",
        displayName: "Neon",
        isPremium: true,
        palette: Palette(
            ink:             Color(hex: 0x0D0018),
            keyFill:         Color(hex: 0x1A0033),
            systemKeyFill:   Color(hex: 0x2A004D),
            topHighlight:    Color(hex: 0x3D0073),
            accent:          Color(hex: 0xFF2D8A),
            accentOnLight:   Color(hex: 0xC4005A),
            text:            Color(hex: 0xF0E6FF),
            subtleText:      Color(hex: 0x9B7BC4)
        )
    )

    public static let vaporwave = Theme(
        id: "vaporwave",
        displayName: "Vaporwave",
        isPremium: true,
        palette: Palette(
            ink:             Color(hex: 0x1A0A2E),
            keyFill:         Color(hex: 0x2D1B4E),
            systemKeyFill:   Color(hex: 0x3D2560),
            topHighlight:    Color(hex: 0x5A3880),
            accent:          Color(hex: 0x00FFDD),
            accentOnLight:   Color(hex: 0x007A6A),
            text:            Color(hex: 0xFFB8D9),
            subtleText:      Color(hex: 0x9F78B8)
        )
    )

    public static let terminalGreen = Theme(
        id: "terminalGreen",
        displayName: "Terminal Green",
        isPremium: true,
        palette: Palette(
            ink:             Color(hex: 0x000000),
            keyFill:         Color(hex: 0x001A00),
            systemKeyFill:   Color(hex: 0x002A00),
            topHighlight:    Color(hex: 0x003D00),
            accent:          Color(hex: 0x00FF41),
            accentOnLight:   Color(hex: 0x006614),
            text:            Color(hex: 0x00CC33),
            subtleText:      Color(hex: 0x006614)
        )
    )

    public static let sunset = Theme(
        id: "sunset",
        displayName: "Sunset",
        isPremium: true,
        palette: Palette(
            ink:             Color(hex: 0x0F0A00),
            keyFill:         Color(hex: 0x1E1408),
            systemKeyFill:   Color(hex: 0x2E2010),
            topHighlight:    Color(hex: 0x4A3318),
            accent:          Color(hex: 0xFF7A2A),
            accentOnLight:   Color(hex: 0xB84A00),
            text:            Color(hex: 0xF5DEB3),
            subtleText:      Color(hex: 0xA0825A)
        )
    )

    public static let paper = Theme(
        id: "paper",
        displayName: "Paper",
        isPremium: true,
        palette: Palette(
            ink:             Color(hex: 0x1C1509),
            keyFill:         Color(hex: 0xD9C9A8),
            systemKeyFill:   Color(hex: 0xC5B491),
            topHighlight:    Color(hex: 0xB8A47E),
            accent:          Color(hex: 0x4A2F00),
            accentOnLight:   Color(hex: 0x4A2F00),
            text:            Color(hex: 0x2C1A00),
            subtleText:      Color(hex: 0x6B4E2A)
        )
    )

    public static let y2k = Theme(
        id: "y2k",
        displayName: "Y2K",
        isPremium: true,
        palette: Palette(
            ink:             Color(hex: 0x0A0A12),
            keyFill:         Color(hex: 0x2A2A3A),
            systemKeyFill:   Color(hex: 0x3A3A4E),
            topHighlight:    Color(hex: 0x5A5A7A),
            accent:          Color(hex: 0x00B4FF),
            accentOnLight:   Color(hex: 0x005A8A),
            text:            Color(hex: 0xC8C8DC),
            subtleText:      Color(hex: 0x7070A0)
        )
    )

    public static let highlighter = Theme(
        id: "highlighter",
        displayName: "Highlighter",
        isPremium: true,
        palette: Palette(
            ink:             Color(hex: 0x0A0800),
            keyFill:         Color(hex: 0x1A1600),
            systemKeyFill:   Color(hex: 0x2A2400),
            topHighlight:    Color(hex: 0x3D3600),
            accent:          Color(hex: 0xFFEE00),
            accentOnLight:   Color(hex: 0x7A6600),
            text:            Color(hex: 0xFFF8E0),
            subtleText:      Color(hex: 0xA09060)
        )
    )
}
```

- [ ] **Step 4: Run the tests to confirm they pass**

```bash
swift test --filter ThemeCatalogTests
```

Expected: 7 tests passed.

- [ ] **Step 5: Run the full test suite to confirm no regressions**

```bash
swift test
```

Expected: 105 passed, 1 skipped (98 existing + 7 new ThemeCatalogTests).

- [ ] **Step 6: Commit**

```bash
git add Sources/SarcasmKit/Design/Theme.swift Tests/SarcasmKitTests/ThemeCatalogTests.swift
git commit -m "Theme type + ThemeCatalog: 10 themes (3 free, 7 Pro) with palette tokens

Introduces Theme (id/displayName/isPremium/palette) and ThemeCatalog enum
with all 10 instances in ship order. Hex values are final — verified contrast
ratios per WCAG AA for body text in spec. 7 ThemeCatalogTests cover count,
order, free/Pro split, non-transparent tokens, lookup, and Palette.default alias."
```

---

## Task 2: `SharedDefaults.selectedThemeID` + round-trip tests

**Files:**
- Modify: `Sources/SarcasmKit/Storage/SharedDefaults.swift`
- Modify: `Tests/SarcasmKitTests/SharedDefaultsTests.swift`

- [ ] **Step 1: Add theme properties to `SharedDefaults`**

Open `Sources/SarcasmKit/Storage/SharedDefaults.swift`. The current `Keys` enum has one key. Add the theme key and two computed properties:

```swift
import Foundation

public enum SharedDefaults {
    public static let appGroupIdentifier = "group.com.sarcasmkeyboard.app"

    public static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    private enum Keys {
        static let selectedPatternID = "sarcasm.selectedPatternID"
        static let selectedThemeID   = "sarcasm.selectedThemeID"
    }

    // MARK: Pattern

    public static var selectedPatternID: String {
        get { defaults.string(forKey: Keys.selectedPatternID) ?? AlternatingPattern().id }
        set { defaults.setValue(newValue, forKey: Keys.selectedPatternID) }
    }

    public static var selectedPattern: any SarcasmPattern {
        SarcasmEngine.pattern(id: selectedPatternID) ?? AlternatingPattern()
    }

    // MARK: Theme

    public static var selectedThemeID: String {
        get { defaults.string(forKey: Keys.selectedThemeID) ?? ThemeCatalog.acid.id }
        set { defaults.setValue(newValue, forKey: Keys.selectedThemeID) }
    }

    public static var selectedTheme: Theme {
        ThemeCatalog.theme(id: selectedThemeID) ?? ThemeCatalog.acid
    }
}
```

- [ ] **Step 2: Add tests to `SharedDefaultsTests.swift`**

Open `Tests/SarcasmKitTests/SharedDefaultsTests.swift`. Add four new test methods at the bottom of the class (before the closing brace):

```swift
    // MARK: selectedThemeID

    func testSelectedThemeIDDefaultsToAcid() {
        SharedDefaults.defaults.removeObject(forKey: "sarcasm.selectedThemeID")
        XCTAssertEqual(SharedDefaults.selectedThemeID, "acid")
    }

    func testSelectedThemeIDRoundTrip() {
        SharedDefaults.defaults.removeObject(forKey: "sarcasm.selectedThemeID")
        SharedDefaults.selectedThemeID = "neon"
        XCTAssertEqual(SharedDefaults.selectedThemeID, "neon")
    }

    func testSelectedThemeResolvesTheme() {
        SharedDefaults.selectedThemeID = "terminalGreen"
        XCTAssertEqual(SharedDefaults.selectedTheme.id, "terminalGreen")
    }

    func testInvalidThemeIDFallsBackToAcid() {
        SharedDefaults.defaults.setValue("bogus", forKey: "sarcasm.selectedThemeID")
        XCTAssertEqual(SharedDefaults.selectedTheme.id, "acid")
    }
```

- [ ] **Step 3: Run tests**

```bash
swift test --filter SharedDefaultsTests
```

Expected: 8 tests passed (4 existing + 4 new).

- [ ] **Step 4: Run full suite**

```bash
swift test
```

Expected: 109 passed, 1 skipped.

- [ ] **Step 5: Commit**

```bash
git add Sources/SarcasmKit/Storage/SharedDefaults.swift Tests/SarcasmKitTests/SharedDefaultsTests.swift
git commit -m "SharedDefaults: add selectedThemeID + selectedTheme with 4 round-trip tests

Adds selectedThemeID (String, defaults to 'acid') and selectedTheme (Theme,
falls back to ThemeCatalog.acid on unknown ID) alongside the existing pattern
equivalents. Four new SharedDefaultsTests cover default, set/get round-trip,
resolution, and invalid-ID fallback."
```

---

## Task 3: `Palette.default` alias update

**Files:**
- Modify: `Sources/SarcasmKit/Design/Palette.swift`

After Task 1, `ThemeCatalog.acid.palette` holds the canonical Acid hex values.
`Palette.default` should alias it so there's one source of truth. This is a
one-line change that causes zero disruption to existing call sites.

- [ ] **Step 1: Replace the inline `Palette.default` construction with the alias**

In `Sources/SarcasmKit/Design/Palette.swift`, find:

```swift
    public static let `default` = Palette(
        ink: Color(hex: 0x0A0A0A),
        keyFill: Color(hex: 0x1C1C1E),
        systemKeyFill: Color(hex: 0x2C2C2E),
        topHighlight: Color(hex: 0x3A3A3C),
        accent: Color(hex: 0xB8FF2A),
        accentOnLight: Color(hex: 0x3F7A00),
        text: Color(hex: 0xF2F2F7),
        subtleText: Color(hex: 0x8E8E93)
    )
```

Replace with:

```swift
    public static var `default`: Palette { ThemeCatalog.acid.palette }
```

Note: `var` instead of `let` because `ThemeCatalog` is defined in the same module
but is a different type — Swift resolves this cleanly. The compiler inlines this
trivially (no heap allocation).

- [ ] **Step 2: Build to confirm all existing call sites still compile**

```bash
swift build
```

Expected: `Build complete!` with no errors. Every file that references `Palette.default` still compiles without modification.

- [ ] **Step 3: Run full suite**

```bash
swift test
```

Expected: 109 passed, 1 skipped. `testAcidPaletteDefaultAlias` in `ThemeCatalogTests` explicitly verifies equality.

- [ ] **Step 4: Commit**

```bash
git add Sources/SarcasmKit/Design/Palette.swift
git commit -m "Palette.default: alias to ThemeCatalog.acid.palette (single source of truth)

Replaces the inline Palette(...) construction in Palette.default with a
computed var that delegates to ThemeCatalog.acid.palette. All 7 tokens stay
identical; existing call sites compile without change. ThemeCatalogTests
testAcidPaletteDefaultAlias verifies equality."
```

---

## Task 4: Wire `KeyboardView` / `KeyButton` / `ActivePatternStrip` to accept explicit `Palette`

**Files:**
- Modify: `SarcasmKeyboardExtension/KeyboardView.swift`
- Modify: `SarcasmKeyboardExtension/KeyButton.swift`

Today both files read `Palette.default.*` directly. After this task they accept a
`Palette` parameter and read from it. `KeyboardViewController` (Task 5) will be the
only caller; it provides the resolved theme palette.

Do not commit until Task 5 is complete — the project will not compile in the
intermediate state between these two tasks.

- [ ] **Step 1: Replace `SarcasmKeyboardExtension/KeyButton.swift`**

```swift
import SwiftUI
import SarcasmKit

struct KeyButton: View {
    enum Style {
        case letter
        case system
    }

    let label: String
    let style: Style
    let palette: Palette
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(style == .letter ? .sarcasmMono : .sarcasmMonoSmall)
                .foregroundColor(palette.text)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(isPressed ? palette.accent.opacity(0.30) : backgroundColor)
                        VStack(spacing: 0) {
                            palette.topHighlight
                                .frame(height: 1)
                            Color.clear
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }
                )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.08), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var backgroundColor: Color {
        switch style {
        case .letter: return palette.keyFill
        case .system: return palette.systemKeyFill
        }
    }
}
```

- [ ] **Step 2: Replace `SarcasmKeyboardExtension/KeyboardView.swift`**

```swift
import SwiftUI
import SarcasmKit

struct KeyboardView: View {
    let onLetter: (Character) -> Void
    let onPunctuation: (Character) -> Void
    let onSpace: () -> Void
    let onDelete: () -> Void
    let onReturn: () -> Void
    let onGlobe: () -> Void
    let onCyclePattern: () -> Void
    let currentPattern: any SarcasmPattern
    let palette: Palette

    private let row1: [Character] = ["q","w","e","r","t","y","u","i","o","p"]
    private let row2: [Character] = ["a","s","d","f","g","h","j","k","l"]
    private let row3: [Character] = ["z","x","c","v","b","n","m"]

    var body: some View {
        VStack(spacing: 0) {
            ActivePatternStrip(pattern: currentPattern, palette: palette, onTap: onCyclePattern)
            keyRows
        }
        .background(palette.ink)
    }

    private var keyRows: some View {
        VStack(spacing: 6) {
            letterRow(row1)
            letterRow(row2)
                .padding(.horizontal, 18)
            HStack(spacing: 6) {
                ForEach(Array(row3), id: \.self) { c in
                    KeyButton(label: String(c), style: .letter, palette: palette) { onLetter(c) }
                }
                KeyButton(label: "⌫", style: .system, palette: palette, action: onDelete)
                    .frame(width: 56)
            }
            HStack(spacing: 6) {
                KeyButton(label: "🌐", style: .system, palette: palette, action: onGlobe)
                    .frame(width: 44)
                KeyButton(label: ".", style: .system, palette: palette) { onPunctuation(".") }
                    .frame(width: 40)
                KeyButton(label: ",", style: .system, palette: palette) { onPunctuation(",") }
                    .frame(width: 40)
                KeyButton(label: "space", style: .system, palette: palette, action: onSpace)
                KeyButton(label: "return", style: .system, palette: palette, action: onReturn)
                    .frame(width: 80)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
    }

    private func letterRow(_ chars: [Character]) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(chars), id: \.self) { c in
                KeyButton(label: String(c), style: .letter, palette: palette) { onLetter(c) }
            }
        }
    }
}

private struct ActivePatternStrip: View {
    let pattern: any SarcasmPattern
    let palette: Palette
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text("•")
                    .font(.sarcasmMonoSmall)
                    .foregroundStyle(palette.accent)
                Text(pattern.transform(pattern.displayName))
                    .font(.sarcasmMonoSmall)
                    .foregroundStyle(palette.accent)
                Text("▾")
                    .font(.sarcasmMonoSmall)
                    .foregroundStyle(palette.accent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(
                ZStack {
                    palette.ink
                    if isPressed {
                        palette.accent.opacity(0.15)
                    }
                    VStack {
                        palette.accent.frame(height: 1)
                        Spacer()
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
```

- [ ] **Step 3: Verify the build fails as expected — `KeyboardViewController` has the old call site**

```bash
xcodegen generate
xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "error:|BUILD FAILED"
```

Expected: errors in `KeyboardViewController.swift` — `missing argument for parameter 'palette'` in `KeyboardView(...)`. This is correct. Move to Task 5 immediately.

**Do not commit yet.** Task 5's commit covers both tasks so git history stays bisectable.

---

## Task 5: Wire `KeyboardViewController.makeKeyboardView()` to resolve + pass palette

**Files:**
- Modify: `SarcasmKeyboardExtension/KeyboardViewController.swift`

- [ ] **Step 1: Replace `SarcasmKeyboardExtension/KeyboardViewController.swift`**

```swift
import UIKit
import SwiftUI
import SarcasmKit

final class KeyboardViewController: UIInputViewController {
    private var hostingController: UIHostingController<KeyboardView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        KeyboardStatus.recordHeartbeat()

        let host = UIHostingController(rootView: makeKeyboardView())
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        addChild(host)
        self.view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        host.didMove(toParent: self)
        hostingController = host
    }

    private func makeKeyboardView() -> KeyboardView {
        KeyboardView(
            onLetter:       { [weak self] char in self?.handleLetter(char) },
            onPunctuation:  { [weak self] char in self?.handlePunctuation(char) },
            onSpace:        { [weak self] in self?.handleLetter(" ") },
            onDelete:       { [weak self] in self?.textDocumentProxy.deleteBackward() },
            onReturn:       { [weak self] in self?.textDocumentProxy.insertText("\n") },
            onGlobe:        { [weak self] in self?.advanceToNextInputMode() },
            onCyclePattern: { [weak self] in self?.cyclePattern() },
            currentPattern: SharedDefaults.selectedPattern,
            palette:        SharedDefaults.selectedTheme.palette
        )
    }

    private func handleLetter(_ char: Character) {
        let prior   = textDocumentProxy.documentContextBeforeInput ?? ""
        let pattern = SharedDefaults.selectedPattern
        let out     = pattern.transformCharacter(char, priorContext: prior)
        textDocumentProxy.insertText(out)
    }

    private func handlePunctuation(_ char: Character) {
        textDocumentProxy.insertText(String(char))
    }

    private func cyclePattern() {
        let nextID = PatternCycler.next(
            currentID: SharedDefaults.selectedPatternID,
            in: SarcasmEngine.allPatterns
        )
        SharedDefaults.selectedPatternID = nextID
        hostingController?.rootView = makeKeyboardView()
    }
}
```

The only change from the Phase 3.5 version is `palette: SharedDefaults.selectedTheme.palette`
added to the `KeyboardView` initializer call. The keyboard picks up a new theme on its
next `viewDidLoad` — the same mechanism as pattern changes from the companion app.

- [ ] **Step 2: Build**

```bash
xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Run full test suite**

```bash
swift test
```

Expected: 109 passed, 1 skipped.

- [ ] **Step 4: Install + quick Simulator smoke-check**

```bash
xcrun simctl boot 'iPhone 17' 2>/dev/null || true
xcrun simctl install booted $(xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' -showBuildSettings 2>/dev/null | awk -F= '/ BUILT_PRODUCTS_DIR /{gsub(/^ +| +$/,"",$2); print $2"/SarcasmKeyboard.app"; exit}')
xcrun simctl launch booted com.apple.mobilenotes
xcrun simctl io booted screenshot /tmp/kb_acid.png
```

Read `/tmp/kb_acid.png`. Keyboard should appear with the Acid palette (lime-on-ink),
unchanged from Phase 3.5 — this task introduced no visual change, just the plumbing.

- [ ] **Step 5: Commit Tasks 4 + 5 together**

```bash
git add SarcasmKeyboardExtension/KeyboardView.swift \
        SarcasmKeyboardExtension/KeyButton.swift \
        SarcasmKeyboardExtension/KeyboardViewController.swift
git commit -m "Keyboard extension: thread Palette param through KeyboardView/KeyButton/Strip

KeyboardView, KeyButton, and ActivePatternStrip no longer read Palette.default
directly. Each accepts an explicit Palette parameter. KeyboardViewController
resolves SharedDefaults.selectedTheme.palette in makeKeyboardView() and passes
it down. No visual change at this commit — Acid is still the default."
```

---

## Task 6: `ThemeRow` view — mini-preview + Pro lock

**Files:**
- Create: `SarcasmKeyboard/Views/ThemeRow.swift`

`ThemeRow` is structurally parallel to `PatternRow`. It shows the theme's display
name, a compact visual preview of the palette, and a lock badge on Pro themes.

The mini-preview is a 44×28pt rounded rectangle filled with the theme's `ink` color,
containing a short text sample (`"aB"`) rendered in the theme's `accent` color. This
communicates ink vs. accent personality at a glance without requiring any images.
The preview text is not transformed through any pattern — it's a pure palette showcase.

- [ ] **Step 1: Create `SarcasmKeyboard/Views/ThemeRow.swift`**

```swift
import SwiftUI
import SarcasmKit

struct ThemeRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let theme: Theme
    let isSelected: Bool

    private var accent: Color { Palette.default.accent(for: colorScheme) }

    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            ZStack {
                Circle()
                    .fill(isSelected ? accent.opacity(0.15) : Color(.tertiarySystemFill))
                    .frame(width: 28, height: 28)
                Image(systemName: isSelected ? "checkmark" : "paintpalette")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? accent : Color.secondary)
            }

            // Name + lock badge
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(theme.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    if theme.isPremium {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                }
                Text(theme.id == "cleanLight" || theme.id == "paper"
                     ? "light keyboard"
                     : "dark keyboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            // Mini palette preview
            MiniPalettePreview(palette: theme.palette)
        }
        .contentShape(Rectangle())
    }
}

private struct MiniPalettePreview: View {
    let palette: Palette

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(palette.ink)
            .frame(width: 52, height: 30)
            .overlay {
                HStack(spacing: 3) {
                    // Two mock key shapes showing keyFill and accent text
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(palette.keyFill)
                        .frame(width: 18, height: 20)
                        .overlay {
                            Text("A")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(palette.text)
                        }
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(palette.keyFill)
                        .frame(width: 18, height: 20)
                        .overlay {
                            Text("b")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(palette.accent)
                        }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
    }
}
```

- [ ] **Step 2: Build to confirm it compiles**

```bash
xcodegen generate
xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add SarcasmKeyboard/Views/ThemeRow.swift
git commit -m "ThemeRow: palette mini-preview + Pro lock badge (parallel to PatternRow)

New ThemeRow view with a 52x30pt rounded-rect mini-preview showing the theme's
ink fill, two mock keys in keyFill, and accent-colored label. Pro themes show a
lock icon. Subtitle distinguishes light vs. dark keyboard themes."
```

---

## Task 7: `ProUpsellSheet` — add `init(lockedTheme:)`

**Files:**
- Modify: `SarcasmKeyboard/Views/ProUpsellSheet.swift`

The existing sheet accepts `lockedPattern: any SarcasmPattern` and uses
`lockedPattern.displayName` in the navigation title. Add a parallel init for themes
using a private enum to share the body.

- [ ] **Step 1: Replace `SarcasmKeyboard/Views/ProUpsellSheet.swift`**

```swift
import SwiftUI
import SarcasmKit

struct ProUpsellSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var accent: Color { Palette.default.accent(for: colorScheme) }

    private let lockedItemName: String

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
            .navigationTitle(lockedItemName)
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
```

The key change: `lockedPattern: any SarcasmPattern` is replaced by a private
`lockedItemName: String` stored at init time. Two inits supply it — one from a
pattern's `displayName`, one from a theme's `displayName`. The view body is
unchanged except `lockedPattern.displayName` → `lockedItemName`.

- [ ] **Step 2: Build**

```bash
xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Run full test suite**

```bash
swift test
```

Expected: 109 passed, 1 skipped.

- [ ] **Step 4: Commit**

```bash
git add SarcasmKeyboard/Views/ProUpsellSheet.swift
git commit -m "ProUpsellSheet: add init(lockedTheme:) alongside existing init(lockedPattern:)

Adds a second initializer that accepts a Theme instead of a SarcasmPattern.
Both inits share the view body via a private lockedItemName String. No
behavior change to existing pattern-upsell flow."
```

---

## Task 8: `ContentView.swift` — add Theme section, wire selection + upsell

**Files:**
- Modify: `SarcasmKeyboard/ContentView.swift`

Add `@State private var selectedThemeID`, a `themesSection` private property,
and wire the tap handler. Insert the Theme section between patternsSection
and aboutSection.

- [ ] **Step 1: Add state and theme section to `ContentView.swift`**

Make the following targeted edits to `SarcasmKeyboard/ContentView.swift`:

**Add two new `@State` properties** after `@State private var proPatternToUpsell`:

```swift
    @State private var selectedThemeID: String = SharedDefaults.selectedThemeID
    @State private var proThemeToUpsell: Theme?
```

**Add the `.sheet` for theme upsell** after the existing `proPatternToUpsell` sheet:

```swift
            .sheet(item: $proThemeToUpsell) { theme in
                ProUpsellSheet(lockedTheme: theme)
            }
```

**Replace the `patternsSection` and `aboutSection` call site in `body`** from:

```swift
                patternsSection
                aboutSection
```

to:

```swift
                patternsSection
                themesSection
                aboutSection
```

**Add the `themesSection` computed property** after `patternsSection`:

```swift
    private var themesSection: some View {
        Section {
            ForEach(ThemeCatalog.allThemes) { theme in
                Button {
                    tapTheme(theme)
                } label: {
                    ThemeRow(
                        theme: theme,
                        isSelected: theme.id == selectedThemeID
                    )
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Theme")
        } footer: {
            Text("Theme applies to the keyboard. Free themes work right away.")
        }
    }
```

**Add the `tapTheme` helper** after the existing `tap` pattern helper:

```swift
    private func tapTheme(_ theme: Theme) {
        if theme.isPremium {
            proThemeToUpsell = theme
            return
        }
        selectedThemeID = theme.id
        SharedDefaults.selectedThemeID = theme.id
    }
```

- [ ] **Step 2: Make `Theme` conform to `Identifiable` for the sheet binding**

`Theme` already conforms to `Identifiable` via its `id: String` property (declared in
`Theme.swift`). Confirm the sheet binding compiles — `item: $proThemeToUpsell` where
`proThemeToUpsell: Theme?` requires `Theme: Identifiable`. ✓ Already satisfied.

- [ ] **Step 3: Build**

```bash
xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Run full test suite**

```bash
swift test
```

Expected: 109 passed, 1 skipped.

- [ ] **Step 5: Launch + screenshot the companion app**

```bash
xcrun simctl install booted $(xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' -showBuildSettings 2>/dev/null | awk -F= '/ BUILT_PRODUCTS_DIR /{gsub(/^ +| +$/,"",$2); print $2"/SarcasmKeyboard.app"; exit}')
xcrun simctl terminate booted com.sarcasmkeyboard.app 2>/dev/null || true
xcrun simctl launch booted com.sarcasmkeyboard.app
xcrun simctl io booted screenshot /tmp/theme_picker.png
```

Read `/tmp/theme_picker.png`. Confirm:
- "Theme" section visible below "Style".
- 10 rows: Acid (checkmark), Clean Light, Clean Dark (no lock), then 7 rows with lock icons.
- Mini palette previews visible on the right side of each row.

- [ ] **Step 6: Tap a Pro theme — verify upsell sheet**

In the Simulator, tap "Neon" (or any Pro theme row). The `ProUpsellSheet` should
appear with "Neon" as the navigation title. Screenshot it:

```bash
xcrun simctl io booted screenshot /tmp/theme_upsell.png
```

Read `/tmp/theme_upsell.png`. Confirm: sheet title is the theme name, body matches
the existing upsell layout, "Unlock for $2.99" button is present but a no-op.

- [ ] **Step 7: Commit**

```bash
git add SarcasmKeyboard/ContentView.swift
git commit -m "ContentView: add Theme section with ThemeRow picker + Pro upsell

Adds selectedThemeID @State and a Theme section (10 rows, 3 free + 7 locked)
below the Style (patterns) section. Free taps write SharedDefaults.selectedThemeID.
Pro taps open ProUpsellSheet(lockedTheme:). Mini palette previews visible in
each ThemeRow."
```

---

## Task 9: End-to-end verification pass

**Files:** None to modify — verification only. If any criterion fails, fix in the
owning task, then return here and re-run.

**Visual changes to keyboard and picker: manual verification only via Simulator
screenshot loop. No automated tests.**

- [ ] **Step 1: Automated baseline**

```bash
swift test
```

Expected: 109 passed, 1 skipped.

```bash
xcodegen generate
xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 2: Theme picker — all 10 rows visible + correct lock state**

```bash
xcrun simctl boot 'iPhone 17' 2>/dev/null || true
xcrun simctl install booted $(xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' -showBuildSettings 2>/dev/null | awk -F= '/ BUILT_PRODUCTS_DIR /{gsub(/^ +| +$/,"",$2); print $2"/SarcasmKeyboard.app"; exit}')
xcrun simctl terminate booted com.sarcasmkeyboard.app 2>/dev/null || true
xcrun simctl launch booted com.sarcasmkeyboard.app
xcrun simctl io booted screenshot /tmp/verify_picker.png
```

Read `/tmp/verify_picker.png`. Check:
- [ ] "Theme" section present, 10 rows.
- [ ] Acid has checkmark (default selection).
- [ ] Clean Light and Clean Dark have no lock.
- [ ] Neon through Highlighter all have lock icons.
- [ ] Mini previews are visually distinct — Acid is lime-green, Terminal Green is
      green-on-black, Vaporwave is pink-on-purple, etc.

- [ ] **Step 3: Select Clean Light — confirm keyboard uses the light palette**

In the Simulator, tap "Clean Light" in the Theme section of the companion app.
Then switch to Notes.app and bring up the sarcasm keyboard:

```bash
xcrun simctl launch booted com.apple.mobilenotes
xcrun simctl io booted screenshot /tmp/verify_cleanlight.png
```

Read `/tmp/verify_cleanlight.png`. After switching to the sarcasm keyboard: keys
should be white on cream background, labels near-black, accent (strip, key press)
deep forest green. No lime anywhere.

- [ ] **Step 4: Select Acid — confirm return to default lime palette**

Back in the companion app, select Acid. Re-open Notes and re-check:

```bash
xcrun simctl terminate booted com.apple.mobilenotes 2>/dev/null || true
xcrun simctl launch booted com.apple.mobilenotes
xcrun simctl io booted screenshot /tmp/verify_acid.png
```

Read `/tmp/verify_acid.png`. Keyboard returns to lime-on-ink.

- [ ] **Step 5: App Group round-trip — keyboard selection → companion app**

The keyboard's pattern-cycle strip changes `selectedPatternID` but not
`selectedThemeID`. Confirm theme persists across app/extension boundary:
Select "Clean Dark" in the companion app. Switch to Notes, type something,
switch back to the companion app:

```bash
xcrun simctl terminate booted com.sarcasmkeyboard.app 2>/dev/null || true
xcrun simctl launch booted com.sarcasmkeyboard.app
xcrun simctl io booted screenshot /tmp/verify_roundtrip.png
```

Read `/tmp/verify_roundtrip.png`. "Clean Dark" should have the checkmark. ✓

- [ ] **Step 6: Pro upsell — correct theme name in title**

Tap "Terminal Green" (Pro) in the companion app. Sheet should open with
"Terminal Green" in the navigation title:

```bash
xcrun simctl io booted screenshot /tmp/verify_upsell.png
```

Read `/tmp/verify_upsell.png`. Confirm title = "Terminal Green", sheet body
matches the standard upsell layout. ✓

- [ ] **Step 7: Light mode + dark mode companion app**

```bash
xcrun simctl ui booted appearance light
xcrun simctl terminate booted com.sarcasmkeyboard.app 2>/dev/null || true
xcrun simctl launch booted com.sarcasmkeyboard.app
xcrun simctl io booted screenshot /tmp/verify_lightmode.png
```

Read `/tmp/verify_lightmode.png`. Companion app light mode: lock icons and
selection checkmarks use the `accentOnLight` color (deeper, readable on white).
Theme mini-previews still show the keyboard palette (not the app palette).

```bash
xcrun simctl ui booted appearance dark
xcrun simctl terminate booted com.sarcasmkeyboard.app 2>/dev/null || true
xcrun simctl launch booted com.sarcasmkeyboard.app
xcrun simctl io booted screenshot /tmp/verify_darkmode.png
```

Read `/tmp/verify_darkmode.png`. Dark mode: lime accent on dark background.

- [ ] **Step 8: Memory spot-check**

Attach Instruments' Allocations instrument to the keyboard extension process
(Xcode → Product → Profile, select the `SarcasmKeyboardExtension` process).
Switch themes via the companion app (free ones; Pro are locked), kill and
reopen the keyboard to trigger `viewDidLoad` with each new theme. Check peak
memory stays under 48MB. Themes are pure `Color` tokens — no images loaded —
so this should pass comfortably. If it doesn't, investigate the
`UIHostingController.rootView` rebuild path for retain cycles.

- [ ] **Step 9: Final commit (if any polish fixes applied during this task)**

If no changes were needed, skip. If any pixel-level adjustments were made:

```bash
git add -A
git commit -m "Polish: verification-pass fixes

<list specific nits addressed>"
```

---

## Self-review

**Spec coverage:**
- Theme type + ThemeCatalog + 10 instances → Task 1. ✓
- SharedDefaults.selectedThemeID → Task 2. ✓
- Palette.default alias → Task 3. ✓
- KeyboardView/KeyButton/Strip palette param threading → Task 4. ✓
- KeyboardViewController makeKeyboardView palette wiring → Task 5. ✓
- ThemeRow with mini-preview → Task 6. ✓
- ProUpsellSheet init(lockedTheme:) → Task 7. ✓
- ContentView Theme section → Task 8. ✓
- End-to-end verification → Task 9. ✓

**No TBD hex values:** All 70 token values (10 themes × 7 tokens) are specified in
the spec with exact hex. `Theme.swift` in Task 1 has all of them as literals. ✓

**No `Co-Authored-By: Claude` trailers in any commit.** ✓

**Test count progression:**
- Start: 98 passed, 1 skipped.
- After Task 1: 105 passed, 1 skipped (+7 ThemeCatalogTests).
- After Task 2: 109 passed, 1 skipped (+4 SharedDefaultsTests).
- Tasks 3–9: 109 passed, 1 skipped (no new tests; visual-only changes).

**Task 4 intermediate broken state is documented** (Step 3 explicitly notes the
expected compile failure) and the commit spans Tasks 4+5 to keep history bisectable. ✓
