# Keyboard themes — design

**Date:** 2026-04-21
**Status:** Approved. Next: implementation plan.
**Closes:** Phase 4 from `~/.claude/plans/i-want-to-create-steady-deer.md`
**Precedes:** Phase 5 (haptics / Full Access) — gets its own spec.

## Problem

The keyboard extension today has exactly one visual style: Acid (lime-on-ink). Users
with different aesthetic contexts — writing in bright sunlight, using a Notes app with
a white background, running a retro-terminal vibe — have no way to adapt the keyboard
to their environment. A theme picker is the first monetization surface where Pro value
is obviously legible before purchase.

## Goal

Ship a theme picker in the companion app that lets users choose from 10 keyboard
themes (3 free, 7 Pro). The selected theme is applied to the keyboard extension on
next load. Pro themes show a lock icon; tapping opens the existing `ProUpsellSheet`
(real IAP lands in Phase 6). The companion app's own chrome is untouched by themes.

## Non-goals

- Re-theming the companion app's chrome. The lime-on-dark companion aesthetic is a
  locked identity. Themes apply to the keyboard extension only.
- Animated themes, gradient fills, or image-based backgrounds. Memory ceiling is
  ~48MB; all theme tokens must be solid `Color` values.
- Live theme preview inside the running keyboard extension. The keyboard reads the
  selected theme on its next `viewDidLoad` / rebuild cycle.
- Real IAP integration. That's Phase 6. The "Unlock for $2.99" button in
  `ProUpsellSheet` is already a no-op comment.
- Per-app theming or time-based theme switching.
- Haptics, Full Access (Phase 5).
- Long-press strip → full pattern picker (deferred to v1.1).

## Design direction

**Dark personalities, one light escape.**

Nine of the ten themes are dark-background riffs — they respect the keyboard's
foundational dark identity. Clean Light is the lone departure: a light-mode-native
keyboard palette for users who prefer light system themes or who type in apps with
white backgrounds where the dark keyboard creates jarring contrast.

Every theme carries a personality that maps to a real use context. The Pro themes
exist because they're visually loud and distinct — worth $2.99 to someone who would
actually choose them.

The three free themes (Acid, Clean Light, Clean Dark) give every user a real choice
from day one. "Free" does not mean "lesser" — Acid is the default and the most
distinctive of the ten.

## Architecture

### `Theme` type

`Theme` is a value-type struct with identity metadata plus an embedded `Palette`.

```swift
public struct Theme: Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let isPremium: Bool
    public let palette: Palette
}
```

This is cleaner than growing metadata fields onto `Palette`, because `Palette` is a
pure color-token bag — adding `id`, `displayName`, and `isPremium` to it would make
it responsible for two different concerns (color definition and catalog identity).
Keeping them separate means `Palette` stays passable to views without dragging theme
metadata along, and the keyboard extension only needs the `Palette` — it never needs
to inspect a theme's `displayName` or `isPremium` at runtime.

### `ThemeCatalog` enum

```swift
public enum ThemeCatalog {
    public static let allThemes: [Theme] = [ /* 10 instances, ordered as shipped */ ]
    public static func theme(id: String) -> Theme? { allThemes.first { $0.id == id } }
}
```

Parallel to `SarcasmEngine`, which has `allPatterns` and `pattern(id:)`. The enum
is a namespace, not a class, keeping allocation-free and trivially thread-safe.

### `Palette.default` alias

`Palette.default` stays defined in `Palette.swift` and continues to return the Acid
palette. It now delegates to `ThemeCatalog.acid.palette` so there's a single source
of truth for the hex values, and all Phase 3.5 call sites that reference
`Palette.default` continue to compile without change.

This is the right call over refactoring callsites because: (a) `Palette.default` is
referenced in 5 files across both targets, (b) the alias costs nothing at runtime,
and (c) the refactor buys nothing — `KeyboardViewController` will replace its
`Palette.default` references with a resolved-theme palette in Task 3/4 anyway.

### `SharedDefaults.selectedThemeID`

Added alongside `selectedPatternID` in the same `SharedDefaults` enum, same App
Group-backed `UserDefaults`. Default value is `"acid"` (Acid's id).

### Palette threading to the keyboard extension

`KeyboardViewController.makeKeyboardView()` resolves the current theme from
`ThemeCatalog`, extracts its `Palette`, and passes it as an explicit parameter to
`KeyboardView`. `KeyboardView` threads it explicitly to `KeyButton` and
`ActivePatternStrip` via a parameter, not `@Environment`.

Rationale: the keyboard extension is a single-view hierarchy with no deep nesting
where an environment key would save meaningful boilerplate. Explicit params keep the
data flow visible and compiler-verified with no `@Environment` registration
boilerplate. If Phase 5 introduces deeper nesting, a switch to `@Environment` is a
small refactor at that point.

### `ProUpsellSheet` generalization

`ProUpsellSheet` currently accepts `lockedPattern: any SarcasmPattern`. We add a
parallel initializer that accepts a `Theme` as the locked item:

```swift
// Existing — no change
init(lockedPattern: any SarcasmPattern)

// New
init(lockedTheme: Theme)
```

Both inits share the same body implementation via a private `LocalItem` enum that
holds either a pattern or a theme and surfaces just `displayName` to the view.
This is cleaner than genericizing the whole sheet or introducing a protocol that
both `Theme` and `SarcasmPattern` conform to, because `Theme` and `SarcasmPattern`
otherwise have nothing in common — a shared protocol would exist solely to serve
`ProUpsellSheet`, which is backwards. Two inits is the smallest change and causes
zero disruption to the existing `ContentView` call site.

### Theme-change refresh in the keyboard extension

Theme changes are written to `SharedDefaults` from the companion app. The keyboard
extension reads `SharedDefaults.selectedThemeID` inside `makeKeyboardView()` at
`viewDidLoad` time. There is no live-refresh: the keyboard picks up the new theme
the next time its view controller loads (which happens every time the user focuses
a new text field or re-opens the keyboard). This is identical to how `selectedPatternID`
works today for pattern changes from the companion app, and it's the right tradeoff —
pushing a live-refresh mechanism into the extension for theme changes would require
observation infrastructure that's complex, memory-costly, and unnecessary given
that theme is a deliberate "set it and forget it" preference, not a per-message
decision.

## Components

### `Sources/SarcasmKit/Design/Theme.swift` (new)

Contains `Theme` struct and `ThemeCatalog` enum with all 10 theme instances.
The file lives in `SarcasmKit/Design/` alongside `Palette.swift` — it's a design
token file, not engine logic.

### `Sources/SarcasmKit/Storage/SharedDefaults.swift` (modified)

Add:

```swift
private enum Keys {
    static let selectedPatternID = "sarcasm.selectedPatternID"
    static let selectedThemeID   = "sarcasm.selectedThemeID"   // NEW
}

public static var selectedThemeID: String {
    get { defaults.string(forKey: Keys.selectedThemeID) ?? ThemeCatalog.acid.id }
    set { defaults.setValue(newValue, forKey: Keys.selectedThemeID) }
}

public static var selectedTheme: Theme {
    ThemeCatalog.theme(id: selectedThemeID) ?? ThemeCatalog.acid
}
```

### `Sources/SarcasmKit/Design/Palette.swift` (modified — one line)

```swift
public static let `default` = ThemeCatalog.acid.palette
```

Replaces the inline `Palette(...)` construction. All hex values move to
`ThemeCatalog` / `Theme.swift`.

### `SarcasmKeyboardExtension/KeyboardView.swift` (modified)

Add `palette: Palette` parameter. Replace every `Palette.default.*` reference
with `palette.*`. Thread `palette` to `ActivePatternStrip` and `KeyButton` as
an explicit parameter.

### `SarcasmKeyboardExtension/KeyButton.swift` (modified)

Add `palette: Palette` parameter. Replace every `Palette.default.*` reference
with `palette.*`.

### `SarcasmKeyboardExtension/KeyboardViewController.swift` (modified)

`makeKeyboardView()` reads `SharedDefaults.selectedTheme.palette` and passes it
into `KeyboardView(...)`.

### `SarcasmKeyboard/Views/ThemeRow.swift` (new)

Parallel to `PatternRow`. Each row shows the theme's `displayName`, a live
mini-preview of sample text rendered in that theme's palette colors, and a lock
icon on Pro themes. The mini-preview is a small rounded rectangle filled with
the theme's `ink` color, containing one line of sample text in `accent` over
`keyFill` — enough to communicate the palette personality at a glance.

### `SarcasmKeyboard/Views/ProUpsellSheet.swift` (modified)

Add `init(lockedTheme: Theme)` alongside the existing `init(lockedPattern:)`.

### `SarcasmKeyboard/ContentView.swift` (modified)

Add a "Theme" section between "Style" (patterns) and "About". One row per theme
via `ThemeRow`. Tapping a free theme writes `SharedDefaults.selectedThemeID`.
Tapping a Pro theme opens `ProUpsellSheet(lockedTheme: theme)`.

`ContentView` needs a `@State private var selectedThemeID: String` parallel to
`selectedPatternID`. No `@State` for a resolved `Theme` — resolve it inline from
`ThemeCatalog.theme(id: selectedThemeID)` the same way `currentPattern` is
resolved from `selectedPatternID`.

### `Tests/SarcasmKitTests/ThemeCatalogTests.swift` (new)

Catalog invariant tests — see Testing section.

### `Tests/SarcasmKitTests/SharedDefaultsTests.swift` (modified)

Add `selectedThemeID` round-trip test alongside existing `selectedPatternID` tests.

## Data flow

```
┌────────────────────┐   write   ┌───────────────────────────────────────┐
│ App: ThemeRow tap  │ ────────▶ │ SharedDefaults.selectedThemeID        │
│ (free theme)       │           │ (App Group UserDefaults)              │
└────────────────────┘           └───────────────────────────────────────┘
                                                         │
                                                    read │
                                                         ▼
                                  ┌────────────────────────────────────┐
                                  │ KeyboardViewController             │
                                  │  .makeKeyboardView()               │
                                  │  → ThemeCatalog.theme(id:)         │
                                  │  → .palette                        │
                                  │  → KeyboardView(palette: palette)  │
                                  └────────────────────────────────────┘

┌────────────────────┐   opens   ┌────────────────────┐
│ App: ThemeRow tap  │ ────────▶ │ ProUpsellSheet     │
│ (Pro theme)        │           │ (lockedTheme: ..)  │
└────────────────────┘           └────────────────────┘
```

Theme selection from the companion app is reflected in the keyboard on next keyboard
load. There is no cross-process notification.

## Theme catalog — all 10 themes with palette hex values

All contrast notes below use the `text` color on `keyFill` pairing, the primary
body-text combination in the keyboard. WCAG AA body text requires ≥ 4.5:1.

### Free themes

#### Acid (id: `"acid"`) — _default; high-voltage lime on near-black_
The current Palette.default. Every existing call site implicitly uses this.

| Token          | Hex       | Notes                                       |
|----------------|-----------|---------------------------------------------|
| `ink`          | `#0A0A0A` | Near-black keyboard background              |
| `keyFill`      | `#1C1C1E` | Letter key fill                             |
| `systemKeyFill`| `#2C2C2E` | Shift/space/return/delete fill              |
| `topHighlight` | `#3A3A3C` | 1px top-edge highlight                      |
| `accent`       | `#B8FF2A` | Acid lime — strip, press flash, lock icons  |
| `text`         | `#F2F2F7` | Off-white key labels                        |
| `subtleText`   | `#8E8E93` | Secondary labels                            |

Contrast `text` on `keyFill`: `#F2F2F7` on `#1C1C1E` ≈ 14.9:1. ✓

---

#### Clean Light (id: `"cleanLight"`) — _iOS-native light keyboard; made for white-background apps_
The only light-background theme. Ink is cream, keys are standard system grays,
accent is deep green for contrast on light surfaces.

| Token          | Hex       | Notes                                                   |
|----------------|-----------|---------------------------------------------------------|
| `ink`          | `#F2F2F7` | System background cream — matches iOS light keyboard bg |
| `keyFill`      | `#FFFFFF` | White letter keys                                       |
| `systemKeyFill`| `#D1D1D6` | Light grey for system keys                              |
| `topHighlight` | `#C7C7CC` | Slightly darker 1px top edge                            |
| `accent`       | `#3F7A00` | Deep forest green — readable on white at ≥ 4.5:1        |
| `text`         | `#1C1C1E` | Near-black labels on white keys                         |
| `subtleText`   | `#3C3C43` | Secondary labels, slightly lighter                      |

Contrast `text` on `keyFill`: `#1C1C1E` on `#FFFFFF` ≈ 19.7:1. ✓
Contrast `accent` on `ink`: `#3F7A00` on `#F2F2F7` ≈ 5.3:1. ✓ (for strip/accents)

---

#### Clean Dark (id: `"cleanDark"`) — _neutral dark; no accent color personality_
For people who just want a dark keyboard that doesn't call attention to itself.
Desaturated accent so nothing pops — pure utility.

| Token          | Hex       | Notes                                       |
|----------------|-----------|---------------------------------------------|
| `ink`          | `#000000` | Pure black                                  |
| `keyFill`      | `#1C1C1E` | Standard dark key fill                      |
| `systemKeyFill`| `#2C2C2E` | Slightly lighter for system keys            |
| `topHighlight` | `#48484A` | More visible 1px edge on pure black         |
| `accent`       | `#8E8E93` | Mid-grey — functional, no personality       |
| `text`         | `#FFFFFF` | Pure white labels                           |
| `subtleText`   | `#636366` | Secondary labels                            |

Contrast `text` on `keyFill`: `#FFFFFF` on `#1C1C1E` ≈ 15.7:1. ✓
Accent is mid-grey by design — it's a neutral accent, not an accessibility concern.

---

### Pro themes

#### Neon (id: `"neon"`) — _synthwave night — deep purple with hot pink strikes_
Evokes neon-lit nightclubs and glowing signage. Hot magenta accent against a
deep indigo background with purple-shifted key fills.

| Token          | Hex       | Notes                                         |
|----------------|-----------|-----------------------------------------------|
| `ink`          | `#0D0018` | Near-black with a violet cast                 |
| `keyFill`      | `#1A0033` | Deep purple key fill                          |
| `systemKeyFill`| `#2A004D` | Slightly lighter purple for system keys       |
| `topHighlight` | `#3D0073` | Purple-violet 1px edge                        |
| `accent`       | `#FF2D8A` | Hot magenta — neon pink                       |
| `text`         | `#F0E6FF` | Lavender-white labels                         |
| `subtleText`   | `#9B7BC4` | Muted violet for secondary                    |

Contrast `text` on `keyFill`: `#F0E6FF` on `#1A0033` ≈ 13.4:1. ✓

---

#### Vaporwave (id: `"vaporwave"`) — _mall aesthetic circa 1995 — teal-pink pastel dusk_
Dusty rose background, cyan-mint accent, that particular shade of lavender that
screams "Windows 3.1 screensaver."

| Token          | Hex       | Notes                                         |
|----------------|-----------|-----------------------------------------------|
| `ink`          | `#1A0A2E` | Deep dusk purple                              |
| `keyFill`      | `#2D1B4E` | Muted purple key fill                         |
| `systemKeyFill`| `#3D2560` | Slightly brighter for system keys             |
| `topHighlight` | `#5A3880` | Mid-purple 1px edge                           |
| `accent`       | `#00FFDD` | Aqua-mint — the vaporwave cyan                |
| `text`         | `#FFB8D9` | Pale rose labels                              |
| `subtleText`   | `#9F78B8` | Muted violet secondary                        |

Contrast `text` on `keyFill`: `#FFB8D9` on `#2D1B4E` ≈ 7.6:1. ✓

---

#### Terminal Green (id: `"terminalGreen"`) — _old-school hacker BBS — phosphor green on black_
Pure monochrome green phosphor. No decorative color, just the original hacker
aesthetic. Every keystroke should feel like you're writing a shell script.

| Token          | Hex       | Notes                                         |
|----------------|-----------|-----------------------------------------------|
| `ink`          | `#000000` | Pure black CRT background                     |
| `keyFill`      | `#001A00` | Near-black with faint green cast              |
| `systemKeyFill`| `#002A00` | Slightly more green for system keys           |
| `topHighlight` | `#003D00` | Muted green 1px edge                          |
| `accent`       | `#00FF41` | Matrix green — the canonical phosphor color   |
| `text`         | `#00CC33` | Slightly dimmed green for labels              |
| `subtleText`   | `#006614` | Dark green secondary                          |

Contrast `text` on `keyFill`: `#00CC33` on `#001A00` ≈ 8.9:1. ✓

---

#### Sunset (id: `"sunset"`) — _golden hour palette — deep amber and coral on dark charcoal_
Warm-toned dark keyboard. Dark slate background with orange-amber key fills
and a coral accent — evokes the last 20 minutes of light before it gets dark.

| Token          | Hex       | Notes                                         |
|----------------|-----------|-----------------------------------------------|
| `ink`          | `#0F0A00` | Very dark warm black                          |
| `keyFill`      | `#1E1408` | Dark amber-brown key fill                     |
| `systemKeyFill`| `#2E2010` | Slightly lighter warm brown for system keys   |
| `topHighlight` | `#4A3318` | Amber 1px edge                                |
| `accent`       | `#FF7A2A` | Warm orange-coral                             |
| `text`         | `#F5DEB3` | Warm wheat — slightly cream-tinted white      |
| `subtleText`   | `#A0825A` | Muted tan secondary                           |

Contrast `text` on `keyFill`: `#F5DEB3` on `#1E1408` ≈ 11.8:1. ✓

---

#### Paper (id: `"paper"`) — _aged parchment — sepia tones for the writer who can't quit dark mode_
Almost-light, almost-dark. A warm parchment background with keys that look like
aged ivory. Accent is dark sepia ink. Gives a typewriter/notebook vibe without
going full white.

| Token          | Hex       | Notes                                         |
|----------------|-----------|-----------------------------------------------|
| `ink`          | `#1C1509` | Very dark warm brown — the "book cover"       |
| `keyFill`      | `#D9C9A8` | Warm parchment key fill                       |
| `systemKeyFill`| `#C5B491` | Slightly darker parchment for system keys     |
| `topHighlight` | `#B8A47E` | Shadow-edge on parchment keys                 |
| `accent`       | `#4A2F00` | Dark sepia ink — deep brown                   |
| `text`         | `#2C1A00` | Very dark brown labels on parchment keys      |
| `subtleText`   | `#6B4E2A` | Mid-brown secondary labels                    |

Contrast `text` on `keyFill`: `#2C1A00` on `#D9C9A8` ≈ 10.1:1. ✓
Note: Paper is a light-background keyboard like Clean Light. `ink` is dark (the app
chrome around the keyboard), but `keyFill` is light parchment. This is correct — the
user sees the cream keys, not the dark surround.

---

#### Y2K (id: `"y2k"`) — _chrome gradient minus the gradient — silver-on-black with electric blue_
The aesthetic of every gaming peripheral circa 2001. Dark gunmetal background,
silver key fills, electric blue accent. Loud without being neon-pink.

| Token          | Hex       | Notes                                         |
|----------------|-----------|-----------------------------------------------|
| `ink`          | `#0A0A12` | Dark charcoal with faint blue cast            |
| `keyFill`      | `#2A2A3A` | Dark gunmetal blue-grey key fill              |
| `systemKeyFill`| `#3A3A4E` | Slightly lighter for system keys              |
| `topHighlight` | `#5A5A7A` | Silver-blue 1px edge                          |
| `accent`       | `#00B4FF` | Electric ice blue                             |
| `text`         | `#C8C8DC` | Silver-lavender labels                        |
| `subtleText`   | `#7070A0` | Muted blue-grey secondary                     |

Contrast `text` on `keyFill`: `#C8C8DC` on `#2A2A3A` ≈ 6.8:1. ✓

---

#### Highlighter (id: `"highlighter"`) — _fluorescent marker on dark paper — bright yellow on near-black_
What if someone took a yellow highlighter to a dark-mode document. Aggressively
high-contrast in a different direction from Acid — warm yellow instead of cold lime.

| Token          | Hex       | Notes                                         |
|----------------|-----------|-----------------------------------------------|
| `ink`          | `#0A0800` | Dark warm black                               |
| `keyFill`      | `#1A1600` | Dark yellow-cast key fill                     |
| `systemKeyFill`| `#2A2400` | Slightly lighter warm dark for system keys    |
| `topHighlight` | `#3D3600` | Amber-dark 1px edge                           |
| `accent`       | `#FFEE00` | Pure fluorescent yellow                       |
| `text`         | `#FFF8E0` | Warm cream-white labels                       |
| `subtleText`   | `#A09060` | Muted warm gold secondary                     |

Contrast `text` on `keyFill`: `#FFF8E0` on `#1A1600` ≈ 14.7:1. ✓

---

## Error handling and edge cases

- **Unknown theme ID in SharedDefaults:** `ThemeCatalog.theme(id:)` returns `nil`;
  `SharedDefaults.selectedTheme` falls back to `ThemeCatalog.acid`. Same fallback
  pattern as `selectedPattern` → `AlternatingPattern()`.
- **Pro theme somehow selected without entitlement:** The companion app's tap handler
  prevents this (tap on Pro theme opens upsell, not a selection write). The keyboard
  extension doesn't inspect `isPremium` — it just reads whatever ID is in defaults
  and renders that palette. In the rare case a Pro ID somehow lands in defaults
  (e.g. a future server-side promo unlock), the keyboard renders it correctly.
  No harm, no defensive guard needed.
- **Palette tokens used by `accentOnLight`:** The `accentOnLight` field stays on
  `Palette` and is used by the companion app's `PatternRow` and `ProUpsellSheet`
  to pick the right accent for light/dark system mode. Themes should set
  `accentOnLight` to a darker variant of their accent suitable for light-mode
  surfaces. For the keyboard themes that have a light `ink` (Clean Light, Paper),
  the normal `accent` already targets light backgrounds — set `accentOnLight`
  equal to `accent` for those two.

## Testing

### Automated — new

**`Tests/SarcasmKitTests/ThemeCatalogTests.swift`** (new file):

```swift
import XCTest
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
            // UIColor resolves the SwiftUI Color; opacity > 0 confirms non-transparent
            let inkAlpha   = UIColor(p.ink).cgColor.alpha
            let fillAlpha  = UIColor(p.keyFill).cgColor.alpha
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
        // Palette.default must still return Acid's palette tokens unchanged.
        let acid = ThemeCatalog.acid.palette
        let def  = Palette.default
        XCTAssertEqual(acid, def)
    }
}
```

**`Tests/SarcasmKitTests/SharedDefaultsTests.swift`** (add to existing file):

```swift
func testSelectedThemeIDDefaultsToAcid() {
    SharedDefaults.defaults.removeObject(forKey: "sarcasm.selectedThemeID")
    XCTAssertEqual(SharedDefaults.selectedThemeID, "acid")
}

func testSelectedThemeIDRoundTrip() {
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

### Automated — existing

`swift test` must remain green at 98 passing + 1 skipped throughout all refactors.
Any existing call to `Palette.default` continues to compile because the alias is
preserved. `SharedDefaultsTests` existing tests are unaffected.

### Manual (Simulator screenshot loop — no automated test)

Visual changes to the keyboard extension and the theme picker are verified manually
via Simulator screenshot loop. No automated tests exist for SwiftUI view composition.

Verification steps are specified in the plan's final task.

## Verification criteria (pass/fail)

- [ ] `swift test` → 98 passing + 1 skipped (IconRenderer, gated on RENDER_ICON=1). New catalog + SharedDefaults tests all green.
- [ ] `xcodebuild` clean for both targets, no warnings about unreferenced symbols.
- [ ] Companion app shows a "Theme" section below "Style" with 10 rows, 3 unlocked + 7 locked (lock icon).
- [ ] Tapping Acid → keyboard uses lime-on-ink palette on next load.
- [ ] Tapping Clean Light → keyboard uses cream/white/green palette on next load.
- [ ] Tapping a Pro theme → `ProUpsellSheet` opens with the theme's display name in the title. "Unlock for $2.99" button is a no-op (expected).
- [ ] Theme mini-preview in each row visually reflects its palette (ink fill, accent sample text).
- [ ] App Group round-trip: select theme in app, kill + reopen keyboard, confirm new palette.
- [ ] Keyboard stays within ~48MB memory ceiling (Instruments spot-check with all free themes cycled).

## Constraints carried forward

- **Extension memory ceiling (~48MB):** All theme tokens are solid `Color` values. No images, no gradients, no per-theme font assets. ✓
- **`SarcasmKit` stays pure Swift/SwiftUI** (no UIKit in the framework). `Theme` and `ThemeCatalog` are pure Swift + SwiftUI. ✓ The `ThemeCatalogTests` use `UIColor(palette.ink)` for alpha testing — that's test code only, not framework code.
- **No custom fonts.** All themes use SF Mono + SF Pro. ✓
- **No network from the extension.** Nothing in this spec introduces any. ✓
- **iOS 17.0 deployment target.** No APIs from iOS 18 used. ✓

## Build order

1. `Theme.swift` + `ThemeCatalog` + 10 theme instances + tests — TDD red/green cycle.
2. `SharedDefaults.selectedThemeID` + tests.
3. `Palette.default` alias update — one-line change, all existing call sites keep compiling.
4. Wire `KeyboardView` / `KeyButton` / `ActivePatternStrip` to accept an explicit `Palette` param.
5. Wire `KeyboardViewController.makeKeyboardView()` to resolve and pass the current theme palette.
6. `ThemeRow` view with mini-preview.
7. `ProUpsellSheet` — add `init(lockedTheme:)`.
8. `ContentView` — add Theme section, wire selection + upsell.
9. End-to-end verification: screenshots, round-trip test, memory check.

## Open questions

None. All architectural decisions are resolved in this spec.
