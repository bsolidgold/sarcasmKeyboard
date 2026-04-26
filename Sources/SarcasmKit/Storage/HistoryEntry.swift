import Foundation

public struct HistoryEntry: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let output: String
    public let patternID: String
    public let createdAt: Date

    public init(output: String, patternID: String, createdAt: Date = Date()) {
        self.id = UUID()
        self.output = output
        self.patternID = patternID
        self.createdAt = createdAt
    }

    init(id: UUID, output: String, patternID: String, createdAt: Date) {
        self.id = id
        self.output = output
        self.patternID = patternID
        self.createdAt = createdAt
    }
}
