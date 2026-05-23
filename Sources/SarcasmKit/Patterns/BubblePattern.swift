import Foundation

public struct BubblePattern: SarcasmPattern {
    public let id = "bubble"
    public let displayName = "Ⓑⓤⓑⓑⓛⓔ"
    public let isPremium = true

    public init() {}

    // Lowercase a-z → ⓐ-ⓩ (U+24D0..U+24E9)
    // Uppercase A-Z → Ⓐ-Ⓩ (U+24B6..U+24CF)
    // 0 → ⓪ (U+24EA), 1-9 → ①-⑨ (U+2460..U+2468)
    private static let map: [Character: Character] = {
        var m: [Character: Character] = [:]
        for i in 0..<26 {
            m[Character(UnicodeScalar(0x61 + i)!)] = Character(UnicodeScalar(0x24D0 + i)!)
            m[Character(UnicodeScalar(0x41 + i)!)] = Character(UnicodeScalar(0x24B6 + i)!)
        }
        m["0"] = "\u{24EA}"
        for i in 1...9 {
            m[Character(UnicodeScalar(0x30 + i)!)] = Character(UnicodeScalar(0x2460 + i - 1)!)
        }
        return m
    }()

    public func transform(_ input: String) -> String {
        String(input.map { Self.map[$0] ?? $0 })
    }

    public func transformCharacter(_ char: Character, priorContext: String) -> String {
        String(Self.map[char] ?? char)
    }
}
