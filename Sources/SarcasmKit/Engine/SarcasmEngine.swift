import Foundation

public enum SarcasmEngine {
    public static let allPatterns: [any SarcasmPattern] = [
        AlternatingPattern(),
        SpongeBobPattern(),
        RandomPattern(),
        WordTogglePattern(),
        SmallCapsPattern(),
        ZalgoPattern()
    ]

    public static func pattern(id: String) -> (any SarcasmPattern)? {
        allPatterns.first { $0.id == id }
    }

    public static func letterCount(in text: String) -> Int {
        text.reduce(0) { $1.isLetter ? $0 + 1 : $0 }
    }
}
