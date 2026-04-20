import Foundation

public struct RandomPattern: LetterIndexedPattern {
    public let id = "random"
    public let displayName = "rAnDoM"
    public let isPremium = false

    public init() {}

    public func transformLetter(_ char: Character, atLetterIndex index: Int) -> String {
        Bool.random()
            ? String(char).uppercased()
            : String(char).lowercased()
    }
}
