# Phase 5 — History (Design Spec)

Date: 2026-04-24
Phase: 5 of the Sarcasm Keyboard build plan (`~/.claude/plans/i-want-to-create-steady-deer.md`).
Status: Approved for implementation.

## Goal

After the user enables the Sarcasm Keyboard and types in any host app, the companion app should show a list of recently produced sarcasm outputs that the user can tap to copy. Outputs only — never raw input.

## Scope decisions (settled during brainstorm)

| Decision | Choice | Notes |
|---|---|---|
| Capture trigger | On commit | Session buffer in keyboard ext, flushed on Return key + `viewWillDisappear` |
| Per-entry max length | 500 chars | Truncate with ellipsis at flush time |
| Cap | 50 newest entries | Enforced on every append; oldest evicted |
| Storage | App Group `UserDefaults`, JSON-encoded `[HistoryEntry]` | Key `"sarcasm.history.entries.v1"` |
| Full Access | Not required | Empirically: extension already writes to App Group via `KeyboardStatus.recordHeartbeat()` with `RequestsOpenAccess: false` (`project.yml:84`). App Groups don't need Full Access on current iOS. |
| Companion-app placement | Inline "Recent" Section (top 3) + dedicated `HistoryView` | New Section between Playground and Style in `ContentView` |
| Cross-process refresh | Poll on `scenePhase == .active` | Mirrors existing `needsSetup` pattern (`ContentView.swift:72-78`) |

## Non-goals (deliberately out of scope for Phase 5)

- Search or filter on history.
- Per-host-app grouping (we don't store the host bundle ID).
- Sync across devices.
- Real-time updates while the companion app is foregrounded.
- Edit / favorite / pin entries.
- Export / share-sheet from history (taps just copy to pasteboard).

## File layout

### New files

```
Sources/SarcasmKit/Storage/HistoryEntry.swift
Sources/SarcasmKit/Storage/HistoryStore.swift
SarcasmKeyboardExtension/HistorySession.swift
SarcasmKeyboard/Views/HistoryView.swift
SarcasmKeyboard/Views/HistoryRow.swift
Tests/SarcasmKitTests/HistoryStoreTests.swift
Tests/SarcasmKitTests/HistorySessionTests.swift
```

### Modified files

```
SarcasmKeyboardExtension/KeyboardViewController.swift
SarcasmKeyboard/ContentView.swift
```

`HistorySession` lives in the extension target because it's invoked from `UIInputViewController` lifecycle hooks; nothing UIKit-specific is in `SarcasmKit`. Logic that needs unit testing (cap, eviction, flush rules, Codable round-trip) lives in `SarcasmKit`.

## Types

### `HistoryEntry`

```swift
public struct HistoryEntry: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let output: String      // The sarcasm-transformed text. Capped at 500 chars.
    public let patternID: String   // The pattern ID active at flush time.
    public let createdAt: Date

    public init(output: String, patternID: String, createdAt: Date = Date()) {
        self.id = UUID()
        self.output = output
        self.patternID = patternID
        self.createdAt = createdAt
    }
}
```

The struct intentionally has no `rawInput` field. That's the type-level expression of the "outputs only" invariant.

### `HistoryStore`

```swift
public enum HistoryStore {
    static let key = "sarcasm.history.entries.v1"
    static let cap = 50

    public static func load() -> [HistoryEntry]
    public static func append(_ entry: HistoryEntry)
    public static func delete(id: UUID)
    public static func clear()
}
```

- Backed by `SharedDefaults.defaults` (the App Group `UserDefaults`).
- All four functions are synchronous and main-thread-safe via `MainActor` annotation. UserDefaults is thread-safe for reads but we serialize writes through MainActor to make ordering trivial; throughput requirements are tiny (one write per Return keypress at the worst).
- `append` decodes the existing array, appends, trims to `cap` (drop from the front), encodes, writes. Storage order is chronological (oldest at index 0, newest at end). The UI reverses for display.
- `load` returns `[]` on decode failure. We don't try to migrate corrupt data — the user loses recent history and the next write resets the array. The `v1` suffix on the key reserves room for explicit migrations later.

### `HistorySession`

```swift
final class HistorySession {
    private var buffer: String = ""
    private let store: HistoryStoreWriter   // protocol over HistoryStore.append for testability

    func append(_ inserted: String)
    func removeLast(count: Int = 1)
    func flush(currentPatternID: String)
    func reset()
}
```

- `append(inserted:)` concatenates onto `buffer`. Called once per `textDocumentProxy.insertText(out)` in the keyboard.
- `removeLast(count:)` drops the last `count` Characters (default 1). Called once per `textDocumentProxy.deleteBackward()`. If `buffer.isEmpty`, no-op (the user is deleting text we didn't insert).
- `flush(currentPatternID:)` trims leading/trailing whitespace; if the result is empty, just resets the buffer with no entry written; otherwise truncates to 500 grapheme clusters (`String.prefix` on a `String` operates on Characters, which are grapheme clusters — matches the rest of `SarcasmKit`'s grapheme-safety stance) and writes a `HistoryEntry`. Then resets the buffer.
- The `HistoryStoreWriter` protocol exists only so `HistorySessionTests` can assert what would be written without touching real `UserDefaults`.

## Capture flow in `KeyboardViewController`

```
viewDidLoad           → KeyboardStatus.recordHeartbeat() (existing) + create HistorySession
handleLetter(c)       → insertText(out) + session.append(out)
handlePunctuation(c)  → insertText(c) + session.append(String(c))
handleSpace           → existing handleLetter(" ") path covers this
onReturn              → insertText("\n") + session.flush(currentPatternID:)
onDelete              → deleteBackward() + session.removeLast()
cyclePattern          → no flush; session continues across pattern changes
viewWillDisappear     → session.flush(currentPatternID:)
```

**Return-key semantics:** Return is treated as a thought boundary, not part of any entry. The `\n` character is sent to the host app but **not** appended to the session buffer; `flush` finalizes the entry and resets. If the user keeps typing after Return (e.g., a multi-line text field), the next keystroke starts a fresh buffer.

**Pattern change mid-buffer:** the entry's `patternID` is whatever was active at flush time. If the user typed "hello" under SpongeBob then "world" under Alternating then pressed Return, the entry text reflects what they actually saw on screen, and `patternID` shows the last pattern. This is a known imperfection — fixing it would require per-character pattern tracking, which is overkill.

## Companion app UX

### Recent Section (in `ContentView`)

Position: between `playgroundSection` and `patternsSection`.

```
┌─ Recent ─────────────────────────────┐
│  ThIs Is SaRcAsM                     │
│  2 min ago · SpongeBob               │
│  ─────────────────────────────────── │
│  ʜᴇʟʟᴏ ᴡᴏʀʟᴅ                          │
│  yesterday · SmallCaps               │
│  ─────────────────────────────────── │
│  thE QUICK browN FOX                 │
│  Mar 12 · WordToggle                 │
│  ─────────────────────────────────── │
│  See all →                           │
└──────────────────────────────────────┘
```

- Reads `HistoryStore.load()` on appear and on `scenePhase == .active`.
- Empty state: single muted card — "Your transformed text shows up here once you start typing." No CTA. (We rely on the existing setup-banner flow to drive the user toward enabling the keyboard.)
- Non-empty: top 3 rows by `createdAt` desc, then a "See all →" `NavigationLink` row pushing to `HistoryView`.
- Each row: output text in `.sarcasmMono`, font size matching `PatternRow`'s preview line. Secondary line uses `RelativeDateTimeFormatter` (`.named` style) for the timestamp + pattern display name.

### `HistoryView` (full screen)

- `List` of all entries, newest-first.
- Tap row → copy `entry.output` to `UIPasteboard.general`, fire a light haptic, show a brief "Copied" toast (or a checkmark inline for ~1.5 s).
- Swipe trailing → Delete (calls `HistoryStore.delete(id:)`).
- Long-press → context menu: Copy, Delete.
- Toolbar trailing: "Clear" button → confirmation alert ("Clear all 50 entries? This can't be undone.") → `HistoryStore.clear()`.
- Empty state inside the dedicated screen mirrors the home empty card.

## Testing

### Unit (run with `swift test`)

`HistoryStoreTests`:
- Round-trip codable: encode 3 entries, decode, equality holds.
- Cap enforcement: appending 51st entry drops the oldest; ordering preserved.
- `delete(id:)`: removes only the matching entry, others untouched.
- `clear()`: empties the array.
- `load()` returns `[]` when the key is absent or contains corrupt JSON (use a custom `UserDefaults(suiteName:)` per test).

`HistorySessionTests`:
- `append` then `flush` writes one entry with the buffer text.
- `flush` on empty/whitespace-only buffer writes nothing.
- `flush` on >500-char buffer truncates with ellipsis.
- `append` followed by `removeLast` followed by `flush` writes the deleted-aware text.
- `removeLast` on empty buffer is a no-op.
- Pattern ID at flush is what the caller passes (verifies pattern-cycle correctness).

### Manual (simulator only)

- Type a few sentences in Notes via the Sarcasm Keyboard, hit Return, switch to the companion app → entry appears.
- Background the keyboard mid-buffer (swipe to home), reopen the app → buffer was flushed, entry appears.
- Swipe-delete one row, force-quit the app, relaunch → row stays deleted.
- Clear All → confirmation → list empties → relaunch confirms.

## Verification (Phase 5 done bar)

Per the original plan: "Granting Full Access populates history in the companion app within 1 second of typing. Raw input is never persisted." Updated for the no-Full-Access-needed reality:

- Typing in any host app populates the companion app's Recent section within 1 second of returning to the app (or sooner via `scenePhase` poll).
- `HistoryEntry` has no field that could store raw input (compile-time guarantee).
- Source review confirms the keyboard never persists `documentContextBeforeInput` or any host-app text.

## Risks

- **Buffer drift:** if the keyboard state and the host text-field diverge (e.g., user uses dictation mid-sentence, then types via our keyboard), our session buffer won't match what the user sees in the host. Acceptable for v1 — history shows what the keyboard produced, not what's in the field.
- **Lost entries on crash:** if the extension crashes mid-buffer before Return or `viewWillDisappear`, that buffer is lost. We don't checkpoint mid-buffer because the cost (a UserDefaults write per keystroke) outweighs the benefit (rare crashes).
- **UserDefaults size:** capped at ~25 KB worst case — well within UserDefaults limits.

## Open items deferred to writing-plans

- Exact MainActor / actor pattern for `HistoryStore` writes.
- Toast component reuse vs. one-off implementation.
- Whether `HistoryRow` should live in `SarcasmKit/Design/` (so it's themable from one place) or in the app target.
