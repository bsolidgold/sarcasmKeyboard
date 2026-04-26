import XCTest
@testable import SarcasmKit

final class HistoryStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        SharedDefaults.defaults.removeObject(forKey: HistoryStore.key)
    }

    func testLoadReturnsEmptyWhenUnset() {
        XCTAssertEqual(HistoryStore.load(), [])
    }

    func testAppendPersistsAcrossLoads() {
        let entry = HistoryEntry(output: "hello", patternID: "alternating")
        HistoryStore.append(entry)
        XCTAssertEqual(HistoryStore.load(), [entry])
    }

    func testAppendPreservesChronologicalOrder() {
        let first = HistoryEntry(output: "first", patternID: "alternating")
        let second = HistoryEntry(output: "second", patternID: "alternating")
        let third = HistoryEntry(output: "third", patternID: "alternating")
        HistoryStore.append(first)
        HistoryStore.append(second)
        HistoryStore.append(third)
        XCTAssertEqual(HistoryStore.load().map(\.output), ["first", "second", "third"])
    }

    func testCapEvictsOldestWhenFull() {
        for i in 0..<HistoryStore.cap {
            HistoryStore.append(HistoryEntry(output: "entry\(i)", patternID: "alternating"))
        }
        XCTAssertEqual(HistoryStore.load().count, HistoryStore.cap)

        HistoryStore.append(HistoryEntry(output: "overflow", patternID: "alternating"))

        let entries = HistoryStore.load()
        XCTAssertEqual(entries.count, HistoryStore.cap)
        XCTAssertEqual(entries.first?.output, "entry1", "oldest should be evicted")
        XCTAssertEqual(entries.last?.output, "overflow", "newest should be at the end")
    }
}
