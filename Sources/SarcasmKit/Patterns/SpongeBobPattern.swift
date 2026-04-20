import Foundation

public struct SpongeBobPattern: LetterIndexedPattern {
    public let id = "spongebob"
    public let displayName = "Mocking SpongeBob"
    public let isPremium = false

    public init() {}

    public func transformLetter(_ char: Character, atLetterIndex index: Int) -> String {
        var rng = SeededGenerator(seed: UInt64(index) &* 0x9E37_79B9_7F4A_7C15 ^ 0xC0FF_EE11_DEAD_BEEF)
        let roll = rng.next() & 0xFF

        let shouldUppercase: Bool
        if index.isMultiple(of: 2) {
            shouldUppercase = roll < 64
        } else {
            shouldUppercase = roll < 192
        }

        return shouldUppercase
            ? String(char).uppercased()
            : String(char).lowercased()
    }
}
