import XCTest
@testable import SarcasmKit

final class SarcasmEngineTests: XCTestCase {
    func testAllPatternsHaveUniqueIds() {
        let ids = SarcasmEngine.allPatterns.map { $0.id }
        XCTAssertEqual(Set(ids).count, ids.count, "Pattern IDs must be unique")
    }

    func testAllPatternsHaveDisplayNames() {
        for pattern in SarcasmEngine.allPatterns {
            XCTAssertFalse(pattern.displayName.isEmpty, "\(pattern.id) has empty displayName")
        }
    }

    func testLookupByIdReturnsCorrectPattern() {
        XCTAssertEqual(SarcasmEngine.pattern(id: "alternating")?.id, "alternating")
        XCTAssertEqual(SarcasmEngine.pattern(id: "spongebob")?.id, "spongebob")
        XCTAssertNil(SarcasmEngine.pattern(id: "nonexistent"))
    }

    func testLetterCountIgnoresNonLetters() {
        XCTAssertEqual(SarcasmEngine.letterCount(in: ""), 0)
        XCTAssertEqual(SarcasmEngine.letterCount(in: "hello"), 5)
        XCTAssertEqual(SarcasmEngine.letterCount(in: "hello world"), 10)
        XCTAssertEqual(SarcasmEngine.letterCount(in: "abc123def"), 6)
        XCTAssertEqual(SarcasmEngine.letterCount(in: "!?,."), 0)
    }

    func testLetterCountWithEmoji() {
        XCTAssertEqual(SarcasmEngine.letterCount(in: "hi 👋"), 2)
        XCTAssertEqual(SarcasmEngine.letterCount(in: "a👨‍👩‍👧b"), 2)
    }

    func testAllPatternsHandleEmptyInput() {
        for pattern in SarcasmEngine.allPatterns {
            XCTAssertEqual(pattern.transform(""), "", "\(pattern.id) failed on empty input")
        }
    }

    func testAllPatternsHandleEmojiWithoutCrashing() {
        let input = "hi 👋 world 👨‍👩‍👧 ok"
        for pattern in SarcasmEngine.allPatterns {
            let out = pattern.transform(input)
            XCTAssertFalse(out.isEmpty, "\(pattern.id) produced empty output")
        }
    }

    func testFreeAndPremiumPatternsExist() {
        let premium = SarcasmEngine.allPatterns.filter { $0.isPremium }
        let free = SarcasmEngine.allPatterns.filter { !$0.isPremium }
        XCTAssertGreaterThan(premium.count, 0, "Expected at least one premium pattern")
        XCTAssertGreaterThan(free.count, 0, "Expected at least one free pattern")
    }
}
