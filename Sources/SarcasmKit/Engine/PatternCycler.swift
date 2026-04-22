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
