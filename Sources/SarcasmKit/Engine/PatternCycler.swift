import Foundation

public enum PatternCycler {
    /// Returns the ID of the next pattern after `currentID`, wrapping around.
    /// When `includePremium` is false, premium patterns are skipped (keyboard strip for free users).
    /// When `includePremium` is true, every pattern is reachable (Pro users).
    public static func next(
        currentID: String,
        in patterns: [any SarcasmPattern],
        includePremium: Bool = false
    ) -> String {
        let pool = includePremium ? patterns : patterns.filter { !$0.isPremium }
        guard !pool.isEmpty else { return currentID }
        guard let currentIndex = pool.firstIndex(where: { $0.id == currentID }) else {
            return pool[0].id
        }
        let nextIndex = (currentIndex + 1) % pool.count
        return pool[nextIndex].id
    }
}
