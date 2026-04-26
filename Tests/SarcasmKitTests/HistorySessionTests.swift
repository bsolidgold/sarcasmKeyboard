import XCTest
@testable import SarcasmKit

final class HistorySessionTests: XCTestCase {

    func testAppendThenFlushWritesOneEntry() {
        var writes: [HistoryEntry] = []
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let session = HistorySession(write: { writes.append($0) }, now: { fixedDate })

        session.append("hello ")
        session.append("world")
        session.flush(currentPatternID: "spongebob")

        XCTAssertEqual(writes.count, 1)
        XCTAssertEqual(writes.first?.output, "hello world")
        XCTAssertEqual(writes.first?.patternID, "spongebob")
        XCTAssertEqual(writes.first?.createdAt, fixedDate)
    }

    func testFlushOnEmptyBufferWritesNothing() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        session.flush(currentPatternID: "alternating")

        XCTAssertTrue(writes.isEmpty)
    }

    func testFlushOnWhitespaceOnlyBufferWritesNothing() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        session.append("   \n\t  ")
        session.flush(currentPatternID: "alternating")

        XCTAssertTrue(writes.isEmpty)
    }

    func testFlushTrimsLeadingAndTrailingWhitespace() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        session.append("   hello   ")
        session.flush(currentPatternID: "alternating")

        XCTAssertEqual(writes.first?.output, "hello")
    }

    func testFlushResetsTheBuffer() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        session.append("first")
        session.flush(currentPatternID: "alternating")
        session.append("second")
        session.flush(currentPatternID: "alternating")

        XCTAssertEqual(writes.map(\.output), ["first", "second"])
    }

    func testRemoveLastDropsCharacters() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        session.append("hello")
        session.removeLast(2)
        session.flush(currentPatternID: "alternating")

        XCTAssertEqual(writes.first?.output, "hel")
    }

    func testRemoveLastOnEmptyBufferIsNoOp() {
        let session = HistorySession(write: { _ in })
        session.removeLast(5)  // must not crash
    }

    func testRemoveLastDoesNotUnderflow() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        session.append("hi")
        session.removeLast(10)
        session.append("ok")
        session.flush(currentPatternID: "alternating")

        XCTAssertEqual(writes.first?.output, "ok")
    }

    func testFlushTruncatesAt500Graphemes() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        let long = String(repeating: "a", count: 600)
        session.append(long)
        session.flush(currentPatternID: "alternating")

        let output = writes.first?.output ?? ""
        XCTAssertEqual(output.count, 500)
        XCTAssertTrue(output.hasSuffix("…"))
        XCTAssertEqual(String(output.prefix(499)), String(repeating: "a", count: 499))
    }

    func testFlushDoesNotTruncateAt500OrFewerGraphemes() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        let exact = String(repeating: "a", count: 500)
        session.append(exact)
        session.flush(currentPatternID: "alternating")

        XCTAssertEqual(writes.first?.output, exact)
        XCTAssertFalse(writes.first?.output.hasSuffix("…") ?? true)
    }

    func testResetClearsBufferWithoutWriting() {
        var writes: [HistoryEntry] = []
        let session = HistorySession(write: { writes.append($0) })

        session.append("draft")
        session.reset()
        session.flush(currentPatternID: "alternating")

        XCTAssertTrue(writes.isEmpty)
    }
}
