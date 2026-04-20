import Foundation

public protocol LetterIndexedPattern: SarcasmPattern {
    func transformLetter(_ char: Character, atLetterIndex index: Int) -> String
}

extension LetterIndexedPattern {
    public func transform(_ input: String) -> String {
        var result = ""
        result.reserveCapacity(input.count)
        var letterIndex = 0
        for char in input {
            if char.isLetter {
                result += transformLetter(char, atLetterIndex: letterIndex)
                letterIndex += 1
            } else {
                result.append(char)
            }
        }
        return result
    }

    public func transformCharacter(_ char: Character, priorContext: String) -> String {
        if char.isLetter {
            let index = priorContext.reduce(0) { $1.isLetter ? $0 + 1 : $0 }
            return transformLetter(char, atLetterIndex: index)
        }
        return String(char)
    }
}
