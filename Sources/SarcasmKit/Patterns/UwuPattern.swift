import Foundation

public struct UwuPattern: SarcasmPattern {
    public let id = "uwu"
    public let displayName = "UwU"
    public let isPremium = true

    public init() {}

    private static let suffixes = [" owo", " uwu", " :3", " >w<", "~"]

    public func transform(_ input: String) -> String {
        guard !input.trimmingCharacters(in: .whitespaces).isEmpty else { return input }
        let chars = Array(input)
        var result = ""
        result.reserveCapacity(chars.count + 4)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if isN(c), i + 1 < chars.count, isVowel(chars[i + 1]) {
                result.append(c)
                result.append("y")
                i += 1
                continue
            }
            result.append(contentsOf: substitute(c))
            i += 1
        }
        let seed = input.unicodeScalars.reduce(UInt64(0)) { $0 &+ UInt64($1.value) }
        var rng = SeededGenerator(seed: seed)
        result.append(contentsOf: Self.suffixes[Int(rng.next() % UInt64(Self.suffixes.count))])
        return result
    }

    public func transformCharacter(_ char: Character, priorContext: String) -> String {
        if isVowel(char), let last = priorContext.last, isN(last) {
            return "y" + substitute(char)
        }
        return substitute(char)
    }

    private func substitute(_ c: Character) -> String {
        switch c {
        case "r": return "w"
        case "R": return "W"
        case "l": return "w"
        case "L": return "W"
        default: return String(c)
        }
    }

    private func isVowel(_ c: Character) -> Bool {
        "aeiouAEIOU".contains(c)
    }

    private func isN(_ c: Character) -> Bool {
        c == "n" || c == "N"
    }
}
