import Foundation

public struct WordTogglePattern: SarcasmPattern {
    public let id = "wordToggle"
    public let displayName = "wORD tOGGLE"
    public let isPremium = false

    public init() {}

    public func transform(_ input: String) -> String {
        var result = ""
        result.reserveCapacity(input.count)
        var wordIndex = 0
        var inWord = false

        for char in input {
            if char.isLetter {
                if !inWord {
                    inWord = true
                }
                let upper = !wordIndex.isMultiple(of: 2)
                result += upper
                    ? String(char).uppercased()
                    : String(char).lowercased()
            } else {
                if inWord {
                    wordIndex += 1
                    inWord = false
                }
                result.append(char)
            }
        }
        return result
    }

    public func transformCharacter(_ char: Character, priorContext: String) -> String {
        if !char.isLetter { return String(char) }

        var wordIndex = 0
        var inWord = false
        for c in priorContext {
            if c.isLetter {
                inWord = true
            } else if inWord {
                wordIndex += 1
                inWord = false
            }
        }
        let upper = !wordIndex.isMultiple(of: 2)
        return upper ? String(char).uppercased() : String(char).lowercased()
    }
}
