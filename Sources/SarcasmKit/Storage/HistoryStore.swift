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

    public static func delete(id: UUID) {
        var entries = load()
        entries.removeAll { $0.id == id }
        save(entries)
    }

    public static func clear() {
        SharedDefaults.defaults.removeObject(forKey: key)
    }

    private static func save(_ entries: [HistoryEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        SharedDefaults.defaults.set(data, forKey: key)
    }
}
