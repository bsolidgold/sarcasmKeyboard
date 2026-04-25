# Phase 5 — History Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Capture sarcasm-transformed outputs from the keyboard extension and surface them in the companion app as a tappable, copyable Recent list backed by App Group `UserDefaults`.

**Architecture:** Three new pure-Swift types in `SarcasmKit/Storage/`: `HistoryEntry` (Codable value), `HistoryStore` (enum namespace with load/append/delete/clear over the App Group `UserDefaults`, capped at 50), and `HistorySession` (a per-keyboard-view buffer that mirrors inserts/deletes and flushes one entry on Return + dismiss). The keyboard extension owns one `HistorySession` per `viewDidLoad` and routes it through existing `handleLetter`/`handlePunctuation`/`onDelete`/`onReturn` plus `viewWillDisappear`. The companion app reads via `HistoryStore.load()` on appear and on `scenePhase == .active`, mirroring the existing `KeyboardStatus.shouldShowSetupBanner` poll. App Group writes don't require Full Access — proven empirically by the existing `KeyboardStatus.recordHeartbeat()` flow with `RequestsOpenAccess: false`.

**Tech Stack:** Swift 5.9, SwiftUI (iOS 17+), XCTest, SwiftPM (`SarcasmKit` + tests), XcodeGen (regenerates `.xcodeproj`), `xcodebuild`, `xcrun simctl`.

**Spec:** [`docs/superpowers/specs/2026-04-24-phase5-history-design.md`](../specs/2026-04-24-phase5-history-design.md)

---

## Conventions used throughout this plan

- **Package root:** `/Users/bretgold/Documents/gitHub/sarcasmKeyboard/`. All `swift test`, `xcodegen`, and `xcodebuild` commands run from there.
- **Project regeneration:** when adding or removing source files, run `xcodegen generate` before `xcodebuild` so the new files are picked up. Modifications to existing files don't require regen, but running it is harmless.
- **Building the iOS app:** `xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build`
- **Screenshot loop for manual verification:** `xcrun simctl io booted screenshot /tmp/sk.png` then read `/tmp/sk.png`.
- **Commits:** one concern per commit. **No `Co-Authored-By: Claude` trailer** — enforced by `.githooks/commit-msg`. Use the project's own voice in messages.
- **Tests baseline:** `swift test` currently reports `109 tests, 2 skipped, 0 failures`. This must stay true after every task except those that explicitly add new tests, where the count grows by exactly the new test count.
- **Spec deviation note:** the spec said `HistorySession` would live in the extension target. During plan-writing we noticed the class has zero UIKit dependencies, so this plan moves it into `Sources/SarcasmKit/Storage/` to make it unit-testable via `swift test`. The keyboard extension imports `SarcasmKit` and instantiates it. No other spec changes.

---

## File map

### New files

| Path | Responsibility |
|---|---|
| `Sources/SarcasmKit/Storage/HistoryEntry.swift` | The `HistoryEntry` value type (`Codable`, `Identifiable`, `Sendable`, `Equatable`). |
| `Sources/SarcasmKit/Storage/HistoryStore.swift` | Enum namespace owning the App Group key, load/append/delete/clear, cap-50 enforcement, corrupt-data resilience. |
| `Sources/SarcasmKit/Storage/HistorySession.swift` | The per-keyboard buffer class. Mirrors inserts/deletes; flushes one entry on demand. |
| `Tests/SarcasmKitTests/HistoryEntryTests.swift` | Codable round-trip + equality. |
| `Tests/SarcasmKitTests/HistoryStoreTests.swift` | Load/append/cap/delete/clear/corrupt. |
| `Tests/SarcasmKitTests/HistorySessionTests.swift` | Append/remove/flush rules, truncation, whitespace skip, pattern ID capture. |
| `SarcasmKeyboard/Views/HistoryRow.swift` | Reusable row view (output text + relative timestamp + pattern name). |
| `SarcasmKeyboard/Views/HistoryView.swift` | Full-screen list with tap-to-copy, swipe-delete, Clear All, transient "Copied" toast. |

### Modified files

| Path | Change summary |
|---|---|
| `SarcasmKeyboardExtension/KeyboardViewController.swift` | Hold a `HistorySession` instance. Mirror inserts/deletes; flush on Return + `viewWillDisappear`. |
| `SarcasmKeyboard/ContentView.swift` | Add a "Recent" Section between Playground and Style. State + `scenePhase` refresh + `NavigationLink` "See all →". |

---

## Task 1: `HistoryEntry` value type — TDD

**Files:**
- Create: `Sources/SarcasmKit/Storage/HistoryEntry.swift`
- Create: `Tests/SarcasmKitTests/HistoryEntryTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `Tests/SarcasmKitTests/HistoryEntryTests.swift`:

```swift
import XCTest
@testable import SarcasmKit

final class HistoryEntryTests: XCTestCase {
    func testRoundTripCodable() throws {
        let original = HistoryEntry(
            output: "ThIs Is SaRcAsM",
            patternID: "spongebob",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HistoryEntry.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testTwoEntriesWithSameContentHaveDifferentIDs() {
        let a = HistoryEntry(output: "x", patternID: "alternating")
        let b = HistoryEntry(output: "x", patternID: "alternating")
        XCTAssertNotEqual(a.id, b.id)
    }

    func testEquatableUsesAllFields() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let id = UUID()
        let a = HistoryEntry(id: id, output: "x", patternID: "alternating", createdAt: date)
        let b = HistoryEntry(id: id, output: "x", patternID: "alternating", createdAt: date)
        XCTAssertEqual(a, b)
    }
}
```

Note the third test calls a memberwise init that takes an explicit `id`. We expose that init for tests; production callers use the public default-id convenience init.

- [ ] **Step 2: Run tests — they should fail to compile**

Run: `swift test --filter HistoryEntryTests`
Expected: compile failure ("cannot find 'HistoryEntry' in scope").

- [ ] **Step 3: Implement `HistoryEntry`**

Create `Sources/SarcasmKit/Storage/HistoryEntry.swift`:

```swift
import Foundation

public struct HistoryEntry: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let output: String
    public let patternID: String
    public let createdAt: Date

    public init(output: String, patternID: String, createdAt: Date = Date()) {
        self.id = UUID()
        self.output = output
        self.patternID = patternID
        self.createdAt = createdAt
    }

    init(id: UUID, output: String, patternID: String, createdAt: Date) {
        self.id = id
        self.output = output
        self.patternID = patternID
        self.createdAt = createdAt
    }
}
```

The struct deliberately has no `rawInput` field. That's the type-level guarantee that history never stores what the user typed before transformation.

- [ ] **Step 4: Run tests — they should pass**

Run: `swift test --filter HistoryEntryTests`
Expected: `Executed 3 tests, with 0 failures`.

- [ ] **Step 5: Run the full suite to confirm no regressions**

Run: `swift test`
Expected: `Executed 112 tests, with 2 tests skipped and 0 failures`.

- [ ] **Step 6: Commit**

```bash
git add Sources/SarcasmKit/Storage/HistoryEntry.swift Tests/SarcasmKitTests/HistoryEntryTests.swift
git commit -m "Phase 5: HistoryEntry value type"
```

---

## Task 2: `HistoryStore` — load + append + cap-50

**Files:**
- Create: `Sources/SarcasmKit/Storage/HistoryStore.swift`
- Create: `Tests/SarcasmKitTests/HistoryStoreTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `Tests/SarcasmKitTests/HistoryStoreTests.swift`:

```swift
import XCTest
@testable import SarcasmKit

final class HistoryStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        SharedDefaults.defaults.removeObject(forKey: HistoryStore.key)
    }

    func testLoadReturnsEmptyWhenUnset() {
        XCTAssertEqual(HistoryStore.load(), [])
    }

    func testAppendPersistsAcrossLoads() {
        let entry = HistoryEntry(output: "hello", patternID: "alternating")
        HistoryStore.append(entry)
        XCTAssertEqual(HistoryStore.load(), [entry])
    }

    func testAppendPreservesChronologicalOrder() {
        let first = HistoryEntry(output: "first", patternID: "alternating")
        let second = HistoryEntry(output: "second", patternID: "alternating")
        let third = HistoryEntry(output: "third", patternID: "alternating")
        HistoryStore.append(first)
        HistoryStore.append(second)
        HistoryStore.append(third)
        XCTAssertEqual(HistoryStore.load().map(\.output), ["first", "second", "third"])
    }

    func testCapEvictsOldestWhenFull() {
        for i in 0..<HistoryStore.cap {
            HistoryStore.append(HistoryEntry(output: "entry\(i)", patternID: "alternating"))
        }
        XCTAssertEqual(HistoryStore.load().count, HistoryStore.cap)

        HistoryStore.append(HistoryEntry(output: "overflow", patternID: "alternating"))

        let entries = HistoryStore.load()
        XCTAssertEqual(entries.count, HistoryStore.cap)
        XCTAssertEqual(entries.first?.output, "entry1", "oldest should be evicted")
        XCTAssertEqual(entries.last?.output, "overflow", "newest should be at the end")
    }
}
```

- [ ] **Step 2: Run tests — they should fail to compile**

Run: `swift test --filter HistoryStoreTests`
Expected: compile failure ("cannot find 'HistoryStore' in scope").

- [ ] **Step 3: Implement `HistoryStore`**

Create `Sources/SarcasmKit/Storage/HistoryStore.swift`:

```swift
import Foundation

/// Append-only history of sarcasm outputs, capped at 50 entries.
/// Storage is the App Group `UserDefaults` (same suite as `SharedDefaults`).
///
/// Threading: callers must invoke these methods on the main thread.
/// `UserDefaults` is thread-safe per access, but our load+modify+save
/// pattern in `append` and `delete` is not — concurrent calls could
/// drop writes. All current callers (keyboard event handlers and SwiftUI
/// view lifecycle) are already on the main thread.
public enum HistoryStore {
    public static let key = "sarcasm.history.entries.v1"
    public static let cap = 50

    /// All entries, oldest first. Returns `[]` when empty or unreadable.
    public static func load() -> [HistoryEntry] {
        guard let data = SharedDefaults.defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([HistoryEntry].self, from: data)) ?? []
    }

    /// Appends an entry. Drops the oldest when over `cap`.
    public static func append(_ entry: HistoryEntry) {
        var entries = load()
        entries.append(entry)
        if entries.count > cap {
            entries.removeFirst(entries.count - cap)
        }
        save(entries)
    }

    private static func save(_ entries: [HistoryEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        SharedDefaults.defaults.set(data, forKey: key)
    }
}
```

- [ ] **Step 4: Run tests — they should pass**

Run: `swift test --filter HistoryStoreTests`
Expected: `Executed 4 tests, with 0 failures`.

- [ ] **Step 5: Run the full suite**

Run: `swift test`
Expected: `Executed 116 tests, with 2 tests skipped and 0 failures`.

- [ ] **Step 6: Commit**

```bash
git add Sources/SarcasmKit/Storage/HistoryStore.swift Tests/SarcasmKitTests/HistoryStoreTests.swift
git commit -m "Phase 5: HistoryStore with cap-50 + chronological order"
```

---

## Task 3: `HistoryStore` — `delete`, `clear`, corrupt-data resilience

**Files:**
- Modify: `Sources/SarcasmKit/Storage/HistoryStore.swift`
- Modify: `Tests/SarcasmKitTests/HistoryStoreTests.swift`

- [ ] **Step 1: Add the failing tests**

Append to `HistoryStoreTests`:

```swift
    func testDeleteRemovesOnlyMatchingEntry() {
        let a = HistoryEntry(output: "a", patternID: "alternating")
        let b = HistoryEntry(output: "b", patternID: "alternating")
        let c = HistoryEntry(output: "c", patternID: "alternating")
        HistoryStore.append(a)
        HistoryStore.append(b)
        HistoryStore.append(c)

        HistoryStore.delete(id: b.id)

        XCTAssertEqual(HistoryStore.load().map(\.output), ["a", "c"])
    }

    func testDeleteWithUnknownIDIsNoOp() {
        let a = HistoryEntry(output: "a", patternID: "alternating")
        HistoryStore.append(a)
        HistoryStore.delete(id: UUID())
        XCTAssertEqual(HistoryStore.load(), [a])
    }

    func testClearRemovesAll() {
        HistoryStore.append(HistoryEntry(output: "x", patternID: "alternating"))
        HistoryStore.append(HistoryEntry(output: "y", patternID: "alternating"))
        HistoryStore.clear()
        XCTAssertEqual(HistoryStore.load(), [])
    }

    func testLoadReturnsEmptyOnCorruptData() {
        SharedDefaults.defaults.set(Data("not valid json".utf8), forKey: HistoryStore.key)
        XCTAssertEqual(HistoryStore.load(), [])
    }
```

- [ ] **Step 2: Run — they should fail**

Run: `swift test --filter HistoryStoreTests`
Expected: compile failure for `delete`/`clear`. (Corrupt-data test will start passing once compile is fixed because `load` already swallows decode errors.)

- [ ] **Step 3: Add `delete` and `clear`**

Append to `HistoryStore` in `Sources/SarcasmKit/Storage/HistoryStore.swift`:

```swift
    public static func delete(id: UUID) {
        var entries = load()
        entries.removeAll { $0.id == id }
        save(entries)
    }

    public static func clear() {
        SharedDefaults.defaults.removeObject(forKey: key)
    }
```

- [ ] **Step 4: Run tests — they should pass**

Run: `swift test --filter HistoryStoreTests`
Expected: `Executed 8 tests, with 0 failures`.

- [ ] **Step 5: Run the full suite**

Run: `swift test`
Expected: `Executed 120 tests, with 2 tests skipped and 0 failures`.

- [ ] **Step 6: Commit**

```bash
git add Sources/SarcasmKit/Storage/HistoryStore.swift Tests/SarcasmKitTests/HistoryStoreTests.swift
git commit -m "Phase 5: HistoryStore delete/clear + corrupt-data resilience"
```

---

## Task 4: `HistorySession` — append, removeLast, flush, truncation

**Files:**
- Create: `Sources/SarcasmKit/Storage/HistorySession.swift`
- Create: `Tests/SarcasmKitTests/HistorySessionTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `Tests/SarcasmKitTests/HistorySessionTests.swift`:

```swift
import XCTest
@testable import SarcasmKit

final class HistorySessionTests: XCTestCase {

    func testAppendThenFlushWritesOneEntry() {
        var writes: [HistoryEntry] = []
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let session = HistorySession(write: { writes.append($0) }, now: { fixedDate })

        session.append("hello ")
        session.append("world")
        session.flush(currentPatternID: "spongebob")

        XCTAssertEqual(writes.count, 1)
        XCTAssertEqual(writes.first?.output, "hello world")
        XCTAssertEqual(writes.first?.patternID, "spongebob")
        XCTAssertEqual(writes.first?.createdAt, fixedDate)
    }

    func testFlushOnEmptyBufferWritesNothing() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        session.flush(currentPatternID: "alternating")

        XCTAssertTrue(writes.isEmpty)
    }

    func testFlushOnWhitespaceOnlyBufferWritesNothing() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        session.append("   \n\t  ")
        session.flush(currentPatternID: "alternating")

        XCTAssertTrue(writes.isEmpty)
    }

    func testFlushTrimsLeadingAndTrailingWhitespace() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        session.append("   hello   ")
        session.flush(currentPatternID: "alternating")

        XCTAssertEqual(writes.first?.output, "hello")
    }

    func testFlushResetsTheBuffer() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        session.append("first")
        session.flush(currentPatternID: "alternating")
        session.append("second")
        session.flush(currentPatternID: "alternating")

        XCTAssertEqual(writes.map(\.output), ["first", "second"])
    }

    func testRemoveLastDropsCharacters() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        session.append("hello")
        session.removeLast(2)
        session.flush(currentPatternID: "alternating")

        XCTAssertEqual(writes.first?.output, "hel")
    }

    func testRemoveLastOnEmptyBufferIsNoOp() {
        let session = HistorySession(write: { _ in })
        session.removeLast(5)  // must not crash
    }

    func testRemoveLastDoesNotUnderflow() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        session.append("hi")
        session.removeLast(10)
        session.append("ok")
        session.flush(currentPatternID: "alternating")

        XCTAssertEqual(writes.first?.output, "ok")
    }

    func testFlushTruncatesAt500Graphemes() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        let long = String(repeating: "a", count: 600)
        session.append(long)
        session.flush(currentPatternID: "alternating")

        let output = writes.first?.output ?? ""
        XCTAssertEqual(output.count, 500)
        XCTAssertTrue(output.hasSuffix("…"))
        XCTAssertEqual(output.prefix(499), String(repeating: "a", count: 499))
    }

    func testFlushDoesNotTruncateAt500OrFewerGraphemes() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        let exact = String(repeating: "a", count: 500)
        session.append(exact)
        session.flush(currentPatternID: "alternating")

        XCTAssertEqual(writes.first?.output, exact)
        XCTAssertFalse(writes.first?.output.hasSuffix("…") ?? true)
    }

    func testResetClearsBufferWithoutWriting() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        session.append("draft")
        session.reset()
        session.flush(currentPatternID: "alternating")

        XCTAssertTrue(writes.isEmpty)
    }
}
```

- [ ] **Step 2: Run — they should fail to compile**

Run: `swift test --filter HistorySessionTests`
Expected: compile failure ("cannot find 'HistorySession' in scope").

- [ ] **Step 3: Implement `HistorySession`**

Create `Sources/SarcasmKit/Storage/HistorySession.swift`:

```swift
import Foundation

/// In-memory buffer of text the keyboard has produced since the last
/// boundary (Return key or `viewWillDisappear`). On flush, builds one
/// `HistoryEntry` and hands it to the injected `write` closure.
///
/// Pure Swift — no UIKit dependencies — so the keyboard extension and
/// any future surfaces (Android port via Kotlin, etc.) can share the
/// same buffer rules. UIKit lifecycle decides *when* to call these
/// methods; this class only decides *what* to record.
public final class HistorySession {
    public typealias Writer = (HistoryEntry) -> Void
    public static let maxOutputLength = 500

    private var buffer: String = ""
    private let write: Writer
    private let now: () -> Date

    public init(write: @escaping Writer, now: @escaping () -> Date = Date.init) {
        self.write = write
        self.now = now
    }

    /// Append text the keyboard just inserted into the host app.
    public func append(_ inserted: String) {
        buffer.append(inserted)
    }

    /// Drop the last `count` Characters (grapheme clusters) from the buffer.
    /// No-op if the buffer is shorter than `count` — bounded to `buffer.count`.
    public func removeLast(count: Int = 1) {
        let n = min(count, buffer.count)
        guard n > 0 else { return }
        buffer.removeLast(n)
    }

    /// Finalize the buffer into a `HistoryEntry` and write it (if non-empty
    /// after trimming whitespace), then clear the buffer regardless.
    public func flush(currentPatternID: String) {
        defer { buffer = "" }
        let trimmed = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let truncated: String
        if trimmed.count > Self.maxOutputLength {
            truncated = String(trimmed.prefix(Self.maxOutputLength - 1)) + "…"
        } else {
            truncated = trimmed
        }
        let entry = HistoryEntry(output: truncated, patternID: currentPatternID, createdAt: now())
        write(entry)
    }

    /// Discard the buffer without writing.
    public func reset() {
        buffer = ""
    }
}
```

- [ ] **Step 4: Run tests — they should pass**

Run: `swift test --filter HistorySessionTests`
Expected: `Executed 11 tests, with 0 failures`.

- [ ] **Step 5: Run the full suite**

Run: `swift test`
Expected: `Executed 131 tests, with 2 tests skipped and 0 failures`.

- [ ] **Step 6: Commit**

```bash
git add Sources/SarcasmKit/Storage/HistorySession.swift Tests/SarcasmKitTests/HistorySessionTests.swift
git commit -m "Phase 5: HistorySession buffer with flush/truncation rules"
```

---

## Task 5: Wire `HistorySession` into `KeyboardViewController`

**Files:**
- Modify: `SarcasmKeyboardExtension/KeyboardViewController.swift`

This task has no new unit tests — `HistorySession` is already covered. We verify by reading the App Group `UserDefaults` after typing in the simulator. The full UI surface lands in Tasks 6 and 7; this task just makes sure entries get written.

- [ ] **Step 1: Add the session and route inserts/deletes/return/disappear**

Replace the contents of `SarcasmKeyboardExtension/KeyboardViewController.swift` with:

```swift
import UIKit
import SwiftUI
import SarcasmKit

final class KeyboardViewController: UIInputViewController {
    private var hostingController: UIHostingController<KeyboardView>?
    private var historySession: HistorySession?

    override func viewDidLoad() {
        super.viewDidLoad()
        KeyboardStatus.recordHeartbeat()
        historySession = HistorySession(write: HistoryStore.append)

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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        flushHistory()
    }

    private func makeKeyboardView() -> KeyboardView {
        KeyboardView(
            onLetter:       { [weak self] char in self?.handleLetter(char) },
            onPunctuation:  { [weak self] char in self?.handlePunctuation(char) },
            onSpace:        { [weak self] in self?.handleLetter(" ") },
            onDelete:       { [weak self] in self?.handleDelete() },
            onReturn:       { [weak self] in self?.handleReturn() },
            onCyclePattern: { [weak self] in self?.cyclePattern() },
            currentPattern: Self.resolvedPattern(),
            palette:        Self.resolvedTheme().palette
        )
    }

    private static func resolvedPattern() -> any SarcasmPattern {
        let p = SharedDefaults.selectedPattern
        if p.isPremium && !SharedDefaults.isPro {
            return AlternatingPattern()
        }
        return p
    }

    private static func resolvedTheme() -> Theme {
        let t = SharedDefaults.selectedTheme
        if t.isPremium && !SharedDefaults.isPro {
            return ThemeCatalog.acid
        }
        return t
    }

    private func handleLetter(_ char: Character) {
        let prior   = textDocumentProxy.documentContextBeforeInput ?? ""
        let pattern = SharedDefaults.selectedPattern
        let out     = pattern.transformCharacter(char, priorContext: prior)
        textDocumentProxy.insertText(out)
        historySession?.append(out)
    }

    private func handlePunctuation(_ char: Character) {
        let s = String(char)
        textDocumentProxy.insertText(s)
        historySession?.append(s)
    }

    private func handleDelete() {
        textDocumentProxy.deleteBackward()
        historySession?.removeLast()
    }

    private func handleReturn() {
        textDocumentProxy.insertText("\n")
        flushHistory()
    }

    private func flushHistory() {
        historySession?.flush(currentPatternID: SharedDefaults.selectedPatternID)
    }

    private func cyclePattern() {
        let nextID = PatternCycler.next(
            currentID: SharedDefaults.selectedPatternID,
            in: SarcasmEngine.allPatterns,
            includePremium: SharedDefaults.isPro
        )
        SharedDefaults.selectedPatternID = nextID
        hostingController?.rootView = makeKeyboardView()
    }
}
```

Key behaviors:
- The newline character itself is **not** appended to the buffer — Return is a clean boundary.
- Pattern cycling does not flush.
- Delete mirrors via `removeLast()`. If the user deletes text we didn't insert (e.g., they tapped into a pre-filled field), `removeLast` no-ops once the buffer is empty.

- [ ] **Step 2: Build the app target**

`KeyboardViewController.swift` is an existing file, so no `xcodegen generate` is needed for this task. Run:
`xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build`
Expected: `BUILD SUCCEEDED`. (Building the app embeds the keyboard extension, so a clean build proves both compile.)

- [ ] **Step 3: Confirm `swift test` is still green**

Run: `swift test`
Expected: `Executed 131 tests, with 2 tests skipped and 0 failures`.

- [ ] **Step 4: Manual smoke test (optional at this task; sufficient at Task 8)**

Until Task 6 lands the UI, you can't see the entries in the app. If you want to verify now, run the simulator app, switch to Notes, type a few characters via the Sarcasm Keyboard, hit Return, then in Xcode run a one-line debug: in the companion app's `ContentView.task`, log `HistoryStore.load()`. Otherwise, defer the smoke test to Task 8.

- [ ] **Step 5: Commit**

```bash
git add SarcasmKeyboardExtension/KeyboardViewController.swift
git commit -m "Phase 5: keyboard extension flushes history on Return + dismiss"
```

---

## Task 6: `HistoryRow` + Recent Section in `ContentView`

**Files:**
- Create: `SarcasmKeyboard/Views/HistoryRow.swift`
- Modify: `SarcasmKeyboard/ContentView.swift`

- [ ] **Step 1: Create `HistoryRow.swift`**

The row is reused by both the inline preview Section and the full `HistoryView` in Task 7. Create `SarcasmKeyboard/Views/HistoryRow.swift`:

```swift
import SwiftUI
import SarcasmKit

struct HistoryRow: View {
    let entry: HistoryEntry

    private static let dateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    private var patternDisplayName: String {
        SarcasmEngine.pattern(id: entry.patternID)?.displayName ?? entry.patternID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.output)
                .font(.sarcasmMono)
                .lineLimit(2)
                .truncationMode(.tail)
                .foregroundStyle(.primary)
            HStack(spacing: 6) {
                Text(Self.dateFormatter.localizedString(for: entry.createdAt, relativeTo: Date()))
                Text("·")
                Text(patternDisplayName)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
```

- [ ] **Step 2: Add Recent state and section to `ContentView`**

Modify `SarcasmKeyboard/ContentView.swift`. Add a `@State` for the recents and a section variable, and wire them through the existing `task` and `scenePhase` paths.

Add this state property next to the others (after `selectedThemeID`):

```swift
    @State private var recentHistory: [HistoryEntry] = []
```

Replace the `body`'s `List` block so it includes a new `historySection` between `playgroundSection` and `patternsSection`:

```swift
            List {
                if needsSetup {
                    setupSection
                }
                playgroundSection
                historySection
                patternsSection
                themesSection
                aboutSection
            }
```

Add this section variable next to the existing section variables:

```swift
    private var historySection: some View {
        Section {
            if recentHistory.isEmpty {
                Text("Your transformed text shows up here once you start typing.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(recentHistory.prefix(3)) { entry in
                    HistoryRow(entry: entry)
                }
                NavigationLink {
                    HistoryView()
                } label: {
                    Text("See all")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(accent)
                }
            }
        } header: {
            Text("Recent")
        }
    }
```

Update the `.task` block at the bottom to also load history (insert before the `guard !hasAutoPresentedGuide` line):

```swift
        .task {
            refreshHistory()
            guard !hasAutoPresentedGuide else { return }
            hasAutoPresentedGuide = true
            if KeyboardStatus.shouldShowSetupBanner {
                showInstallGuide = true
            }
        }
```

Update the `.onChange(of: scenePhase)` block to also refresh history:

```swift
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                needsSetup = KeyboardStatus.shouldShowSetupBanner
                refreshHistory()
            }
        }
```

Add the helper method near the other private methods:

```swift
    private func refreshHistory() {
        recentHistory = HistoryStore.load().reversed()
    }
```

The `.reversed()` call flips chronological storage (oldest first) into newest-first display order.

- [ ] **Step 3: Stub `HistoryView` so the file compiles**

Task 7 builds the real `HistoryView`. For now, add a placeholder so the `NavigationLink` compiles. Create `SarcasmKeyboard/Views/HistoryView.swift`:

```swift
import SwiftUI
import SarcasmKit

struct HistoryView: View {
    var body: some View {
        Text("History (full screen lands in Task 7)")
            .navigationTitle("History")
    }
}
```

- [ ] **Step 4: Regenerate the Xcode project**

`HistoryRow.swift` and `HistoryView.swift` are new files. XcodeGen needs to refresh the project so they're included in the app target.

Run: `xcodegen generate`
Expected: `Generated project successfully` (or similar).

- [ ] **Step 5: Build the app**

Run: `xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 6: Manual smoke test**

In the simulator: launch the app — Recent section should be visible with the empty-state copy. Switch to Notes (or any text field), type a sentence via the Sarcasm Keyboard, hit Return, switch back to the app. The Recent section should now show the transformed text plus "See all". Tapping "See all" pushes the placeholder `HistoryView`.

- [ ] **Step 7: Commit**

```bash
git add SarcasmKeyboard/Views/HistoryRow.swift SarcasmKeyboard/Views/HistoryView.swift SarcasmKeyboard/ContentView.swift SarcasmKeyboard.xcodeproj
git commit -m "Phase 5: Recent section in ContentView with empty + 3-row preview"
```

---

## Task 7: `HistoryView` — full-screen list with copy / delete / clear

**Files:**
- Modify: `SarcasmKeyboard/Views/HistoryView.swift`

- [ ] **Step 1: Replace the placeholder with the real view**

Replace the contents of `SarcasmKeyboard/Views/HistoryView.swift`:

```swift
import SwiftUI
import SarcasmKit
import UIKit

struct HistoryView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var entries: [HistoryEntry] = []
    @State private var showCopiedToast = false
    @State private var showClearConfirmation = false

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "Nothing yet",
                    systemImage: "text.alignleft",
                    description: Text("Your transformed text shows up here once you start typing.")
                )
            } else {
                List {
                    ForEach(entries) { entry in
                        Button {
                            copy(entry)
                        } label: {
                            HistoryRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                copy(entry)
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            Button(role: .destructive) {
                                delete(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !entries.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Text("Clear")
                    }
                }
            }
        }
        .confirmationDialog(
            "Clear all history?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                HistoryStore.clear()
                refresh()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every entry. It can't be undone.")
        }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                copiedToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 32)
            }
        }
        .task { refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refresh() }
        }
    }

    private var copiedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
            Text("Copied")
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: Capsule())
        .shadow(radius: 4, y: 2)
    }

    private func copy(_ entry: HistoryEntry) {
        UIPasteboard.general.string = entry.output
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopiedToast = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopiedToast = false
            }
        }
    }

    private func delete(_ entry: HistoryEntry) {
        HistoryStore.delete(id: entry.id)
        refresh()
    }

    private func refresh() {
        entries = HistoryStore.load().reversed()
    }
}
```

Notes:
- `ContentUnavailableView` is iOS 17+ — already the deployment target.
- The toast is a tiny inline view, no new file. The 1.5 s auto-dismiss matches the spec.
- `refresh()` reverses chronological storage to newest-first display order, same as `ContentView.refreshHistory()`.

- [ ] **Step 2: Build the app**

Run: `xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Manual verification of the four interactions**

In the simulator:
1. Tap "See all" from the Recent section → full list appears, newest-first.
2. Tap a row → "Copied" toast appears for ~1.5 s; long-press elsewhere to paste and confirm the right text was copied.
3. Swipe a row left → Delete; the row disappears.
4. Tap "Clear" in the toolbar → confirmation alert; tap Clear All → list empties → empty state shows.
5. Force-quit the app and relaunch → list reflects whatever state you left it in (deletes/clears persist).

- [ ] **Step 4: Commit**

```bash
git add SarcasmKeyboard/Views/HistoryView.swift
git commit -m "Phase 5: HistoryView with copy/delete/clear + transient toast"
```

---

## Task 8: End-to-end verification + close out the phase

**Files:** none modified.

- [ ] **Step 1: Run the full Swift test suite**

Run: `swift test`
Expected: `Executed 131 tests, with 2 tests skipped and 0 failures`. (109 baseline + 3 HistoryEntry + 8 HistoryStore + 11 HistorySession = 131.)

- [ ] **Step 2: Clean Xcode build of the iOS app**

Run: `xcodebuild -project SarcasmKeyboard.xcodeproj -scheme SarcasmKeyboard -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' clean build`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: End-to-end manual verification (simulator)**

Boot iPhone 17 simulator. Run the app. Then run through this checklist:

1. **Empty-state on first launch:** Recent section shows the empty-state line. No Recent rows.
2. **Single-Return capture:** install the keyboard if not already installed (existing setup banner). In Notes, type "this is sarcastic" via the Sarcasm Keyboard, hit Return. Switch to the companion app. The Recent section shows the transformed output as the first row, with a relative timestamp ("now" or "1 sec ago") and the active pattern's name. Tap "See all" → full screen confirms the same.
3. **Multi-sentence flush on dismiss:** type "no return key" via the keyboard, then swipe to home (without pressing Return). Open the app — the entry appeared anyway (`viewWillDisappear` flushed it).
4. **Delete persists:** swipe-delete a row in the full screen, then swipe up to home, then re-open the app. The row stays gone.
5. **Clear persists:** Clear → confirm. Re-open. Empty state shows.
6. **Cap behavior:** there's no fast way to type 51 sentences manually. Skip this test in the simulator — it's already covered by `HistoryStoreTests.testCapEvictsOldestWhenFull`.
7. **Pro/free still works:** purchase Pro (StoreKit Configuration), confirm a Pro pattern transforms text and produces an entry tagged with that pattern's name in the Recent list.
8. **No raw input leak:** in Notes, type "secret" via the system keyboard first, then switch to Sarcasm Keyboard and type " sauce". Hit Return. The Recent entry should contain only the transformed " sauce" portion (or whatever the pattern produced for it), not "secret".

- [ ] **Step 4: Update the build plan to mark Phase 5 done**

Edit `~/.claude/plans/i-want-to-create-steady-deer.md`:
- In the "Current state" block, add a line: `- ✅ Phase 5 — HistoryStore (50-cap) + HistorySession + Recent section + full HistoryView. App Group writes; no Full Access required.`
- In the "Verification" block, change Phase 5's bullet to past tense and note the no-Full-Access discovery.

- [ ] **Step 5: Final commit**

```bash
git add ~/.claude/plans/i-want-to-create-steady-deer.md
git commit -m "Phase 5: mark complete in build plan"
```

(If the plan file lives outside the repo, this commit is a no-op — skip it. The plan file is in `~/.claude/plans/`, not the repo, so this step is informational; just edit the file and move on.)

---

## Verification — how you'll know Phase 5 is done

| Check | How |
|---|---|
| `swift test` is green at 131/131 (+2 skipped) | Step 8.1 |
| Clean iOS build succeeds | Step 8.2 |
| Recent section appears between Playground and Style | Step 8.3.1 |
| Output captured on Return | Step 8.3.2 |
| Output captured on dismiss without Return | Step 8.3.3 |
| Delete and Clear persist across relaunch | Step 8.3.4-5 |
| Pro pattern integration intact | Step 8.3.7 |
| No raw input ever stored | Step 8.3.8 + `HistoryEntry` has no `rawInput` field |
| Cap-50 enforcement | `HistoryStoreTests.testCapEvictsOldestWhenFull` |

## Risks recap (from spec, restated for the implementer)

- **Buffer drift**: if the user mixes the system keyboard / dictation with our keyboard, the buffer reflects only what we inserted, not what the user sees. Acceptable.
- **Lost entries on extension crash**: the buffer is in-memory; a crash mid-buffer loses unflushed text. We don't checkpoint per-keystroke because the cost outweighs the rarity.
- **Concurrent writes**: load+modify+save is not atomic across processes. Both keyboard and app calling `append`/`delete` simultaneously could lose a write. In practice the keyboard writes when foregrounded and the app writes when foregrounded — they don't overlap. If this becomes an issue we'll switch to a file-coordinated write or a shared SQLite store.
