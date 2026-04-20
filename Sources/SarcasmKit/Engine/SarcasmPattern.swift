import Foundation

public protocol SarcasmPattern: Sendable {
    var id: String { get }
    var displayName: String { get }
    var isPremium: Bool { get }

    func transform(_ input: String) -> String

    func transformCharacter(_ char: Character, priorContext: String) -> String
}

extension SarcasmPattern {
    public func transformCharacter(_ char: Character, priorContext: String) -> String {
        let combined = priorContext + String(char)
        let transformed = transform(combined)
        let dropCount = transform(priorContext).count
        return String(transformed.dropFirst(dropCount))
    }
}
