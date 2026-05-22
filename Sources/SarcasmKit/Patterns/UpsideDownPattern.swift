import Foundation

public struct UpsideDownPattern: SarcasmPattern {
    public let id = "upsidedown"
    public let displayName = "uʍop ǝpᴉsd∩"
    public let isPremium = true

    public init() {}

    private static let flipMap: [Character: Character] = [
        "a": "ɐ", "b": "q", "c": "ɔ", "d": "p", "e": "ǝ",
        "f": "ɟ", "g": "ƃ", "h": "ɥ", "i": "ᴉ", "j": "ɾ",
        "k": "ʞ", "l": "ʟ", "m": "ɯ", "n": "u", "o": "o",
        "p": "d", "q": "b", "r": "ɹ", "s": "s", "t": "ʇ",
        "u": "n", "v": "ʌ", "w": "ʍ", "x": "x", "y": "ʎ",
        "z": "z",
        "A": "∀", "B": "ᗺ", "C": "Ɔ", "D": "ᗡ", "E": "Ǝ",
        "F": "Ⅎ", "G": "⅁", "H": "H", "I": "I", "J": "ɾ",
        "K": "ʞ", "L": "˥", "M": "W", "N": "N", "O": "O",
        "P": "d", "Q": "b", "R": "ɹ", "S": "S", "T": "ʇ",
        "U": "∩", "V": "ʌ", "W": "M", "X": "X", "Y": "ʎ",
        "Z": "Z",
        ".": "˙", ",": "'", "?": "¿", "!": "¡",
        "(": ")", ")": "(", "[": "]", "]": "[",
        "{": "}", "}": "{", "&": "⅋", ";": "؛",
    ]

    // transform: flip each character and reverse the whole string
    public func transform(_ input: String) -> String {
        String(input.map { Self.flipMap[$0] ?? $0 }.reversed())
    }

    // transformCharacter: flip only — no reversal possible in live-typing mode
    public func transformCharacter(_ char: Character, priorContext: String) -> String {
        String(Self.flipMap[char] ?? char)
    }
}
