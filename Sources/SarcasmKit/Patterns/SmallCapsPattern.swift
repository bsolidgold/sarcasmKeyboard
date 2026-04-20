import Foundation

public struct SmallCapsPattern: SarcasmPattern {
    public let id = "smallCaps"
    public let displayName = "sMaLl CaPs"
    public let isPremium = true

    public init() {}

    private static let smallCapsMap: [Character: Character] = [
        "a": "ᴀ", "b": "ʙ", "c": "ᴄ", "d": "ᴅ", "e": "ᴇ",
        "f": "ꜰ", "g": "ɢ", "h": "ʜ", "i": "ɪ", "j": "ᴊ",
        "k": "ᴋ", "l": "ʟ", "m": "ᴍ", "n": "ɴ", "o": "ᴏ",
        "p": "ᴘ", "q": "ꞯ", "r": "ʀ", "s": "ꜱ", "t": "ᴛ",
        "u": "ᴜ", "v": "ᴠ", "w": "ᴡ", "x": "x", "y": "ʏ",
        "z": "ᴢ"
    ]

    public func transform(_ input: String) -> String {
        var result = ""
        result.reserveCapacity(input.count)
        for char in input {
            let lower = Character(String(char).lowercased())
            if let mapped = Self.smallCapsMap[lower] {
                result.append(mapped)
            } else {
                result.append(char)
            }
        }
        return result
    }

    public func transformCharacter(_ char: Character, priorContext: String) -> String {
        let lower = Character(String(char).lowercased())
        if let mapped = Self.smallCapsMap[lower] {
            return String(mapped)
        }
        return String(char)
    }
}
