import Foundation

public struct AlternatingPattern: LetterIndexedPattern {
    public let id = "alternating"
    public let displayName = "aLtErNaTiNg"
    public let isPremium = false

    public init() {}

    public func transformLetter(_ char: Character, atLetterIndex index: Int) -> String {
        index.isMultiple(of: 2)
            ? String(char).lowercased()
            : String(char).uppercased()
    }
}
