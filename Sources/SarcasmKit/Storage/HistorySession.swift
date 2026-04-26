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
    public func removeLast(_ count: Int = 1) {
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
