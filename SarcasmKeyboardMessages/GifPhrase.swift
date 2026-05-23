import Foundation

struct GifPhrase: Identifiable, Sendable {
    let id: String
    let displayText: String
    let isFree: Bool
    // Bundled asset filename; nil = generate on the fly
    let gifFilename: String?
}
