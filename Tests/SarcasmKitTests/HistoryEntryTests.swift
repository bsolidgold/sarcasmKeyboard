import XCTest
@testable import SarcasmKit

final class HistoryEntryTests: XCTestCase {
    func testRoundTripCodable() throws {
        let original = HistoryEntry(
            output: "ThIs Is SaRcAsM",
            patternID: "spongebob",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HistoryEntry.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testTwoEntriesWithSameContentHaveDifferentIDs() {
        let a = HistoryEntry(output: "x", patternID: "alternating")
        let b = HistoryEntry(output: "x", patternID: "alternating")
        XCTAssertNotEqual(a.id, b.id)
    }

    func testEquatableUsesAllFields() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let id = UUID()
        let a = HistoryEntry(id: id, output: "x", patternID: "alternating", createdAt: date)
        let b = HistoryEntry(id: id, output: "x", patternID: "alternating", createdAt: date)
        XCTAssertEqual(a, b)
    }
}
