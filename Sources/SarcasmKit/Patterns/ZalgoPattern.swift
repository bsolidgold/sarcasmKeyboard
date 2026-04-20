import Foundation

public struct ZalgoPattern: SarcasmPattern {
    public let id = "zalgo"
    public let displayName = "Z̊ä̶l̈g̃ȯ"
    public let isPremium = true

    public init() {}

    private static let above: [Unicode.Scalar] = [
        "\u{0300}", "\u{0301}", "\u{0302}", "\u{0303}",
        "\u{0304}", "\u{0306}", "\u{0307}", "\u{0308}",
        "\u{030A}", "\u{030B}", "\u{030C}"
    ]
    private static let below: [Unicode.Scalar] = [
        "\u{0316}", "\u{0317}", "\u{0323}", "\u{0324}",
        "\u{0325}", "\u{0326}", "\u{0329}"
    ]

    public func transform(_ input: String) -> String {
        var result = ""
        result.reserveCapacity(input.count * 3)
        for (idx, char) in input.enumerated() {
            result.append(char)
            if char.isLetter {
                result += combiningMarks(for: String(char), charIndex: idx)
            }
        }
        return result
    }

    public func transformCharacter(_ char: Character, priorContext: String) -> String {
        var out = String(char)
        if char.isLetter {
            out += combiningMarks(for: String(char), charIndex: priorContext.count)
        }
        return out
    }

    private func combiningMarks(for char: String, charIndex: Int) -> String {
        var rng = SeededGenerator(seed: char.stableHash &+ UInt64(charIndex) &* 2654435761)
        let markCount = Int(rng.next() & 0x3)
        var marks = ""
        for _ in 0..<markCount {
            let fromAbove = (rng.next() & 1) == 0
            let pool = fromAbove ? Self.above : Self.below
            let pick = Int(rng.next() % UInt64(pool.count))
            marks.append(Character(pool[pick]))
        }
        return marks
    }
}
