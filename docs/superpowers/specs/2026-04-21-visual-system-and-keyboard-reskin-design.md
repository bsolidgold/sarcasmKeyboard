# Visual system, keyboard reskin, and app icon — design

**Date:** 2026-04-21
**Status:** Approved (brainstorming phase). Next: implementation plan.
**Closes:** Phase 3.5 gaps from `~/.claude/plans/i-want-to-create-steady-deer.md`
**Precedes:** Phase 4 (additional themes) — gets its own spec later.

## Problem

Phase 3.5 shipped an iOS-native companion-app redesign but left two deliverables from
the original plan unfinished:

1. **App icon** — `SarcasmKeyboard/Assets.xcassets/AppIcon.appiconset/` is empty. Blocks
   TestFlight and App Store submission (Phase 9).
2. **Keyboard extension reskin** — `KeyboardView.swift` / `KeyButton.swift` still use
   the Phase 1 generic system styling. Phase 4 themes have nothing meaningful to theme
   until the keyboard has an intentional visual identity.

Additionally, the shipped companion-app aesthetic (burnt-orange accent, insetGrouped
list) was an AI-driven direction the user didn't pick. It's not load-bearing and gets
replaced in this work.

## Goal

Lock one distinctive visual identity for the sarcasm keyboard — app + extension +
icon — that carries personality without sacrificing typing UX.

The target use context is hostile comment threads, group chats, and late-night phone
usage. The product is a tool people use to clown on strangers. The design should
answer that: functional, dark by default, one loud accent color, no artisanal chrome.

## Non-goals

- Additional themes beyond the default (Phase 4).
- Haptics / sound (requires Full Access — Phase 5).
- Pro unlock gating of the strip cycle (Phase 6).
- Long-press strip → full pattern picker (deferred to v1.1; tap-to-cycle is enough
  for v1).
- Light-mode palette for the keyboard extension (keyboard is always dark by design).

## Design direction

**Dark, loud, functional.**

- **Dark by default** — app and keyboard both anchored on near-black. App follows
  system light/dark; keyboard is always dark regardless of system setting (it's part
  of the identity, and matching the system would visually fragment the product).
- **One loud accent** — acid lime `#B8FF2A`. Used in exactly four places:
  1. Selected-pattern checkmark in the app.
  2. The active-pattern strip above the keyboard keys.
  3. The pressed-key flash in the keyboard.
  4. The app icon.
  Nowhere else. Restraint is what makes it loud.
- **Typography** — SF Mono for anything that represents typed/transformed output so
  it reads as "text in transit." SF Pro for chrome (section headers, nav titles).
- **No ornament** — no gradients, no soft shadows, no chunky borders, no
  stickerisms. Solid fills, hairline borders only, one-pixel highlights only where
  they aid legibility.

## Architecture

Four domains of change, all rooted in a new shared design-token module that both
targets consume.

```
Sources/SarcasmKit/Design/
├── Palette.swift          # NEW — color tokens (dark keyboard, system-aware app)
├── Typography.swift       # TRIMMED — prune unused font extensions
└── Theme.swift            # DELETED — orphaned memeMax/terminal directions

Sources/SarcasmKit/Design/
├── IconView.swift                       # NEW — SwiftUI source for the app icon (lives in SarcasmKit; pure SwiftUI, no app-specific deps)

SarcasmKeyboard/
├── ContentView.swift                    # REPAINTED — lime accent, plain list, palette tokens
├── Views/
│   ├── PatternRow.swift                 # REPAINTED — lime accent
│   ├── InstallGuideSheet.swift          # REPAINTED
│   └── ProUpsellSheet.swift             # REPAINTED
└── Assets.xcassets/AppIcon.appiconset/  # FILLED IN — rendered PNGs + Contents.json

SarcasmKeyboardExtension/
├── KeyboardView.swift                   # REBUILT — adds active-pattern strip + dark palette
├── KeyButton.swift                      # REBUILT — dark fill, mono labels, lime press flash
└── KeyboardViewController.swift         # MODIFIED — wires cycle-pattern callback

Tests/SarcasmKitTests/
└── IconRenderer.swift                   # NEW — one-shot test that emits icon PNGs
```

### Why these boundaries

- `Palette.swift` lives in `SarcasmKit` so both targets import the same tokens. It
  stays pure Swift / SwiftUI (no UIKit) to preserve the Android-port path in Phase 11.
- The icon is authored in SwiftUI (`IconView`) and *rendered* via a test helper
  (`IconRenderer`). This keeps the icon source in-repo, version-controlled, and
  re-renderable when the palette shifts in Phase 4, without adding build-time
  dependencies.
- The active-pattern strip is a *new surface*, not a modification to the key rows —
  keeping it isolated in `KeyboardView.swift` means changes to it don't ripple into
  `KeyButton.swift`.

## Components

### `Sources/SarcasmKit/Design/Palette.swift` (new)

Plain Swift struct exposing color tokens. No environment wiring yet — Phase 4 adds a
`@Environment(\.palette)` mechanism; for now the default palette is referenced
statically as `Palette.default`.

```swift
public struct Palette: Sendable, Equatable {
    // Keyboard (always dark)
    public let ink: Color              // #0A0A0A — keyboard background, app dark-mode background
    public let keyFill: Color          // #1C1C1E — letter keys
    public let systemKeyFill: Color    // #2C2C2E — shift/space/return/delete
    public let topHighlight: Color     // #3A3A3C — 1px highlight on top edge of keys
    public let accent: Color           // #B8FF2A — lime, used sparingly

    // Text (on dark surfaces)
    public let text: Color             // #F2F2F7 — primary on dark
    public let subtleText: Color       // #8E8E93 — secondary on dark

    // App light-mode: uses SwiftUI's system-semantic colors directly at callsite
    // (Color(.systemBackground), .primary, .secondary) rather than tokens here —
    // keeps SarcasmKit UIKit-free and lets the system handle dynamic color.

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
```

The `Color(hex:)` initializer already exists in `Theme.swift`; it gets moved to
`Palette.swift` before `Theme.swift` is deleted.

### `Sources/SarcasmKit/Design/Typography.swift` (trimmed)

Keep only what gets used:

```swift
extension Font {
    public static let sarcasmTitle = Font.system(size: 22, weight: .bold, design: .monospaced)
    public static let sarcasmMono = Font.system(size: 16, weight: .regular, design: .monospaced)
    public static let sarcasmMonoSmall = Font.system(size: 13, weight: .regular, design: .monospaced)
}
```

`sarcasmMega`, `sarcasmHeadline`, `sarcasmBody`, `sarcasmLabel`, `sarcasmTight()`,
`sarcasmLoose()` are deleted — unused.

### `Sources/SarcasmKit/Design/Theme.swift` (deleted)

`Theme`, `Palette` (the old nested one), `Radii`, `Borders`, `Shadow`, `Theme.memeMax`,
`Theme.terminal` — all orphaned, zero references outside the file itself. Deleted
wholesale. `Color(hex:)` moves to `Palette.swift` first.

### `SarcasmKeyboard/ContentView.swift` (repainted)

- Drop `extension Color { static let appAccent = Color(red: 0.92, green: 0.42, blue: 0.22) }`.
- Replace `.tint(.appAccent)` → `.tint(Palette.default.accent)`.
- Keep the "title transforms itself" behavior — it's the single best move in the
  current app and matches the product's self-demonstrating spirit.
- `.listStyle(.insetGrouped)` → `.listStyle(.plain)`. Compact section spacing
  preserved.
- `listRowBackground(Color.orange.opacity(0.08))` on the setup section → `Palette.default.accent.opacity(0.10)`.
- Playground preview text font changes from `.system(.subheadline, design: .monospaced)`
  to `.sarcasmMono`.
- Strip the "(sarcastic nudge)" and equivalent editorial parentheticals from footer
  copy. "Install the keyboard" + "4 quick steps in iOS Settings" stays. Footer: "Not
  sure if it's installed yet. Swipe left to dismiss." (drops "forever" — it's obvious).
- Background color in dark mode: `Palette.default.ink`. In light mode: system default.

### `SarcasmKeyboard/Views/PatternRow.swift` (repainted)

- Selected circle fill `Color.accentColor.opacity(0.15)` → `Palette.default.accent.opacity(0.15)`.
- Selected check + icon foreground `Color.accentColor` → `Palette.default.accent`.
- Pro lock `.orange` → `Palette.default.accent`.
- Sample text font → `.sarcasmMonoSmall`.
- Pattern name kept in system font (`.subheadline.weight(.medium)`) — chrome stays
  legible, transformed content is what's monospaced.

### `SarcasmKeyboard/Views/InstallGuideSheet.swift` & `ProUpsellSheet.swift` (repainted)

No structural change. Any orange/burnt-orange tint → palette accent. Any
system-accent-color reference → palette accent. `sheet` backgrounds on dark mode
use `Palette.default.ink` for consistency with the parent view.

### `Sources/SarcasmKit/Design/IconView.swift` (new)

**Concept update (2026-04-21, per user direction):** The icon renders
`AlternatingPattern().transform("sarcastic")` → `sArCaStIc` split into three
rows of three (`sAr / CaS / tIc`), so the icon literally demonstrates the
product's output on the product's name. Lime on ink, stacked VStack with
tight negative spacing, SF Pro Rounded Black.

```swift
import SwiftUI

public struct IconView: View {
    public enum Variant { case primary, tinted }
    public let variant: Variant
    public init(variant: Variant = .primary) { self.variant = variant }

    private static let rows: [String] = {
        let t = AlternatingPattern().transform("sarcastic")  // "sArCaStIc"
        return [
            String(t.prefix(3)),
            String(t.dropFirst(3).prefix(3)),
            String(t.dropFirst(6).prefix(3))
        ]
    }()

    public var body: some View {
        ZStack {
            background
            VStack(spacing: -40) {
                ForEach(Self.rows, id: \.self) { row in
                    Text(row)
                        .font(.system(size: 340, weight: .black, design: .rounded))
                        .foregroundStyle(foreground)
                        .tracking(-18)
                }
            }
        }
        .frame(width: 1024, height: 1024)
    }
    // background + foreground switch on variant — see implementation file.
}
```

Rationale: the `aA` earlier draft communicated "case flip" in one mark, but the
stacked full-word version better conveys what the product actually does (and
reads better as a recognizable word on a home screen). Lime on ink reads from
1024px down to ~60pt; verified in the Simulator.

### `Tests/SarcasmKitTests/IconRenderer.swift` (new)

Not a regression test — a one-shot render helper gated by an environment flag so
it doesn't run on every `swift test`:

```swift
import XCTest
import SwiftUI
@testable import SarcasmKit

final class IconRenderer: XCTestCase {
    func testRenderAppIcon() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["RENDER_ICON"] == "1",
                          "Set RENDER_ICON=1 to render app icon PNGs")
        // Use ImageRenderer on IconView() — write to SarcasmKeyboard/Assets.xcassets/AppIcon.appiconset/
        // Three outputs:
        //   AppIcon-1024.png       (primary, lime on ink)
        //   AppIcon-Dark-1024.png  (same artwork — our icon is already dark)
        //   AppIcon-Tinted-1024.png (lime aA on transparent, for iOS 18 tinted mode)
    }
}
```

Invoke with `RENDER_ICON=1 swift test --filter IconRenderer`.

**Location:** `IconView` lives in `SarcasmKit/Design/` alongside `Palette` and
`Typography`. It's pure SwiftUI with no app- or extension-specific imports, so
placing it in the framework is consistent with the existing design-token home and
lets the `IconRenderer` test import it directly without duplication.

### `SarcasmKeyboard/Assets.xcassets/AppIcon.appiconset/` (filled in)

- `Contents.json` with iOS 17+ multi-idiom + multi-variant schema (Any Appearance,
  Dark, Tinted). Only the 1024×1024 "single size" is required now — iOS handles
  downscales automatically since iOS 17.
- Three PNGs rendered by `IconRenderer`.

### `SarcasmKeyboardExtension/KeyboardView.swift` (rebuilt)

Adds the active-pattern strip above the existing key rows. Layout:

```
╔════════════════════════════════════════╗
║  • sPoNgEbOb ▾                         ║   ← strip: 30pt, ink bg, hairline lime top
╠════════════════════════════════════════╣
║  [q][w][e][r][t][y][u][i][o][p]        ║
║   [a][s][d][f][g][h][j][k][l]          ║
║  [⇧][z][x][c][v][b][n][m][⌫]           ║
║  [🌐][.][,][  space  ][return]          ║
╚════════════════════════════════════════╝
```

- Strip height: 30pt. Background: `Palette.default.ink`. Top edge: 1pt
  `Palette.default.accent`.
- Text: `• <currentPattern.transform(currentPattern.displayName)> ▾` — i.e. the
  pattern demonstrates itself. Font `.sarcasmMonoSmall`, color
  `Palette.default.accent`.
- Tap: calls new `onCyclePattern` callback. Tap animation: strip briefly fills with
  `accent.opacity(0.15)` for 150ms.
- Whole keyboard background: `Palette.default.ink` (was `Color(.systemGray6)`).

```swift
struct KeyboardView: View {
    let onLetter: (Character) -> Void
    let onPunctuation: (Character) -> Void
    let onSpace: () -> Void
    let onDelete: () -> Void
    let onReturn: () -> Void
    let onGlobe: () -> Void
    let onCyclePattern: () -> Void      // NEW
    let currentPattern: any SarcasmPattern   // NEW — read from SharedDefaults in VC, passed in

    var body: some View {
        VStack(spacing: 0) {
            ActivePatternStrip(pattern: currentPattern, onTap: onCyclePattern)
            VStack(spacing: 6) {
                // existing letter rows, reparented
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
        }
        .background(Palette.default.ink)
    }
}
```

`ActivePatternStrip` is a small inner view in the same file.

### `SarcasmKeyboardExtension/KeyButton.swift` (rebuilt)

- Background: `Palette.default.keyFill` for `.letter`, `Palette.default.systemKeyFill`
  for `.system`.
- 1pt top-edge highlight in `Palette.default.topHighlight` (via an overlay stroke on
  the top side only — a small `Path` or an overlay `VStack` spacer).
- Text: `Palette.default.text`, font `.sarcasmMono` for letters, `.sarcasmMonoSmall`
  for system keys.
- Drop shadow removed.
- Press animation: background briefly fills with `Palette.default.accent.opacity(0.30)`
  for 80ms (not a scale effect — dim-flash reads better on dark).
- Corner radius: 5pt (slightly tighter than current 6pt — less rounded-puffy).

### `SarcasmKeyboardExtension/KeyboardViewController.swift` (modified)

- Add `KeyboardStatus` isn't changing; just wire the new callback:

```swift
let view = KeyboardView(
    // ...existing callbacks...
    onCyclePattern: { [weak self] in self?.cyclePattern() },
    currentPattern: SharedDefaults.selectedPattern
)
```

- New method:

```swift
private func cyclePattern() {
    let all = SarcasmEngine.allPatterns.filter { !$0.isPremium }
    guard let currentIndex = all.firstIndex(where: { $0.id == SharedDefaults.selectedPatternID }),
          !all.isEmpty else { return }
    let next = all[(currentIndex + 1) % all.count]
    SharedDefaults.selectedPatternID = next.id
    // Rebuild the hosting controller's rootView so the strip updates.
    hostingController?.rootView = makeKeyboardView()
}
```

- `makeKeyboardView()` factored out of `viewDidLoad` so `viewDidLoad` and
  `cyclePattern` both use the same construction path.

## Data flow

Unchanged except for the new cycle path:

```
┌──────────────────┐    write     ┌────────────────────────────┐
│  App: PatternRow │ ───────────▶ │ SharedDefaults             │
│  tap             │              │ .selectedPatternID         │
└──────────────────┘              │ (App Group UserDefaults)   │
                                  └────────────────────────────┘
┌──────────────────┐    write     ▲                            │
│  Keyboard: strip │ ─────────────┘                            │
│  tap             │                                           │
└──────────────────┘                                           │
                                                               │
┌──────────────────┐                              read         │
│  Keyboard: key   │ ◀──────────────────────────────────────────┘
│  press transform │
└──────────────────┘
```

Both write sites go through `SharedDefaults.selectedPatternID`. The keyboard's
`handleLetter` reads `SharedDefaults.selectedPattern` on every keystroke (already
does), so no observation/binding plumbing is needed for the letters to pick up the
new pattern. The strip itself updates via the explicit `hostingController.rootView`
rebuild in `cyclePattern`.

## Error handling and edge cases

- **Cycle from a Pro pattern when user isn't entitled:** `cyclePattern()` only picks
  from `!isPremium` patterns. If the current pattern is Pro (shouldn't happen in v1
  pre-Phase 6, but guarding anyway), fall through to the first free pattern.
- **Only one free pattern:** `cyclePattern` is a no-op if the filtered list has
  fewer than 2 entries. Strip remains tappable; nothing changes.
- **App Group not available:** `SharedDefaults` already handles this by returning
  defaults. Strip will show the default pattern's name. Cycling will silently fail
  to persist, which is acceptable — this is a "keyboard installed but entitlements
  broken" edge case.
- **Long pattern display name** (hypothetical): truncate with tail ellipsis. All
  current names are ≤10 chars.
- **Dark/light mode mid-keyboard-session:** keyboard is always dark; system change
  doesn't affect it. App will re-render on system change via standard SwiftUI.

## Testing

### Automated
- **Existing:** `swift test` → 91/91 passing. Must remain green through all
  refactors. Specifically `SharedDefaultsTests` covers the round-trip the new strip
  relies on.
- **New:** no new unit tests for the visual layer — it's all pure SwiftUI composition
  with no logic worth asserting. The `IconRenderer` test is a renderer, not a
  regression test (skipped unless `RENDER_ICON=1`).

### Manual (Simulator screenshot loop)
- `xcodebuild` against the app scheme for an iOS 17 Simulator destination → clean. (Exact scheme name lives in the generated `.xcodeproj`; implementation plan will pin the command.)
- Launch in Simulator. Home screen: lime `aA` icon visible.
- Open companion app: dark background, plain list, lime accents on active pattern +
  Pro locks. Title re-cases through the selected pattern.
- Enable keyboard in Settings → Notes.app. Switch to sarcasm keyboard.
- Keyboard: dark, mono labels, visible top strip showing current pattern.
- Tap keys: dim-flash press animation, text appears transformed.
- Tap strip: pattern name updates, subsequent keystrokes use new pattern.
- Reopen companion app: the list shows the strip-selected pattern checked (App
  Group round-trip confirmed).

### Verification criteria (pass/fail)
- [ ] `swift test` → 91/91.
- [ ] `xcodebuild` clean for both targets.
- [ ] Home screen icon is lime `aA` on ink.
- [ ] Companion app is dark in dark mode, clean in light mode, lime accents only.
- [ ] Keyboard top strip visible and tap-cycles through free patterns.
- [ ] Keyboard keys are dark with mono labels and lime press flash.
- [ ] Strip selection persists to the companion app via App Group.
- [ ] Keyboard stays within the ~48MB memory budget (Instruments spot-check).

## Constraints carried forward

- **Extension memory ceiling (~48MB):** no images, no gradients, no heavy animations.
  All tokens are solid `Color` values. ✓
- **`SarcasmKit` stays pure Swift/SwiftUI** (no UIKit) — palette is pure SwiftUI.
  `IconView` is pure SwiftUI. Android port path preserved. ✓
- **No custom fonts** — SF Mono + SF Pro Rounded only. Zero font-asset weight. ✓
- **No network from the extension.** Nothing in this spec introduces any. ✓

## Build order

1. `Palette.swift` + move `Color(hex:)` helper into it + Typography trim +
   `Theme.swift` deletion. Single commit. No visible change yet.
2. `IconView.swift` + `IconRenderer` test + asset catalog population. Commit. Icon
   now visible on home screen — first visible win.
3. Companion app repaint: `ContentView.swift`, `PatternRow.swift`, two sheets. Commit.
4. Keyboard key reskin: `KeyButton.swift` + `KeyboardView.swift` background. Commit.
5. Active-pattern strip: `KeyboardView.swift` strip + `KeyboardViewController.swift`
   cycle wiring. Commit.
6. Screenshot-loop iteration: adjust hex values, paddings, strip proportions until
   it reads right. Commit when stable.

Total estimated time: 1.5–2 days of focused work for implementation; a day of
iteration on step 6.

## Open questions for implementation plan

- Should the strip's tap animation use `.symbolEffect` on the ▾ chevron for a
  micro-indicator of the cycle, or stick with the background flash alone? Defer
  to planning step — both are cheap to try.
- Exact `xcodebuild` command and scheme name — pinned in planning step after
  regenerating `.xcodeproj` via `xcodegen`.
