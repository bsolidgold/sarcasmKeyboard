# Visual System & Keyboard Reskin — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the two Phase 3.5 deliverables (app icon + keyboard reskin) and lock the product's visual system on a dark-by-default palette with a single lime accent, with a new tap-to-cycle active-pattern strip above the keyboard keys.

**Architecture:** A shared `Palette` struct in `SarcasmKit/Design/` supplies color tokens to both the companion app and the keyboard extension. A pure `PatternCycler` helper lives in `SarcasmKit/Engine/` so the cycle logic is unit-testable. The app icon is authored in SwiftUI (`IconView` in the framework) and rendered to PNG via a gated test using `ImageRenderer`. No new runtime dependencies.

**Tech Stack:** Swift 5.9, SwiftUI (iOS 17+), XCTest, SwiftPM (for `SarcasmKit` + tests), XcodeGen (regenerates `.xcodeproj`), `xcodebuild`, `xcrun simctl` (Simulator screenshots), `xcrun actool` is not needed — asset catalog is consumed by Xcode directly.

**Spec:** [`docs/superpowers/specs/2026-04-21-visual-system-and-keyboard-reskin-design.md`](../specs/2026-04-21-visual-system-and-keyboard-reskin-design.md)

---

## Conventions used throughout this plan

- **Package root:** `/Users/bretgold/Documents/gitHub/sarcasmKeyboard/`. All `swift test`, `xcodegen`, and `xcodebuild` commands are run from there.
- **Running the app + extension:** regenerate project with `xcodegen generate`, then build with `xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build`.
- **Screenshot loop:** `xcrun simctl io booted screenshot /tmp/sk.png` then `Read /tmp/sk.png` to inspect.
- **Commits:** Small, one-concern commits after each task. **No `Co-Authored-By: Claude` trailer** (enforced by `.githooks/commit-msg`).
- **Tests baseline:** `swift test` is currently green at 91/91. This must remain true after every task except where explicitly adding a new passing test count.

---

## Task 1: Foundation — `Palette.swift`, `Typography` trim, delete orphaned `Theme.swift`

**Files:**
- Create: `Sources/SarcasmKit/Design/Palette.swift`
- Modify: `Sources/SarcasmKit/Design/Typography.swift` (trim unused)
- Delete: `Sources/SarcasmKit/Design/Theme.swift`

- [ ] **Step 1: Create `Sources/SarcasmKit/Design/Palette.swift`**

```swift
import SwiftUI

public struct Palette: Sendable, Equatable {
    // Keyboard (always dark)
    public let ink: Color              // #0A0A0A — keyboard background, app dark-mode background
    public let keyFill: Color          // #1C1C1E — letter keys
    public let systemKeyFill: Color    // #2C2C2E — shift/space/return/delete
    public let topHighlight: Color     // #3A3A3C — 1px highlight on the top edge of keys
    public let accent: Color           // #B8FF2A — lime, used sparingly

    // Text (on dark surfaces)
    public let text: Color             // #F2F2F7 — primary on dark
    public let subtleText: Color       // #8E8E93 — secondary on dark

    public init(
        ink: Color,
        keyFill: Color,
        systemKeyFill: Color,
        topHighlight: Color,
        accent: Color,
        text: Color,
        subtleText: Color
    ) {
        self.ink = ink
        self.keyFill = keyFill
        self.systemKeyFill = systemKeyFill
        self.topHighlight = topHighlight
        self.accent = accent
        self.text = text
        self.subtleText = subtleText
    }

    public static let `default` = Palette(
        ink: Color(hex: 0x0A0A0A),
        keyFill: Color(hex: 0x1C1C1E),
        systemKeyFill: Color(hex: 0x2C2C2E),
        topHighlight: Color(hex: 0x3A3A3C),
        accent: Color(hex: 0xB8FF2A),
        text: Color(hex: 0xF2F2F7),
        subtleText: Color(hex: 0x8E8E93)
    )
}

extension Color {
    public init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex & 0xFF0000) >> 16) / 255
        let g = Double((hex & 0x00FF00) >> 8) / 255
        let b = Double(hex & 0x0000FF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
```

- [ ] **Step 2: Trim `Sources/SarcasmKit/Design/Typography.swift` to used extensions only**

Replace entire file contents with:

```swift
import SwiftUI

extension Font {
    public static let sarcasmTitle = Font.system(size: 22, weight: .bold, design: .monospaced)
    public static let sarcasmMono = Font.system(size: 16, weight: .regular, design: .monospaced)
    public static let sarcasmMonoSmall = Font.system(size: 13, weight: .regular, design: .monospaced)
}
```

- [ ] **Step 3: Delete `Sources/SarcasmKit/Design/Theme.swift`**

Run: `rm Sources/SarcasmKit/Design/Theme.swift`

- [ ] **Step 4: Build the SarcasmKit package to confirm the refactor compiles cleanly**

Run: `swift build`
Expected: `Build complete!` with no errors. Any leftover reference to `Theme.*` or a deleted `Font.sarcasmHeadline`/`sarcasmBody`/`sarcasmMega`/`sarcasmLabel`/`sarcasmTight`/`sarcasmLoose` surfaces as a compile error — fix by removing the reference (none of these are expected to exist outside the deleted file, but verify).

- [ ] **Step 5: Run the test suite to confirm no regressions**

Run: `swift test`
Expected: `Test Suite 'All tests' passed`, 91 tests passed.

- [ ] **Step 6: Regenerate the Xcode project and build the app + extension**

Run: `xcodegen generate`
Expected: `Loaded project ... Created project at SarcasmKeyboard.xcodeproj`.

Run: `xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 7: Commit**

```bash
git add Sources/SarcasmKit/Design/Palette.swift Sources/SarcasmKit/Design/Typography.swift
git rm Sources/SarcasmKit/Design/Theme.swift
git commit -m "Design foundation: Palette tokens + Typography trim; delete orphan Theme

Introduces Palette.default (ink #0A0A0A, lime accent #B8FF2A, key fills, text
colors) as the shared color system for both the companion app and the keyboard
extension. Typography trimmed to the three monospaced sizes actually consumed
(sarcasmTitle, sarcasmMono, sarcasmMonoSmall). Theme.swift (memeMax/terminal)
had zero references and is removed wholesale; Color(hex:) helper relocated
to Palette.swift."
```

---

## Task 2: `PatternCycler` (pure logic, TDD)

**Files:**
- Create: `Sources/SarcasmKit/Engine/PatternCycler.swift`
- Create: `Tests/SarcasmKitTests/PatternCyclerTests.swift`

**Why separate:** The keyboard's new strip will cycle through free patterns. Keeping the "which pattern is next?" logic pure and tested means the extension-side wiring stays a thin call site, and we exercise edge cases (Pro filtering, unknown current ID, single-pattern list) without a Simulator.

- [ ] **Step 1: Write the failing tests**

Create `Tests/SarcasmKitTests/PatternCyclerTests.swift`:

```swift
import XCTest
@testable import SarcasmKit

final class PatternCyclerTests: XCTestCase {
    func testCyclesToNextFreePattern() {
        let patterns = SarcasmEngine.allPatterns
        let next = PatternCycler.next(currentID: "alternating", in: patterns)
        XCTAssertEqual(next, "spongebob")
    }

    func testSkipsPremiumPatterns() {
        let patterns = SarcasmEngine.allPatterns
        // wordToggle is free; next free after wordToggle must skip smallCaps (pro) and zalgo (pro)
        // so it must wrap back to alternating.
        let next = PatternCycler.next(currentID: "wordToggle", in: patterns)
        XCTAssertEqual(next, "alternating")
    }

    func testWrapsAtEndOfFreeList() {
        let patterns = SarcasmEngine.allPatterns
        // Assume free-list ends at wordToggle; start from last free pattern → wrap.
        let lastFreeID = patterns.last(where: { !$0.isPremium })?.id ?? ""
        let next = PatternCycler.next(currentID: lastFreeID, in: patterns)
        let firstFreeID = patterns.first(where: { !$0.isPremium })?.id ?? ""
        XCTAssertEqual(next, firstFreeID)
    }

    func testUnknownCurrentIDReturnsFirstFree() {
        let patterns = SarcasmEngine.allPatterns
        let next = PatternCycler.next(currentID: "nonexistent", in: patterns)
        let firstFreeID = patterns.first(where: { !$0.isPremium })?.id ?? ""
        XCTAssertEqual(next, firstFreeID)
    }

    func testCurrentIsPremiumFallsThroughToFirstFree() {
        let patterns = SarcasmEngine.allPatterns
        let next = PatternCycler.next(currentID: "smallCaps", in: patterns)
        let firstFreeID = patterns.first(where: { !$0.isPremium })?.id ?? ""
        XCTAssertEqual(next, firstFreeID)
    }

    func testEmptyFreeListReturnsCurrent() {
        let next = PatternCycler.next(currentID: "alternating", in: [SmallCapsPattern(), ZalgoPattern()])
        XCTAssertEqual(next, "alternating")
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `swift test --filter PatternCyclerTests`
Expected: Fails with `error: no such module 'PatternCycler'` or `use of unresolved identifier 'PatternCycler'`.

- [ ] **Step 3: Implement `PatternCycler`**

Create `Sources/SarcasmKit/Engine/PatternCycler.swift`:

```swift
import Foundation

public enum PatternCycler {
    /// Returns the ID of the next free pattern after `currentID`, wrapping around.
    /// If the free list is empty, returns `currentID` unchanged.
    /// If `currentID` is unknown or premium, returns the first free pattern's ID.
    public static func next(currentID: String, in patterns: [any SarcasmPattern]) -> String {
        let free = patterns.filter { !$0.isPremium }
        guard !free.isEmpty else { return currentID }
        guard let currentIndex = free.firstIndex(where: { $0.id == currentID }) else {
            return free[0].id
        }
        let nextIndex = (currentIndex + 1) % free.count
        return free[nextIndex].id
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `swift test --filter PatternCyclerTests`
Expected: 6 tests passed.

- [ ] **Step 5: Run the full suite to confirm no regressions**

Run: `swift test`
Expected: 97 tests passed (91 existing + 6 new).

- [ ] **Step 6: Commit**

```bash
git add Sources/SarcasmKit/Engine/PatternCycler.swift Tests/SarcasmKitTests/PatternCyclerTests.swift
git commit -m "PatternCycler: pure next-free-pattern helper with 6 unit tests

Extracts the 'advance the selected pattern to the next free one' logic out
of the keyboard extension so it's testable without a Simulator. Handles
wrap-around, Pro filtering, unknown current IDs, currently-selected Pro
pattern (fall through to first free), and an all-Pro list (no-op)."
```

---

## Task 3: `IconView` — SwiftUI source for the app icon

**Files:**
- Create: `Sources/SarcasmKit/Design/IconView.swift`

- [ ] **Step 1: Create `IconView.swift`**

```swift
import SwiftUI

public struct IconView: View {
    public enum Variant {
        case primary    // lime on ink — default home-screen icon
        case tinted     // white on transparent — iOS 18 tinted mode
    }

    public let variant: Variant

    public init(variant: Variant = .primary) {
        self.variant = variant
    }

    public var body: some View {
        ZStack {
            background
            Text("aA")
                .font(.system(size: 640, weight: .black, design: .rounded))
                .foregroundStyle(foreground)
                .tracking(-40)
        }
        .frame(width: 1024, height: 1024)
    }

    @ViewBuilder private var background: some View {
        switch variant {
        case .primary: Palette.default.ink
        case .tinted:  Color.clear
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary: Palette.default.accent
        case .tinted:  .white
        }
    }
}

#Preview("Primary") { IconView().frame(width: 256, height: 256).scaleEffect(0.25) }
#Preview("Tinted")  { IconView(variant: .tinted).frame(width: 256, height: 256).scaleEffect(0.25) }
```

- [ ] **Step 2: Build to confirm it compiles**

Run: `swift build`
Expected: `Build complete!`.

- [ ] **Step 3: Commit**

```bash
git add Sources/SarcasmKit/Design/IconView.swift
git commit -m "IconView: SwiftUI source for the app icon (lime aA on ink, tinted variant)

Authors the icon in-repo as a pure SwiftUI view so it's re-renderable when
the palette shifts in Phase 4. Two variants: primary (lime on ink) and
tinted (white on transparent) for iOS 18 tinted mode. Rendering to PNG
lands in Task 4."
```

---

## Task 4: Render icon PNGs + wire asset catalog

**Files:**
- Create: `Tests/SarcasmKitTests/IconRendererTests.swift`
- Create: `SarcasmKeyboard/Assets.xcassets/Contents.json`
- Create: `SarcasmKeyboard/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create (via render): `SarcasmKeyboard/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`
- Create (via render): `SarcasmKeyboard/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark-1024.png`
- Create (via render): `SarcasmKeyboard/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted-1024.png`

- [ ] **Step 1: Create the asset catalog skeleton**

Create `SarcasmKeyboard/Assets.xcassets/Contents.json`:

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Create `SarcasmKeyboard/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images" : [
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        { "appearance" : "luminosity", "value" : "dark" }
      ],
      "filename" : "AppIcon-Dark-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        { "appearance" : "luminosity", "value" : "tinted" }
      ],
      "filename" : "AppIcon-Tinted-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 2: Write the renderer test (gated by env var)**

Create `Tests/SarcasmKitTests/IconRendererTests.swift`:

```swift
import XCTest
import SwiftUI
@testable import SarcasmKit

#if canImport(AppKit)
import AppKit
#endif

final class IconRendererTests: XCTestCase {
    /// Runs only when RENDER_ICON=1. Emits three PNGs into the asset catalog.
    func testRenderAppIconVariants() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["RENDER_ICON"] == "1",
            "Set RENDER_ICON=1 to render app icon PNGs."
        )

        let outputDir = Self.assetCatalogDirectory()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        try renderPNG(IconView(variant: .primary), to: outputDir.appendingPathComponent("AppIcon-1024.png"))
        // Dark is identical to primary — our icon is already dark-native. iOS uses it under Dark appearance.
        try renderPNG(IconView(variant: .primary), to: outputDir.appendingPathComponent("AppIcon-Dark-1024.png"))
        try renderPNG(IconView(variant: .tinted),  to: outputDir.appendingPathComponent("AppIcon-Tinted-1024.png"))
    }

    private func renderPNG<V: View>(_ view: V, to url: URL) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        guard let cgImage = renderer.cgImage else {
            throw NSError(domain: "IconRenderer", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "ImageRenderer returned nil for \(url.lastPathComponent)"])
        }
        #if canImport(AppKit)
        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "IconRenderer", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "PNG encoding failed for \(url.lastPathComponent)"])
        }
        try data.write(to: url)
        #else
        throw NSError(domain: "IconRenderer", code: 3,
                      userInfo: [NSLocalizedDescriptionKey: "PNG encoding requires AppKit (macOS)."])
        #endif
    }

    /// Resolves the asset-catalog output directory relative to this source file.
    private static func assetCatalogDirectory() -> URL {
        let thisFile = URL(fileURLWithPath: #filePath)
        // Tests/SarcasmKitTests/IconRendererTests.swift → repo root is two levels up
        let repoRoot = thisFile.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return repoRoot
            .appendingPathComponent("SarcasmKeyboard")
            .appendingPathComponent("Assets.xcassets")
            .appendingPathComponent("AppIcon.appiconset")
    }
}
```

- [ ] **Step 3: Verify the test skips without the env var (no regression)**

Run: `swift test`
Expected: 98 tests total; `IconRendererTests.testRenderAppIconVariants` reports "skipped". All other tests pass.

- [ ] **Step 4: Render the PNGs**

Run: `RENDER_ICON=1 swift test --filter IconRendererTests`
Expected: 1 test passed. Three new PNGs exist:

```bash
ls -la SarcasmKeyboard/Assets.xcassets/AppIcon.appiconset/
```

Should show:
- `Contents.json`
- `AppIcon-1024.png` (~ a few hundred KB)
- `AppIcon-Dark-1024.png`
- `AppIcon-Tinted-1024.png`

- [ ] **Step 5: Preview the primary PNG and confirm it reads as expected**

Open the PNG to eyeball it:

```bash
open SarcasmKeyboard/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
```

You're looking for: lime `aA` on ink, letterforms butted together, no visible whitespace cruft, the "a" and "A" both fully visible (not cut off). If the tracking (-40) clipped too much, adjust to `-30` in `IconView.swift` and re-run Step 4.

- [ ] **Step 6: Regenerate project, build, install, screenshot the home screen**

```bash
xcodegen generate
xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Boot a simulator and install:

```bash
xcrun simctl boot 'iPhone 17' 2>/dev/null || true
xcrun simctl install booted $(xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' -showBuildSettings | awk -F= '/ BUILT_PRODUCTS_DIR /{gsub(/^ +| +$/,"",$2); print $2"/SarcasmKeyboard.app"; exit}')
xcrun simctl io booted screenshot /tmp/home.png
```

Read `/tmp/home.png` and confirm the lime `aA` icon is on the home screen.

- [ ] **Step 7: Commit**

```bash
git add Tests/SarcasmKitTests/IconRendererTests.swift \
        SarcasmKeyboard/Assets.xcassets/Contents.json \
        SarcasmKeyboard/Assets.xcassets/AppIcon.appiconset/Contents.json \
        SarcasmKeyboard/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png \
        SarcasmKeyboard/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark-1024.png \
        SarcasmKeyboard/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted-1024.png
git commit -m "App icon: render lime aA mark via ImageRenderer + wire asset catalog

Adds Tests/SarcasmKitTests/IconRendererTests (gated on RENDER_ICON=1) that
uses SwiftUI's ImageRenderer to emit 1024x1024 PNGs from IconView — primary,
dark, and tinted variants. Adds Assets.xcassets skeleton + AppIcon.appiconset
Contents.json with iOS 17 single-size schema. Icon now renders on the
Simulator home screen."
```

---

## Task 5: Companion app repaint — `ContentView.swift`

**Files:**
- Modify: `SarcasmKeyboard/ContentView.swift`

- [ ] **Step 1: Replace `ContentView.swift` with the repainted version**

Replace the entire file with:

```swift
import SwiftUI
import SarcasmKit

struct ContentView: View {
    @State private var selectedPatternID: String = SharedDefaults.selectedPatternID
    @State private var playgroundInput: String = "the quick brown fox"
    @State private var needsSetup: Bool = KeyboardStatus.shouldShowSetupBanner
    @State private var showInstallGuide = false
    @State private var proPatternToUpsell: AnyHashablePattern?

    private var patterns: [any SarcasmPattern] { SarcasmEngine.allPatterns }
    private var currentPattern: any SarcasmPattern {
        SarcasmEngine.pattern(id: selectedPatternID) ?? AlternatingPattern()
    }

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
        .tint(Palette.default.accent)
    }

    private func rerollPattern() {
        let nextID = PatternCycler.next(currentID: selectedPatternID, in: patterns)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedPatternID = nextID
        }
        SharedDefaults.selectedPatternID = nextID
    }

    private var setupSection: some View {
        Section {
            Button {
                showInstallGuide = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "keyboard.badge.ellipsis")
                        .font(.callout)
                        .foregroundStyle(Palette.default.accent)
                        .frame(width: 28, height: 28)
                        .background(Palette.default.accent.opacity(0.15), in: Circle())
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
        .listRowBackground(Palette.default.accent.opacity(0.10))
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
                    .foregroundStyle(Palette.default.accent)
                    .padding(.top, 2)
                Text(currentPattern.transform(playgroundInput.isEmpty ? "type something to see it transformed" : playgroundInput))
                    .font(.sarcasmMono)
                    .foregroundStyle(Palette.default.accent)
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
```

Changes relative to the previous file:
- Dropped the `extension Color { static let appAccent = ... }` definition (burnt orange).
- `.tint(.appAccent)` → `.tint(Palette.default.accent)`.
- `.listStyle(.insetGrouped)` → `.listStyle(.plain)`, `.scrollContentBackground(.hidden)`, explicit system background.
- Setup button accent orange → `Palette.default.accent`.
- `rerollPattern()` now delegates to `PatternCycler.next(...)` instead of the inline random-filter logic.
- Playground transformed text font `.system(.subheadline, design: .monospaced)` → `.sarcasmMono`; color → `Palette.default.accent`.
- Copy: "Not sure if it's installed yet. Swipe left to dismiss forever." → "Not sure if it's installed. Swipe left to dismiss." (drops "yet"/"forever" filler).
- "keyboard NOT installed (sarcastic nudge)" wasn't in the shipped version, but any parentheticals of that ilk are stripped.

- [ ] **Step 2: Build the app to confirm compiles**

```bash
xcodegen generate
xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Launch, screenshot, inspect**

```bash
xcrun simctl boot 'iPhone 17' 2>/dev/null || true
xcrun simctl install booted $(xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' -showBuildSettings | awk -F= '/ BUILT_PRODUCTS_DIR /{gsub(/^ +| +$/,"",$2); print $2"/SarcasmKeyboard.app"; exit}')
xcrun simctl launch booted com.sarcasmkeyboard.app
xcrun simctl io booted screenshot /tmp/app.png
```

Read `/tmp/app.png`. You're looking for:
- No burnt-orange anywhere.
- Title re-casing "Sarcasm Keyboard" via the current pattern.
- Lime accent on: setup chevron/icon, playground arrow+text, selected pattern check (Task 6 will finalize this).
- Plain list (no grouped cards, no inset backgrounds except the tinted setup row).

- [ ] **Step 4: Commit**

```bash
git add SarcasmKeyboard/ContentView.swift
git commit -m "ContentView: drop burnt-orange accent, adopt Palette tokens + plain list

Swaps the ad-hoc Color.appAccent for Palette.default.accent (lime), converts
insetGrouped → plain list with hidden scroll background, delegates the
reroll button to PatternCycler.next, and prunes filler copy from the setup
footer. No behavior change beyond the cycle helper swap; visual only."
```

---

## Task 6: `PatternRow.swift` — lime accent + mono sample text

**Files:**
- Modify: `SarcasmKeyboard/Views/PatternRow.swift`

- [ ] **Step 1: Replace `PatternRow.swift` with the repainted version**

```swift
import SwiftUI
import SarcasmKit

struct PatternRow: View {
    let pattern: any SarcasmPattern
    let isSelected: Bool

    private let sampleText = "The quick brown fox jumps"

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isSelected ? Palette.default.accent.opacity(0.15) : Color(.tertiarySystemFill))
                    .frame(width: 28, height: 28)
                Image(systemName: isSelected ? "checkmark" : symbolName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? Palette.default.accent : .secondary)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(pattern.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    if pattern.isPremium {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Palette.default.accent)
                    }
                }
                Text(pattern.transform(sampleText))
                    .font(.sarcasmMonoSmall)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }

    private var symbolName: String {
        switch pattern.id {
        case "alternating": return "character.cursor.ibeam"
        case "spongebob": return "face.smiling"
        case "random": return "dice"
        case "wordToggle": return "textformat"
        case "smallCaps": return "textformat.size.smaller"
        case "zalgo": return "sparkles"
        default: return "character"
        }
    }
}
```

Changes: `Color.accentColor` → `Palette.default.accent`, `.orange` Pro lock → `Palette.default.accent`, sample text `.font(.system(.caption, design: .monospaced))` → `.font(.sarcasmMonoSmall)`.

- [ ] **Step 2: Build + screenshot**

```bash
xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
xcrun simctl install booted $(xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' -showBuildSettings | awk -F= '/ BUILT_PRODUCTS_DIR /{gsub(/^ +| +$/,"",$2); print $2"/SarcasmKeyboard.app"; exit}')
xcrun simctl launch booted com.sarcasmkeyboard.app
xcrun simctl io booted screenshot /tmp/rows.png
```

Read `/tmp/rows.png`. Confirm:
- Selected pattern's check circle is lime-tinted.
- Pro patterns (Small Caps, Zalgo) have a lime lock, not orange.
- Sample transformed text under each pattern renders in SF Mono small, secondary color.

- [ ] **Step 3: Commit**

```bash
git add SarcasmKeyboard/Views/PatternRow.swift
git commit -m "PatternRow: lime accent, mono sample text

Selected check + pro lock both use Palette.default.accent. Sample sentence
switches to .sarcasmMonoSmall for consistency with the rest of the app's
transformed-text typography."
```

---

## Task 7: Sheet repaints — `InstallGuideSheet.swift` + `ProUpsellSheet.swift`

**Files:**
- Modify: `SarcasmKeyboard/Views/InstallGuideSheet.swift`
- Modify: `SarcasmKeyboard/Views/ProUpsellSheet.swift`

**Pattern:** Replace any occurrence of `.orange`, `Color.accentColor`, or `Color(red: 0.92, green: 0.42, blue: 0.22)` (the burnt-orange literal, in case it leaked into sheets) with `Palette.default.accent`. Swap any system-body monospaced fonts used for transformed-text demos to `.sarcasmMono` or `.sarcasmMonoSmall` as appropriate.

- [ ] **Step 1: Read the current files to identify every accent/color callsite**

```bash
rg -n 'orange|accentColor|appAccent|Color\(red:' SarcasmKeyboard/Views/InstallGuideSheet.swift SarcasmKeyboard/Views/ProUpsellSheet.swift
```

Expected output: every line that references a non-palette tint. List them.

- [ ] **Step 2: Replace each matched line with the palette equivalent**

For each match, apply:
- `Color.orange` or `.orange` (as a foreground/background) → `Palette.default.accent`
- `Color.orange.opacity(x)` → `Palette.default.accent.opacity(x)`
- `Color.accentColor` → `Palette.default.accent`
- Literal burnt-orange RGB → `Palette.default.accent`

Use `Edit` with each exact line replaced. Keep all other formatting and behavior unchanged.

- [ ] **Step 3: Build + re-screenshot both sheets**

```bash
xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
xcrun simctl install booted $(xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' -showBuildSettings | awk -F= '/ BUILT_PRODUCTS_DIR /{gsub(/^ +| +$/,"",$2); print $2"/SarcasmKeyboard.app"; exit}')
xcrun simctl launch booted com.sarcasmkeyboard.app
```

Manually tap "Install the keyboard" in the Simulator (click with the mouse / use `xcrun simctl` UI automation if automating), screenshot, then tap a Pro pattern to trigger the upsell, screenshot. Confirm no orange visible in either sheet.

- [ ] **Step 4: Confirm no orange references remain**

```bash
rg -n 'orange|accentColor|appAccent' SarcasmKeyboard/Views/InstallGuideSheet.swift SarcasmKeyboard/Views/ProUpsellSheet.swift
```

Expected: no matches (outside of legitimate SF Symbol names that happen to contain "orange"; there are none in these files).

- [ ] **Step 5: Commit**

```bash
git add SarcasmKeyboard/Views/InstallGuideSheet.swift SarcasmKeyboard/Views/ProUpsellSheet.swift
git commit -m "Sheets: repaint InstallGuide and ProUpsell to Palette accent

Both sheets' orange/systemAccent tints move to Palette.default.accent. No
structural changes; preserves existing layout, copy, and behavior."
```

---

## Task 8: `KeyButton.swift` — dark fills, mono labels, lime press flash

**Files:**
- Modify: `SarcasmKeyboardExtension/KeyButton.swift`

- [ ] **Step 1: Replace `KeyButton.swift`**

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
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(style == .letter ? .sarcasmMono : .sarcasmMonoSmall)
                .foregroundColor(Palette.default.text)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(isPressed ? Palette.default.accent.opacity(0.30) : backgroundColor)
                        // 1pt top-edge highlight — rendered as a thin strip above a clip mask
                        VStack(spacing: 0) {
                            Palette.default.topHighlight
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
        case .letter: return Palette.default.keyFill
        case .system: return Palette.default.systemKeyFill
        }
    }
}
```

Changes:
- Fills use `Palette.default.keyFill` / `systemKeyFill` instead of system colors.
- Text uses `Palette.default.text` (off-white) and `.sarcasmMono` / `.sarcasmMonoSmall`.
- Corner radius 6 → 5 (slightly less puffy).
- Drop shadow removed.
- Press state now = 80ms flash to `accent.opacity(0.30)` instead of a scale effect.
- 1pt top-edge highlight rendered via a `VStack` + clip mask (no stroke-only-top API in SwiftUI, so this is the clean idiom).

- [ ] **Step 2: Build the extension**

```bash
xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Install + verify on Simulator**

Install the app (includes the embedded extension), enable the keyboard once manually via Settings → General → Keyboard → Keyboards → Add New Keyboard → Sarcasm Keyboard. Then:

```bash
xcrun simctl launch booted com.apple.mobilenotes
xcrun simctl io booted screenshot /tmp/keys.png
```

Tap into a note, switch to the sarcasm keyboard via the globe key, screenshot again. You're verifying: keys are dark, labels are mono off-white, pressing a key flashes lime briefly, 1px highlight visible on the top edge of each key.

- [ ] **Step 4: Commit**

```bash
git add SarcasmKeyboardExtension/KeyButton.swift
git commit -m "KeyButton: dark Palette fill, mono labels, 1pt top highlight, lime press flash

Replaces the generic system-color keys with Palette-driven dark fills. Labels
move to SF Mono (.sarcasmMono for letters, .sarcasmMonoSmall for system keys).
Press animation is now an 80ms flash to Palette accent at 30% opacity — reads
better on dark than a scale effect would. Added a 1pt top-edge highlight via
VStack + clip mask for subtle key separation."
```

---

## Task 9: `KeyboardView.swift` — dark background + active-pattern strip

**Files:**
- Modify: `SarcasmKeyboardExtension/KeyboardView.swift`

- [ ] **Step 1: Replace `KeyboardView.swift`**

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

    private let row1: [Character] = ["q","w","e","r","t","y","u","i","o","p"]
    private let row2: [Character] = ["a","s","d","f","g","h","j","k","l"]
    private let row3: [Character] = ["z","x","c","v","b","n","m"]

    var body: some View {
        VStack(spacing: 0) {
            ActivePatternStrip(pattern: currentPattern, onTap: onCyclePattern)
            keyRows
        }
        .background(Palette.default.ink)
    }

    private var keyRows: some View {
        VStack(spacing: 6) {
            letterRow(row1)
            letterRow(row2)
                .padding(.horizontal, 18)
            HStack(spacing: 6) {
                ForEach(Array(row3), id: \.self) { c in
                    KeyButton(label: String(c), style: .letter) { onLetter(c) }
                }
                KeyButton(label: "⌫", style: .system, action: onDelete)
                    .frame(width: 56)
            }
            HStack(spacing: 6) {
                KeyButton(label: "🌐", style: .system, action: onGlobe)
                    .frame(width: 44)
                KeyButton(label: ".", style: .system) { onPunctuation(".") }
                    .frame(width: 40)
                KeyButton(label: ",", style: .system) { onPunctuation(",") }
                    .frame(width: 40)
                KeyButton(label: "space", style: .system, action: onSpace)
                KeyButton(label: "return", style: .system, action: onReturn)
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
                KeyButton(label: String(c), style: .letter) { onLetter(c) }
            }
        }
    }
}

private struct ActivePatternStrip: View {
    let pattern: any SarcasmPattern
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text("•")
                    .font(.sarcasmMonoSmall)
                    .foregroundStyle(Palette.default.accent)
                Text(pattern.transform(pattern.displayName))
                    .font(.sarcasmMonoSmall)
                    .foregroundStyle(Palette.default.accent)
                Text("▾")
                    .font(.sarcasmMonoSmall)
                    .foregroundStyle(Palette.default.accent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(
                ZStack {
                    Palette.default.ink
                    if isPressed {
                        Palette.default.accent.opacity(0.15)
                    }
                    VStack {
                        Palette.default.accent.frame(height: 1)
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

Changes:
- Outer `.background(Color(.systemGray6))` → `.background(Palette.default.ink)`.
- `VStack(spacing: 6)` split into outer (strip + keyRows, spacing 0) and inner (rows, spacing 6).
- New `ActivePatternStrip` private view: 30pt tall, ink background, hairline lime top border, centered mono label `• <pattern-transformed-name> ▾`, tappable → calls `onCyclePattern`, brief lime flash on press.
- Two new parameters on `KeyboardView`: `onCyclePattern` and `currentPattern`.

- [ ] **Step 2: Build — expect it to fail because `KeyboardViewController` hasn't been updated yet**

```bash
xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: build fails in `KeyboardViewController.swift` — `missing argument for parameter 'onCyclePattern'` and `missing argument for parameter 'currentPattern'`. That's the signal to move to Task 10.

**Do not commit yet** — the project is in a broken intermediate state. Task 10's commit will cover both files so history stays green.

---

## Task 10: `KeyboardViewController.swift` — wire cycle callback + rebuild on cycle

**Files:**
- Modify: `SarcasmKeyboardExtension/KeyboardViewController.swift`

- [ ] **Step 1: Replace `KeyboardViewController.swift`**

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
            onLetter: { [weak self] char in self?.handleLetter(char) },
            onPunctuation: { [weak self] char in self?.handlePunctuation(char) },
            onSpace: { [weak self] in self?.handleLetter(" ") },
            onDelete: { [weak self] in self?.textDocumentProxy.deleteBackward() },
            onReturn: { [weak self] in self?.textDocumentProxy.insertText("\n") },
            onGlobe: { [weak self] in self?.advanceToNextInputMode() },
            onCyclePattern: { [weak self] in self?.cyclePattern() },
            currentPattern: SharedDefaults.selectedPattern
        )
    }

    private func handleLetter(_ char: Character) {
        let prior = textDocumentProxy.documentContextBeforeInput ?? ""
        let pattern = SharedDefaults.selectedPattern
        let out = pattern.transformCharacter(char, priorContext: prior)
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

Changes:
- Extracted `makeKeyboardView()` so `viewDidLoad` and `cyclePattern` share the construction path.
- Added `onCyclePattern` callback and `currentPattern` argument when instantiating `KeyboardView`.
- New `cyclePattern()` method: calls `PatternCycler.next(...)`, persists to `SharedDefaults`, rebuilds the SwiftUI root so the strip label updates.

- [ ] **Step 2: Build**

```bash
xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Install, enable keyboard, exercise the strip**

Install onto a booted simulator that already has the keyboard enabled (or enable it via Settings one time). Open Notes:

```bash
xcrun simctl install booted $(xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' -showBuildSettings | awk -F= '/ BUILT_PRODUCTS_DIR /{gsub(/^ +| +$/,"",$2); print $2"/SarcasmKeyboard.app"; exit}')
xcrun simctl launch booted com.apple.mobilenotes
xcrun simctl io booted screenshot /tmp/strip.png
```

After tapping into a note and switching to the sarcasm keyboard, screenshot. Verify:
- Strip is visible above keys.
- Strip label reads `• <current pattern name, transformed by itself> ▾` (e.g., `• aLtErNaTiNg ▾`).
- Tapping the strip changes the label to the next free pattern and subsequent keystrokes use the new pattern.
- Hairline lime top border visible on the strip.

- [ ] **Step 4: Confirm App Group round-trip**

Still in the Simulator, switch back to the companion app:

```bash
xcrun simctl terminate booted com.apple.mobilenotes
xcrun simctl launch booted com.sarcasmkeyboard.app
xcrun simctl io booted screenshot /tmp/roundtrip.png
```

Confirm: the pattern that the strip last selected is the one checked in the app's list.

- [ ] **Step 5: Run the full test suite**

```bash
swift test
```
Expected: 97 passing, 1 skipped (IconRendererTests.testRenderAppIconVariants — skipped without `RENDER_ICON=1`).

- [ ] **Step 6: Commit Task 9 + Task 10 together**

```bash
git add SarcasmKeyboardExtension/KeyboardView.swift SarcasmKeyboardExtension/KeyboardViewController.swift
git commit -m "Keyboard: add active-pattern strip (tap to cycle) + dark Palette background

New ActivePatternStrip above the key rows: 30pt tall, ink bg, hairline lime
top border, centered mono label showing '• <pattern-transformed-name> ▾'.
Tap calls onCyclePattern which runs PatternCycler.next on SharedDefaults
and rebuilds the SwiftUI root so the strip label updates immediately.
Keystrokes still read SharedDefaults.selectedPattern per press, so the new
pattern applies to the very next character typed after cycling."
```

---

## Task 11: Verification pass against the spec's criteria

**Files:** None to modify — this is a verification-only task. If any criterion fails, circle back to the owning task, fix, and return.

- [ ] **Step 1: Automated baseline**

```bash
swift test
```
Expected: `Test Suite 'All tests' passed.`, 97 tests passed, 1 skipped.

```bash
xcodegen generate
xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 2: Home-screen icon check**

```bash
xcrun simctl io booted screenshot /tmp/home.png
```

Read `/tmp/home.png`. Icon is lime `aA` on ink. Readable at tile size.

- [ ] **Step 3: Companion app — dark mode**

```bash
xcrun simctl ui booted appearance dark
xcrun simctl launch booted com.sarcasmkeyboard.app
xcrun simctl io booted screenshot /tmp/app_dark.png
```

Confirm: dark background, lime accents on selected pattern + Pro locks + playground arrow/text, title transforms through the selected pattern.

- [ ] **Step 4: Companion app — light mode**

```bash
xcrun simctl ui booted appearance light
xcrun simctl terminate booted com.sarcasmkeyboard.app
xcrun simctl launch booted com.sarcasmkeyboard.app
xcrun simctl io booted screenshot /tmp/app_light.png
```

Confirm: clean light list, lime accents still read well against system background. Reset: `xcrun simctl ui booted appearance dark`.

- [ ] **Step 5: Keyboard — reskin + strip + cycle**

```bash
xcrun simctl launch booted com.apple.mobilenotes
xcrun simctl io booted screenshot /tmp/kb.png
```

Tap into a note, switch to sarcasm keyboard, type a few letters, tap the strip, type more letters, screenshot. Confirm:
- Keys dark with mono labels, lime press flash on taps.
- Strip label reads `• <current-pattern-transformed> ▾`.
- Tapping strip cycles to the next free pattern.
- Typed text after the cycle reflects the new pattern.

- [ ] **Step 6: App Group round-trip**

After cycling via the strip, switch back to the companion app and confirm the newly-selected pattern is the one with a lime check.

- [ ] **Step 7: Memory spot-check (Instruments optional, but cheap to verify)**

Attach Instruments' Allocations template to `SarcasmKeyboardExtension` (Xcode → Product → Profile → select the extension process in a running host). Type 100 characters and cycle patterns. Confirm peak memory stays under 48MB. If over, the most likely culprit is the `UIHostingController.rootView = makeKeyboardView()` rebuild leaking prior hosted views — investigate before declaring done.

- [ ] **Step 8: Final commit (if any polish changes landed in this task)**

If no changes were required, skip. Otherwise:

```bash
git add -A
git commit -m "Polish: verification-pass fixes

<specific nits addressed during the verification pass>"
```

---

## Self-review notes (written after the plan was drafted)

**Spec coverage:**
- Palette.swift + Typography trim + Theme.swift delete → Task 1. ✓
- Companion app repaint (ContentView) → Task 5. ✓
- PatternRow repaint → Task 6. ✓
- InstallGuideSheet + ProUpsellSheet repaint → Task 7. ✓
- KeyButton rebuild → Task 8. ✓
- KeyboardView dark bg + active-pattern strip → Task 9. ✓
- KeyboardViewController cycle wiring → Task 10. ✓
- IconView → Task 3. ✓
- IconRenderer test + asset catalog → Task 4. ✓
- App icon rendered + visible on home screen → Task 4, verified in Task 11. ✓
- Verification criteria from spec → Task 11. ✓
- PatternCycler as pure/tested logic — added beyond spec as a TDD-friendly extraction (spec's cyclePattern inline logic; cleaner + tested here). ✓

**No placeholders:** Confirmed — every code step contains the full file contents or the full diff. No "similar to Task N" references. Every command has expected output.

**Type consistency:**
- `Palette.default.accent` referenced consistently in every task. ✓
- `PatternCycler.next(currentID:in:)` signature identical in the test (Task 2) and the callsites in `ContentView.rerollPattern` (Task 5) and `KeyboardViewController.cyclePattern` (Task 10). ✓
- `KeyboardView` adds `onCyclePattern` + `currentPattern` parameters in Task 9; Task 10 updates every callsite (only one: `makeKeyboardView()`). Task 9 Step 2 explicitly flags the expected compile failure and defers the commit to Task 10 to keep history bisectable. ✓
- Font extensions `.sarcasmMono` / `.sarcasmMonoSmall` / `.sarcasmTitle` — defined in Task 1, used in Tasks 5/6/8/9. No other font extensions referenced. ✓

**Scope:** One cohesive unit of work — closes 3.5 gaps, leaves Phase 4 for a separate spec. ✓
